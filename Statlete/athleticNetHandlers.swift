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
func teamRequest(schoolID: String, type: String) -> Observable<[JSON]> {
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
// Returns the records for each event in the specified sport for a team

func teamRecords(type: String, teamID: String, year: String = "", gender: String = "M") -> [String: [TeamTimeResult]] {
    if type == "CrossCountry" {
        let urlString = "https://www.athletic.net/CrossCountry/Team.aspx?SchoolID=\(teamID)&S=\(year)"
        return _CrossCountryRecordParser(url: urlString, gender: gender)
    }
    var newGender = "men"
    if gender == "F" {
        newGender = "women"
    }
    let urlString = "https://www.athletic.net/TrackAndField/EventRecords.aspx?SchoolID=\(teamID)&S=\(year)"
    return _TrackAndFieldRecordParser(url: urlString, gender: newGender)
}

struct TeamTimeResult {
    var rank: Int
    var grade: Int?
    var time: AthleteTime
}
func _CrossCountryRecordParser(url: String, gender: String) -> [String: [TeamTimeResult]] {
    var results = [String: [TeamTimeResult]]()
    if let doc = try? HTML(url: URL(string: url)!, encoding: .utf8) {
        for distance in doc.css(".distance") {
            
            let eventName = distance.at_xpath(".//h3/text()")!.text!
            results[eventName] = [TeamTimeResult]()
            let year = doc.at_css("#h_clCurSeason")!.text!
            let table = distance.at_css(".\(gender) > table")!
                for result in table.css("tr") {
                    let rawRank = result.at_css("td")!.text
                    let rank = (rawRank == "") ? results[eventName]!.last!.rank : Int(rawRank!.prefix(rawRank!.count - 1))!
                    let grade = result.at_xpath(".//td[2]")!.text!
                    let name = result.at_css("a")!.text!
                    let rawTime = result.at_xpath(".//td[4]/a/text()")!.text!
                    let rawDate = result.at_xpath(".//td[5]")!.text!
                    let raceName = result.at_xpath(".//td[6]")!.text!
                    let time = formatEventTime(s: rawTime.replacingOccurrences(of: "[awch]", with: "", options: .regularExpression, range: nil))
                    let date = formatEventDate(s: rawDate + " \(year)")
                    // TODO: Fill in meetID and resultID
                    let athleteTime = AthleteTime(name: raceName, meetID: nil, resultID: nil, time: time, date: date)
                    let timeResult = TeamTimeResult(rank: rank, grade: Int(grade)!, time: athleteTime)
                    results[eventName]!.append(timeResult)
                    
                }
            
        }
    }
    return results
}
func _TrackAndFieldRecordParser(url: String, gender: String) -> [String: [TeamTimeResult]] {
    var results = [String: [TeamTimeResult]]()
    if let doc = try? HTML(url: URL(string: url)!, encoding: .utf8) {
        let year = doc.at_css("#h_clCurSeason")!.text!.prefix(4)
        let table = doc.at_css("div#\(gender) > table")!
        var eventName = ""
        for result in table.css("tr") {
            if result.at_css(".l") != nil {
                eventName = result.text!
                continue
            
            } else if result.css("td").count == 1 {
                continue
            }
            
            let rawRank = result.at_css("td")!.text
            let rank = (rawRank == "") ? results[eventName]!.last!.rank : Int(rawRank!.prefix(rawRank!.count - 1))!
            let rawGrade = result.at_xpath(".//td[2]")?.text
            let grade: Int? = (rawGrade == nil) ? nil : Int(rawGrade!)
            let name = result.at_css("a")!.text!
            let rawTime = result.at_xpath(".//td[5]/a/text()|.//td[5]/text()")!.text!
            if rawTime.range(of: "'") != nil {
                continue
            }
            if results[eventName] == nil {
                results[eventName] = [TeamTimeResult]()
            }
            let rawDate = result.at_xpath(".//td[6]")!.text!
            let time = formatEventTime(s: rawTime.replacingOccurrences(of: "[awch]", with: "", options: .regularExpression, range: nil))
            let date = formatEventDate(s: rawDate + " \(year)")
            let athleteTime = AthleteTime(name: name, meetID: nil, resultID: nil, time: time, date: date)
            let timeResult = TeamTimeResult(rank: rank, grade: grade, time: athleteTime)
            results[eventName]!.append(timeResult)
        }
    }
    return results
}

// https://www.athletic.net/TrackAndField/Report/FullSeasonTeam.aspx?SchoolID=13318&S=2018
// https://www.athletic.net/CrossCountry/Results/Season.aspx?SchoolID=13318&S=2018

func teamTimes(type: String, teamID: String, year: String = "", gender: String = "M") -> [String: [Date: Meet]] {
    if type == "CrossCountry" {
        let urlString = "https://www.athletic.net/CrossCountry/Results/Season.aspx?SchoolID=\(teamID)&S=\(year)"
        return _CrossCountryTimesParser(url: urlString, gender: gender)
    }
    var newGender = "men"
    if gender == "F" {
        newGender = "women"
    }
    let urlString = "https://www.athletic.net/TrackAndField/Report/FullSeasonTeam.aspx?SchoolID=\(teamID)&S=\(year)"
    return _TrackAndFieldTimesParser(url: urlString, gender: newGender)
}

func _TrackAndFieldTimesParser(url: String, gender: String) -> [String: [Date: Meet]] {
    var results = [String: [Date: Meet]]()

    if let doc = try? HTML(url: URL(string: url)!, encoding: .utf8) {
        let year = doc.at_css("#h_clCurSeason")!.text!.prefix(4)

        for athlete in doc.at_css("#\(gender)")!.css(".athlete") {
            
            for row in athlete.at_css("table.seasonStats")!.css("tr") {
                var event = ""
                var athleteName = ""
                if row.at_css("span") != nil {
                // header
                    let nameTag = row.at_css("a")!
                    athleteName = nameTag.text!
                    let nameID = nameTag["href"]
                } else if row.at_css("b") != nil {
                    event = row.at_css("b")!.text!
                // event name
                } else if row.at_css("a") != nil {
                    let place = row.at_css("td")
                    let rawTime = row.at_xpath(".//td[3]")!.text!
                    if rawTime.range(of: "'") != nil || rawTime == "NH" || rawTime == "DNS" {
                        continue
                    }
                    // https://stackoverflow.com/questions/28445917/what-is-the-most-succinct-way-to-remove-the-first-character-from-a-string-in-swi
                    let rawDate = String(row.at_xpath(".//td[6]")!.text!.split(separator: ",")[1].dropFirst())
                    
                    let meetTag = row.at_xpath(".//td[7]/a")!
                    let meetName = meetTag.text!
                    let meetID = meetTag["href"]!
                    let time = formatEventTime(s: rawTime.replacingOccurrences(of: "[awch]", with: "", options: .regularExpression, range: nil))

                    let date = formatEventDate(s: rawDate + " \(year)")
                    let timeEvent = AthleteTime(name: athleteName, meetID: nil, resultID: nil, time: time, date: date)
                    if results[event] == nil {
                        results[event] = [Date: Meet]()
                    }
                    if results[event]![date] == nil {
                        results[event]![date] = Meet(name: meetName, date: date, meetID: meetID, times: [timeEvent])
                    } else {
                        results[event]![date]!.times.append(timeEvent)
                    }
                // event result
                }
                
            }
        }
    }
    return results
}
struct Meet {
    var name: String
    var date: Date
    var meetID: String
    var times: [AthleteTime]
}
func _CrossCountryTimesParser(url: String, gender: String) -> [String: [Date: Meet]]{
    // eventName: [athlete]
    // -> [String: [String: TeamTimeResult]]
    // [String: [Date?: Meet]]
    var results = [String: [Date: Meet]]()
    if let doc = try? HTML(url: URL(string: url)!, encoding: .utf8) {
        // lookup table
        var subscriptLookup = [String: String]()
        var indexLookup = [String: String]()
        var meetLookup = [String: [String: String]]()
        for entry in doc.at_css(".pull-right-sm")!.css("tr") {
            if entry.at_css("th") != nil {
                continue //header
            }
            subscriptLookup[entry.at_css("sub")!.text!] = entry.at_xpath(".//td/text()")!.text!
        }
        let table = doc.at_css("#\(gender)_Table > table")!
        let year = doc.at_css("#h_clCurSeason")!.text!.prefix(4)

        for header in table.at_css("tr")!.css("th") {
            if header.className?.range(of: "td") != nil {
                indexLookup[header.className!] = header.text!
            }
        }
        for meet in doc.at_css("#MeetList")!.css("tr") {
            if meet.at_css("td") == nil {
                continue
            }
            let rawDate = meet.at_css("label")!.text!
            let meetTag = meet.at_css("a")!
            let meetName = meetTag.text!
            let meetID = meetTag["href"]!
            meetLookup[rawDate] = ["meetName": meetName, "meetID": meetID]
        }
    
        for row in table.at_css("tbody.athletes")!.css("tr") {
            let athleteName = row.at_xpath(".//td[2]/a/text()")!.text!
            let grade = row.at_css("td")!.text!
            for timeCell in row.css("td.d") {
                let resultCell = timeCell.at_css("a")
                let rawTime = resultCell!.text!
                let time = formatEventTime(s: rawTime)
                let resultID = resultCell!["href"]!
                let sub = timeCell.at_css(".subscript")!.text!
                let event = subscriptLookup[sub]!
                let classIndex = String(timeCell.className!.split(separator: " ")[0])
                let rawDate = indexLookup[classIndex]!
                let date = formatEventDate(s: rawDate + " \(year)")
                let timeEvent = AthleteTime(name: athleteName, meetID: nil, resultID: resultID, time: time, date: date)
                
                if results[event] == nil {
                    results[event] = [Date: Meet]()
                }
                if results[event]![date] == nil {
                    let meet = meetLookup[rawDate]!
                    let meetID = meet["meetID"]!
                    let meetName = meet["meetName"]!
                    results[event]![date] = Meet(name: meetName, date: date, meetID: meetID, times: [timeEvent])
                } else {
                    results[event]![date]!.times.append(timeEvent)
                }
            }
            
        }
    }
    return results
}

func getCalendar(year: String, sport: String, schoolID: String) -> Observable<[JSON]> {
    var urlSport = "tf"
    if sport == "CrossCountry" {
        urlSport = "xc"
    }
    let url = "https://www.athletic.net/api/v1/\(urlSport)Team/GetCalendar?teamID=\(schoolID)&seasonID=\(year)&editPermission=false"
    return Observable.create { observer in
    teamRequest(schoolID: schoolID, type: sport).map { $0[0]["publicToken"].stringValue }.subscribe(onNext: { token in
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

func meetInfo(sport: String, meetID: String) -> Observable<[JSON]> {
    return Observable.create { observer in
        let url = URL(string: "https://www.athletic.net/\(sport)/meet/\(meetID)/results")!
        
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
struct MeetEvent {
    var Name: String
    var URL: String
    var Gender: String
    
}


func meetInfoFor(sportMode: String) -> (JSON) -> Observable<[MeetEvent]> {
    return { meet in
        if (sportMode == "CrossCountry") {
            return meetInfo(sport: sportMode, meetID: meet["MeetID"].stringValue)
                .map {
                    $0[1]["divisions"].arrayValue
                }.map { divisions in
                    divisions.map { division in
                        let raceID = division["IDMeetDiv"].stringValue
                        let meetID = meet["MeetID"].stringValue
                        let url = "https://www.athletic.net/CrossCountry/meet/\(meetID)/results/\(raceID)"
                        return MeetEvent(Name: division["DivName"].stringValue, URL: url, Gender: division["Gender"].stringValue)
                    }
                }
        }
        
        return meetInfo(sport: sportMode, meetID: meet["MeetID"].stringValue).map {
            $0[1]["events"].arrayValue
        }.map { events in
            events.filter { $0["Measure"].stringValue == "M" }.map { event in
                let meetID = meet["MeetID"].stringValue
                let eventShort = event["EventShort"].stringValue
                let gender = event["Gender"].stringValue
                let divNum = "1"
                let url = "https://www.athletic.net/TrackAndField/meet/\(meetID)/results/\(gender.lowercased())/\(divNum)/\(eventShort)"
                return MeetEvent(Name: event["Event"].stringValue, URL: url, Gender: gender)
            }
        }
    }
}
func getRaceInfo(url: String) -> Observable<[JSON]> {
    return Observable.create { observer in
        let url = URL(string: url)!
        
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
struct RaceResult {
    var Result: String
    var SortValue: Double
    var Place: Int
    var AthleteID: Int
    var FirstName: String
    var LastName: String
    var Grade: String
    var AgeGrade: String
    var Gender: String
    var TeamID: Int
    var SchoolName: String
    var TeamCode: String
    var sr: Bool
    var pr: Bool
    var ShortCode: String
}
func raceInfoFor(url: String) -> Observable<[JSON]> {
    return getRaceInfo(url: url).map { $0[1]["results"].arrayValue }
}

