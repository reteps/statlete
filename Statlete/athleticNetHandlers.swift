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
// Returns team information like a list of athletes from a schoolID

struct TeamAthlete {
    var Name: String
    var Gender: String
    var ID: Int
}
// https://stackoverflow.com/questions/27880650/swift-extract-regex-matches
// https://stackoverflow.com/questions/52656378/bind-alamofire-request-to-table-view-using-rxswift/52656720?noredirect=1#comment92244571_52656720
// searches athletic.net
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

                var parsedJson = JSON(json!)

                let doc = try! Kanna.HTML(html: parsedJson["d"]["results"].stringValue, encoding: .utf8)
                for row in doc.css("td:nth-child(2)") {
                    let link = row.at_css("a.result-title-tf")!
                    let location = row.at_css("a[target=_blank]")!
                    let schoolID = link["href"]!.components(separatedBy: "=")[1]
                    results.append(["location": location.text!, "result": link.text!, "id": schoolID])
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
    var events: [String: [String: [AthleteTime]]]
    // [eventName: [season: [time]]]

}

struct AthleteTime {
    var name: String // Optional for use in other functions, can be meetName OR athleteName
    var meetID: String? // Optional for use in other functions
    var resultID: String? // Race may not have result ID
    var time: Date
    var date: Date    
}
// Helper function, formats a date
func formatEventDate(s: String) -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMM dd yyyy"
    return dateFormatter.date(from: s)!
}
// Helper function, formats a time
func formatEventTime(s: String) -> Date {
    let dateFormatter = DateFormatter()
    if (s.count > 5) {
        dateFormatter.dateFormat = "mm:ss.SS"
    } else {
        // https://stackoverflow.com/questions/28328615/is-there-an-efficient-way-to-round-a-float-to-the-nearest-hundredths-place-in-sw
        let seconds = Double(s)!
        if seconds >= 60 { // Track Time Parse Error
            let newS = String(format: "1:%.2f", (seconds - 60.0))
            dateFormatter.dateFormat = "m:ss.SS"
            return dateFormatter.date(from: newS)!
        }
        dateFormatter.dateFormat = "ss.SS"
    }
    return dateFormatter.date(from: s)!
}
// Returns an Athlete from an athleteID

func individualAthlete(athleteID: Int, athleteName: String, type: String) -> Athlete? {
    let url = URL(string: "https://www.athletic.net/\(type)/Athlete.aspx?AID=\(athleteID)#!/L0")
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
                    let meetName = race.at_xpath(".//td[4]/a/text()")!.text!
                    let meetID = race.at_xpath(".//td[4]/a")!["href"]
                    let rawTime = race.at_xpath(".//td[2]/a/text()|.//td[2]/text()")
                    if rawTime == nil {
                        continue
                    } else if rawTime!.text! == "NT" || rawTime!.text! == "DNF" {
                        continue
                    }
                    let rawTimeTag = race.at_xpath(".//td[2]/a")
                    let resultID = (rawTimeTag != nil) ? rawTimeTag!["href"] : nil
                    let time = formatEventTime(s: rawTime!.text!.replacingOccurrences(of: "[awch]", with: "", options: .regularExpression, range: nil))
                    let date = formatEventDate(s: race.at_css("td[style='width: 60px;']")!.text! + " \(year)")
                    times.append(AthleteTime(name: meetName, meetID: meetID, resultID: resultID, time: time, date: date))
                }
                if athlete.events[event] == nil {
                    athlete.events[event] = [String: [AthleteTime]]()
                }
                if athlete.events[event]?[year] == nil {
                    athlete.events[event]?[year] = times
                } else {
                    athlete.events[event]?[year]? += times
                }
            }
        }
        // http://nsdateformatter.com/
        // https://waracle.com/iphone-nsdateformatter-date-formatting-table/

        return athlete
    }
    return nil
}

// https://www.athletic.net/TrackAndField/Report/FullSeasonTeam.aspx?SchoolID=13318&S=2018
// https://www.athletic.net/CrossCountry/Results/Season.aspx?SchoolID=13318&S=2018




struct Meet {
    var name: String
    var date: Date
    var meetID: String
    var times: [AthleteTime]
}

func getCalendarYears(sport: String, schoolID: String) -> Observable<[String]> {
    let url = "https://www.athletic.net/\(sport)/School.aspx?SchoolID=\(schoolID)"
    return dataRequest(url: url).map { data in
        let newSeasons = data[1]["seasons"].dictionaryValue.map { (key, value) in
            return value["ID"].stringValue
        }
        return newSeasons.sorted().reversed()
    }
}
func getCalendar(year: String, sport: String, schoolID: String) -> Observable<[JSON]> {
    var urlSport = "tf"
    if sport == "CrossCountry" {
        urlSport = "xc"
    }
    let url = "https://www.athletic.net/api/v1/\(urlSport)Team/GetCalendar?teamID=\(schoolID)&seasonID=\(year)&editPermission=false"
    
    return Observable.create { observer in
    let schoolUrl = "https://www.athletic.net/\(sport)/School.aspx?SchoolID=\(schoolID)"
    dataRequest(url: schoolUrl).map { $0[0]["publicToken"].stringValue }.subscribe(onNext: { token in
        let headers: HTTPHeaders = [
            "authid": schoolID,
            "authtoken": token
        ]
        Alamofire.request(url, headers: headers).responseJSON { response in
            let json = JSON(response.result.value!)
            observer.onNext(json.arrayValue)
            observer.onCompleted()
        }
    })
        return Disposables.create()
    }
}


struct MeetEvent {
    var Name: String
    var URL: String
    var Gender: String
    var Sport: String
}


func meetInfoFor(sport: String, meet: JSON) -> Observable<[MeetEvent]> {
        let url = "https://www.athletic.net/\(sport)/meet/\(meet["MeetID"].stringValue)/results"


        if (sport == "CrossCountry") {

            return dataRequest(url: url)
                .map {
                    $0[1]["divisions"].arrayValue
                }.map { divisions in
                    divisions.map { division in
                        let raceID = division["IDMeetDiv"].stringValue
                        let meetID = meet["MeetID"].stringValue
                        let url = "https://www.athletic.net/\(sport)/meet/\(meetID)/results/\(raceID)"
                        return MeetEvent(Name: division["DivName"].stringValue, URL: url, Gender: division["Gender"].stringValue,Sport: sport)
                    }
                }
        }
        
        return dataRequest(url: url).map {
            $0[1]["events"].arrayValue
        }.map { events in
            events.filter { $0["Measure"].stringValue == "M" }.map { event in
                let meetID = meet["MeetID"].stringValue
                let eventShort = event["EventShort"].stringValue
                let gender = event["Gender"].stringValue
                let divNum = "1"
                let url = "https://www.athletic.net/TrackAndField/meet/\(meetID)/results/\(gender.lowercased())/\(divNum)/\(eventShort)"
                return MeetEvent(Name: event["Event"].stringValue, URL: url, Gender: gender, Sport: sport)
            }
        }
}
// gets params and initialData from url
func dataRequest(url: String) -> Observable<[JSON]> {
    return Observable.create { observer in
        
        Alamofire.request(URL(string: url)!)
            .responseString { response in
                print(url)
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
struct RaceResult {
    var Result: String
    var SortValue: Double
    var AthleteName: String
    var Place: Int?
    var Team: String?
    var Grade: String?
    var isSR: Bool
    var isPR: Bool
    var ResultCode: String?
}
struct Race {
    var URL: String
    var Name: String
    var Rounds: [Round]
}
struct Round {
    var Name: String
    var items: [RaceResult]
}
func raceInfoFor(url: String, sport: String) -> Observable<Race> {
    return dataRequest(url: url).map { data in
        let results = data[1]["results"].arrayValue
        var rounds = [String: String]()
        if (sport == "TrackAndField") {
            let roundLookupTable = data[1]["rounds"]
            // https://github.com/SwiftyJSON/SwiftyJSON
             for (_, json) in roundLookupTable {
                rounds[json["IDRound"].stringValue] = json["RoundDesc"].stringValue
            }
        }
        var rawRoundData = [String: [RaceResult]]()
        results.forEach { result in
            let time = result["Result"].stringValue.replacingOccurrences(of: "[awch]", with: "", options: .regularExpression, range: nil)
            let athleteName = (result["AthleteName"].string != nil) ? result["AthleteName"].stringValue : result["FirstName"].stringValue + " " + result["LastName"].stringValue
            var sortValue = result["SortValue"].doubleValue
            var place = result["Place"].int
            if sport == "TrackAndField" {
                sortValue = result["SortInt"].doubleValue
                place = Int(result["Place"].string ?? "")
            }
            let team = result["SchoolName"].string
            let grade = result["Grade"].string
            let isSR = result["sr"].boolValue
            let isPR = result["pr"].boolValue
            let roundName = (result["Round"].string != nil) ? rounds[result["Round"].stringValue]!: "Results"
            let resultCode = result["ShortCode"].string
            let raceStruct = RaceResult(Result: time, SortValue: sortValue, AthleteName: athleteName, Place: place, Team: team,  Grade: grade, isSR: isSR, isPR: isPR, ResultCode: resultCode)
            if rawRoundData[roundName] == nil {
                rawRoundData[roundName] = [RaceResult]()
            }
            rawRoundData[roundName]!.append(raceStruct)
        }
        var roundData = [Round]()
        for (name, data) in rawRoundData {
            roundData.append(Round(Name: name, items: data))
        }
        let meetName = data[1]["meet"]["Name"].stringValue
        let race = Race(URL: url, Name: meetName, Rounds: roundData)
        return race
    }
}

