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

func teamRequest(schoolID: String, type: String = "CrossCountry", completionHandler: @escaping (JSON, JSON) -> ()) {
    let url = URL(string: "https://www.athletic.net/\(type)/School.aspx?SchoolID=\(schoolID)")!

    Alamofire.request(url).responseString { response in
        let htmlString = response.result.value!
        let rawTokenData = htmlString.matchingStrings(regex: "constant\\(\"params\", (.+)\\)")[0][1]
        let rawTeamData = htmlString.matchingStrings(regex: "constant\\(\"initialData\", (.+)\\)")[0][1]
        let jsonTokenData = rawTokenData.data(using: .utf8, allowLossyConversion: false)!
        let jsonTeamData = rawTeamData.data(using: .utf8, allowLossyConversion: false)!
        let parsedTokenData = try! JSON(data: jsonTokenData)
        let parsedTeamData = try! JSON(data: jsonTeamData)
        completionHandler(parsedTokenData, parsedTeamData)
    }

}
// https://stackoverflow.com/questions/27880650/swift-extract-regex-matches

func searchRequest(search: String, searchType: String, completionHandler: @escaping ([[String: String]]) -> ()) {
    let payload: [String: Any] = [
        "q": search,
        "fq": searchType,
        "start": 0
    ]
    
    let url = URL(string: "https://www.athletic.net/Search.aspx/runSearch")!
    Alamofire.request(url, method: .post, parameters: payload, encoding: JSONEncoding.default).responseJSON { response in
        let json = response.data
        do {
            var searchResults: [[String: String]] = []
            let parsedJson = JSON(json!)
            if let doc = try? Kanna.HTML(html: parsedJson["d"]["results"].stringValue, encoding: .utf8) {
                for row in doc.css("td:nth-child(2)") {
                    let link = row.at_css("a.result-title-tf")!
                    let location = row.at_css("a[target=_blank]")!
                    let schoolID = link["href"]!.components(separatedBy: "=")[1]
                    searchResults.append(["location": location.text!, "result": link.text!, "id":schoolID])
                }
            }
            completionHandler(searchResults)
        } catch let error {
            print(error)
        }
    }
}
struct Athlete {
    var name: String
    var athleteID: Int
    var events: [String: AthleteEvent]
    
}
struct AthleteEvent {
    var fastest: AthleteTime?
    var slowest: AthleteTime?
    var first: AthleteTime?
    var last: AthleteTime?
    var times: [AthleteTime]
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
    if let doc = try? HTML(url: url!, encoding: .utf8) {
        var athlete = Athlete(name: athleteName, athleteID: athleteID, events: [:])
        for season in doc.css(".season") {
            // https://stackoverflow.com/questions/39677330/how-does-string-substring-work-in-swift
            let year = season.className!.split(separator: " ")[4].suffix(4)
            let headerTags = season.xpath(".//h5[not(@class) or @class=\"bold\"]")
            for (index, section) in season.css("table").enumerated() {
                let event = headerTags[index].text!
                var eventTimes: [AthleteTime] = []
                // skip over all non-running events
                if section.at_css("tr > td:nth-child(2)")!.text!.range(of:"'") != nil {
                    continue
                }
                for race in section.css("tr") {
                    // https://github.com/tid-kijyun/Kanna/issues/127
                    let name = race.at_xpath(".//td[4]/a/text()")!.text!
                    let raw_time = try? race.at_xpath(".//td[2]/a/text()|.//td[2]/text()")!.text!
                    let time = formatEventTime(s: raw_time!.replacingOccurrences(of: "h", with: ""))
                    let date = formatEventDate(s: race.at_css("td[style='width: 60px;']")!.text! + " " + year)
                    eventTimes.append(AthleteTime(name: name, time: time, date: date))
                }
                if athlete.events[event] == nil {
                    athlete.events[event] = AthleteEvent(fastest: nil, slowest: nil, first: nil, last: nil, times: eventTimes)
                } else {
                    athlete.events[event]?.times += eventTimes
                }
            }
        }
        
        for (eventName, event) in athlete.events {
            // https://stackoverflow.com/questions/24781027/how-do-you-sort-an-array-of-structs-in-swift
            athlete.events[eventName]?.times = event.times.sorted { $0.date < $1.date }
            athlete.events[eventName]?.slowest = event.times.min { $0.time > $1.time }!
            athlete.events[eventName]?.fastest = event.times.max { $0.time > $1.time}!
            athlete.events[eventName]?.first = event.times[0]
            athlete.events[eventName]?.last = event.times[event.times.count - 1]

        }
        // http://nsdateformatter.com/
        // https://waracle.com/iphone-nsdateformatter-date-formatting-table/
        
        return athlete
    }
    return nil
}
