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
// Returns team information like a list of athletes from a teamID

struct TeamAthlete {
    var Name: String
    var Gender: String
    var ID: Int
}
// https://stackoverflow.com/questions/27880650/swift-extract-regex-matches
// https://stackoverflow.com/questions/52656378/bind-alamofire-request-to-table-view-using-rxswift/52656720?noredirect=1#comment92244571_52656720
// searches athletic.net
func searchRequest(search: String, searchType: String) -> Observable<[Team]> {
    let payload: [String: Any] = [
        "q": search,
        "fq": searchType,
        "start": 0
    ]
    if search.count < 3 {
        return Observable.just([Team]())
    }
    let url = URL(string: "https://www.athletic.net/Search.aspx/runSearch")!
    return Observable.create { observer in
        Alamofire.request(url, method: .post, parameters: payload, encoding: JSONEncoding.default).responseJSON { response in
            let json = response.data
            var results = [Team]()

            var parsedJson = JSON(json!)

            let doc = try! Kanna.HTML(html: parsedJson["d"]["results"].stringValue, encoding: .utf8)
            for row in doc.css("td:nth-child(2)") {
                let link = row.at_css("a.result-title-tf")!
                let location = row.at_css("a[target=_blank]")!
                let teamID = link["href"]!.components(separatedBy: "=")[1]
                results.append(Team(name: link.text!, code: teamID, location: location.text!))
            }
            observer.onNext(results)
            observer.onCompleted()
        }
        return Disposables.create()
    }
}
func getYear() -> String {
    let year = Calendar.current.component(.year, from: Date())
    return String(year)
}

struct Athlete {
    var name: String
    var athleteID: String
    var events: [Sport: [String: [String: [AthleteTime]]]]
    // [sport: [eventName: [season: [time]]]]
    init(name: String = "", athleteID: String = "", events: [Sport: [String: [String: [AthleteTime]]]]? = nil) {
        self.name = name
        self.athleteID = athleteID
        self.events = events ?? [Sport: [String: [String: [AthleteTime]]]]()
    }

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

func individualAthlete(id: String, name: String, sport: Sport = Sport.XC, bothSports: Bool = false) -> Athlete? {
    var data = createAthlete(sport: sport, id: id, name: name)
    if bothSports {
        let other = createAthlete(sport: sport.opposite, id: id, name: name)
        // https://stackoverflow.com/questions/24051904/how-do-you-add-a-dictionary-of-items-into-another-dictionary
        data!.events = other!.events.merging(data!.events) { $1 }
    }
    return data
}
// Helper function
func createAthlete(sport: Sport, id: String, name: String) -> Athlete? {
    let url = URL(string: "https://www.athletic.net/\(sport.raw)/Athlete.aspx?AID=\(id)#!/L0")
    if let doc = try? HTML(url: url!, encoding: .utf8) {
        var athlete = Athlete(name: name, athleteID: id, events: [:])
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
                if athlete.events[sport] == nil {
                    athlete.events[sport] = [String: [String: [AthleteTime]]]()
                }
                if athlete.events[sport]?[event] == nil {
                    athlete.events[sport]?[event] = [String: [AthleteTime]]()
                }
                if athlete.events[sport]?[event]?[year] == nil {
                    athlete.events[sport]?[event]?[year] = times
                } else {
                    athlete.events[sport]?[event]?[year]? += times
                }
            }
        }
        return athlete
    }
    return nil
}
struct Meet {
    var name: String
    var date: Date
    var meetID: String
    var times: [AthleteTime]
}

func getCalendarYears(sport: String, teamID: String) -> Observable<[String]> {
    let url = "https://www.athletic.net/\(sport)/School.aspx?SchoolID=\(teamID)"
    return dataRequest(url: url).map { data in
        let newSeasons = data[1]["seasons"].dictionaryValue.map { (key, value) in
            return value["ID"].stringValue
        }
        return newSeasons.sorted().reversed()
    }
}
struct CalendarMeet {
    var date: String
    var hasResults: Bool
    var startDate: String
    var name: String
    var location: String
    var id: String
    var sport: Sport
    init(json: JSON, sport: Sport) {
        self.date = json["StartDate"].stringValue
        self.hasResults = json["MeetHasResults"].intValue == 1
        self.startDate = json["StartDate"].stringValue
        self.name = json["Name"].stringValue
        self.location = json["Location"].stringValue
        self.id = json["MeetID"].stringValue
        self.sport = sport
    }
}
func getCalendar(year: String, sport: Sport, teamID: String) -> Observable<[CalendarMeet]> {
    var urlSport = "tf"
    if sport == Sport.XC {
        urlSport = "xc"
    }
    let url = "https://www.athletic.net/api/v1/\(urlSport)Team/GetCalendar?teamID=\(teamID)&seasonID=\(year)&editPermission=false"

    return Observable.create { observer in
        let schoolUrl = "https://www.athletic.net/\(sport.raw)/School.aspx?SchoolID=\(teamID)"
        dataRequest(url: schoolUrl).map { $0[0]["publicToken"].stringValue }
        .subscribe(onNext: { token in
            let headers: HTTPHeaders = [
                "authid": teamID,
                "authtoken": token
            ]
            Alamofire.request(url, headers: headers).responseJSON { response in
                let json = JSON(response.result.value!)

                let calendar = json.map { (arg) -> CalendarMeet in

                    let (_, raw) = arg
                    return CalendarMeet(json: raw,sport:sport)

                }
                observer.onNext(calendar)
                observer.onCompleted()
            }
        })
        return Disposables.create()
    }
}


struct MeetEvent {
    var name: String
    var url: String
    var gender: String
    var sport: Sport
    init(json: JSON, meet: CalendarMeet) {
        if meet.sport == Sport.XC {
            let raceID = json["IDMeetDiv"].stringValue
            self.url = "https://www.athletic.net/CrossCountry/meet/\(meet.id)/results/\(raceID)"
            self.name = json["DivName"].stringValue
            self.gender = json["Gender"].stringValue
            self.sport = meet.sport
        } else {
            let eventShort = json["EventShort"].stringValue
            let divNum = "1"
            self.gender = json["Gender"].stringValue
            self.url = "https://www.athletic.net/TrackAndField/meet/\(meet.id)/results/\(self.gender.lowercased())/\(divNum)/\(eventShort)"
            self.name = json["Event"].stringValue
            self.sport = meet.sport
        }
    }
}


func meetInfoFor(meet: CalendarMeet) -> Observable<[MeetEvent]> {
    let url = "https://www.athletic.net/\(meet.sport.raw)/meet/\(meet.id)/results"


    if (meet.sport == Sport.XC) {

        return dataRequest(url: url)
            .map {
                $0[1]["divisions"].arrayValue
            }.map { divisions in
                divisions.map { division in

                    return MeetEvent(json: division, meet: meet)

                }
        }
    }

    return dataRequest(url: url).map {
        $0[1]["events"].arrayValue
    }.map { events in
        events.filter { $0["Measure"].stringValue == "M" }.map { event in

            return MeetEvent(json: event, meet: meet)
        }
    }
}
struct AthleteResult {
    var name: String
    var id: String
    var gender: String
    init(json: JSON) {
        self.name = json["Name"].stringValue
        self.id = json["ID"].stringValue
        self.gender = json["Gender"].stringValue

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
    var time: String
    var sortValue: Double
    var athleteName: String
    var place: Int?
    var team: String?
    var grade: String?
    var isSR: Bool
    var isPR: Bool
    var resultCode: String?
    init(json: JSON, sport: Sport) {
        self.time = json["Result"].stringValue.replacingOccurrences(of: "[awch]", with: "", options: .regularExpression, range: nil)
        self.sortValue = json["sortValue"].doubleValue
        self.athleteName = (json["AthleteName"].string != nil) ? json["AthleteName"].stringValue : json["FirstName"].stringValue + " " + json["LastName"].stringValue
        self.place = json["Place"].int
        if sport == Sport.TF {
            self.sortValue = json["SortInt"].doubleValue
            self.place = Int(json["Place"].stringValue)
        }
        self.team = json["SchoolName"].string
        self.grade = json["Grade"].string
        self.isSR = json["sr"].boolValue
        self.isPR = json["pr"].boolValue
        self.resultCode = json["ShortCode"].string
    }
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
func raceInfoFor(url: String, sport: Sport) -> Observable<Race> {
    return dataRequest(url: url).map { data in
        let results = data[1]["results"].arrayValue
        var rounds = [String: String]()
        if sport == Sport.TF {
            let roundLookupTable = data[1]["rounds"]
            // https://github.com/SwiftyJSON/SwiftyJSON
            for (_, json) in roundLookupTable {
                rounds[json["IDRound"].stringValue] = json["RoundDesc"].stringValue
            }
        }
        var rawRoundData = [String: [RaceResult]]()
        results.forEach { json in

            let raceStruct = RaceResult(json: json, sport: sport)
            let roundName = json["Round"].string ?? "Results"
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

enum Sport: String {
    case XC = "CrossCountry"
    case TF = "TrackAndField"
    case None = ""
    var raw: String {
        switch self {
        case .XC: return "CrossCountry"
        case .TF: return "TrackAndField"
        case .None: return ""
        }
    }
    var opposite: Sport {
        switch self {
        case .TF: return .XC
        case .XC: return .TF
        case .None: return .None
        }
    }
    var display: String {
        switch self {
        case .XC: return "Cross Country"
        case .TF: return "Track and Field"
        case .None: return "Events"
        }
    }
}
