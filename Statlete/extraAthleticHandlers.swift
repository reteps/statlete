//
//  extraAthleticHandlers.swift
//  Statlete
//
//  Created by Peter Stenger on 11/27/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import Foundation
import Kanna
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
                // let name = result.at_css("a")!.text!
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
                    // let nameID = nameTag["href"]
                } else if row.at_css("b") != nil {
                    event = row.at_css("b")!.text!
                    // event name
                } else if row.at_css("a") != nil {
                    // let place = row.at_css("td")
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
            // let grade = row.at_css("td")!.text!
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
