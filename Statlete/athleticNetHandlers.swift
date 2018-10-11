//
//  athleticNetHandlers.swift
//  Statlete
//
//  Created by Peter Stenger on 9/22/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import Foundation
import Alamofire
import Kanna
import SwiftyJSON
import RxCocoa
import RxSwift
// http://adamborek.com/creating-observable-create-just-deferred/
// https://github.com/NavdeepSinghh/RxSwift_MVVM_Finished/blob/master/Networking/ViewController.swift
func teamRequest(schoolID: String, type: String = "CrossCountry") -> Observable<[JSON]> {
    return Observable.create { observer in
        let url = URL(string: "https://www.athletic.net/\(type)/School.aspx?SchoolID=\(schoolID)")!
        Alamofire.request(url)
        .responseString { response in
            let htmlString = response.result.value!
            let rawTokenData = htmlString.matchingStrings(regex: "constant\\(\"params\", (.+)\\)")[0][1]
            let rawTeamData = htmlString.matchingStrings(regex: "constant\\(\"initialData\", (.+)\\)")[0][1]
            let jsonTokenData = rawTokenData.data(using: .utf8, allowLossyConversion: false)!
            let jsonTeamData = rawTeamData.data(using: .utf8, allowLossyConversion: false)!
            let parsedTokenData = try! JSON(data: jsonTokenData)
            let parsedTeamData = try! JSON(data: jsonTeamData)
            observer.onNext([parsedTokenData, parsedTeamData])
            observer.onCompleted()
        }
        return Disposables.create()
    }

}
struct TeamAthlete {
    var Name: String
    var Gender: String
    var ID: Int
}
// https://stackoverflow.com/questions/27880650/swift-extract-regex-matches
// https://stackoverflow.com/questions/52656378/bind-alamofire-request-to-table-view-using-rxswift/52656720?noredirect=1#comment92244571_52656720
func searchRequest(search: String, searchType: String) -> Observable<[[String:String]]> {
    let payload: [String: Any] = [
        "q": search,
        "fq": searchType,
        "start": 0
    ]
    if search.count < 3 {
        return Observable.just([[String:String]]())
    }
    let url = URL(string: "https://www.athletic.net/Search.aspx/runSearch")!
    return Observable.create { observer in
        Alamofire.request(url, method: .post, parameters: payload, encoding: JSONEncoding.default).responseJSON { response in
            let json = response.data
            var results = [[String:String]]()

            do {
                var parsedJson = JSON(json!)

                let doc = try! Kanna.HTML(html: parsedJson["d"]["results"].stringValue, encoding: .utf8)
                for row in doc.css("td:nth-child(2)") {
                    let link = row.at_css("a.result-title-tf")!
                    let location = row.at_css("a[target=_blank]")!
                    let schoolID = link["href"]!.components(separatedBy: "=")[1]
                    results.append(["location": location.text!, "result": link.text!, "id": schoolID])
                }
            } catch let error {
                observer.onError(error)
            }
            observer.onNext(results)
            observer.onCompleted()
        }
        return Disposables.create()
    }
}
struct Athlete {
    var name: String
    var athleteID: Int
    var events: [String: [String: AthleteSeason]]
    // event: season: times

}
struct AthleteSeason {
    var fastest: AthleteTime?
    var slowest: AthleteTime?
    var earliest: AthleteTime?
    var latest: AthleteTime?
    var times: [AthleteTime] // all times (for sorting)
}
struct AthleteTime {
    var name: String
    var time: Date
    var date: Date
}
func formatEventDate(s: String) -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMM dd yyyy"
    return dateFormatter.date(from: s)!
}
func formatEventTime(s: String) -> Date {
    let dateFormatter = DateFormatter()
    if (s.count > 5) {
        dateFormatter.dateFormat = "mm:ss.SS"
    } else {
        dateFormatter.dateFormat = "ss.SS"
    }
    return dateFormatter.date(from: s)!
}
func individualAthlete(athleteID: Int, athleteName: String, type: String) -> Athlete? {
    let url = URL(string: "https://www.athletic.net/\(type)/Athlete.aspx?AID=\(athleteID)#!/L0")
    print(url)
    if let doc = try? HTML(url: url!, encoding: .utf8) {
        var athlete = Athlete(name: athleteName, athleteID: athleteID, events: [:])
        for season in doc.css(".season") {
            // https://stackoverflow.com/questions/39677330/how-does-string-substring-work-in-swift
            let year = String(season.className!.split(separator: " ")[4].suffix(4))
            let headerTags = season.xpath(".//h5[not(@class) or @class=\"bold\"]")
            for (index, section) in season.css("table").enumerated() {
                let event = headerTags[index].text!
                var times: [AthleteTime] = []
                // skip over all non-running events
                if section.at_css("tr > td:nth-child(2)")!.text!.range(of: "'") != nil {
                    continue
                }
                for race in section.css("tr") {
                    // https://github.com/tid-kijyun/Kanna/issues/127
                    let name = race.at_xpath(".//td[4]/a/text()")!.text!
                    let rawTime = race.at_xpath(".//td[2]/a/text()|.//td[2]/text()")
                    if rawTime == nil {
                        print("skipping")
                        continue
                    }
                    let time = formatEventTime(s: rawTime!.text!.replacingOccurrences(of: "h", with: ""))
                    let date = formatEventDate(s: race.at_css("td[style='width: 60px;']")!.text! + " " + year)
                    times.append(AthleteTime(name: name, time: time, date: date))
                }
                if athlete.events[event] == nil {
                    athlete.events[event] = [String: AthleteSeason]()
                } else if athlete.events[event]?[year] == nil {
                    athlete.events[event]?[year] = AthleteSeason(fastest: nil, slowest: nil, earliest: nil, latest: nil, times: times)
                } else {
                    athlete.events[event]?[year]?.times += times
                }
            }
        }
        // do this afterward because seasons could be out of order
        for (eventName, event) in athlete.events {
            // https://stackoverflow.com/questions/24781027/how-do-you-sort-an-array-of-structs-in-swift
            for (year, season) in event {
                athlete.events[eventName]?[year]?.times = season.times.sorted { $0.date < $1.date }
                athlete.events[eventName]?[year]?.slowest = season.times.min { $0.time > $1.time }!
                athlete.events[eventName]?[year]?.fastest = season.times.max { $0.time > $1.time }!
                athlete.events[eventName]?[year]?.earliest = season.times[0]
                athlete.events[eventName]?[year]?.latest = season.times[season.times.count - 1]
            }
        }
        // http://nsdateformatter.com/
        // https://waracle.com/iphone-nsdateformatter-date-formatting-table/

        return athlete
    }
    return nil
}
