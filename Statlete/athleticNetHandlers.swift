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

func teamRequest(schoolID: String, type: String = "CrossCountry", completionHandler: @escaping (TokenData, TeamData) -> ()) {
    let url = URL(string: "https://www.athletic.net/\(type)/School.aspx?SchoolID=\(schoolID)")!

    Alamofire.request(url).responseString { response in
        let htmlString = response.result.value!
        let rawTokenData = htmlString.matchingStrings(regex: "constant\\(\"params\", (.+)\\)")[0][1]
        let rawTeamData = htmlString.matchingStrings(regex: "constant\\(\"initialData\", (.+)\\)")[0][1]
        let jsonTokenData = rawTokenData.data(using: .utf8)!
        let jsonTeamData = rawTeamData.data(using: .utf8)!

        let decoder = JSONDecoder()
        print(rawTeamData)
        print(rawTokenData)
        let parsedTokenData = try! decoder.decode(TokenData.self, from: jsonTokenData)
        let parsedTeamData = try! decoder.decode(TeamData.self, from: jsonTeamData)
        // print("\n\n", tokenData[0][1].count)
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
            let decoder = JSONDecoder()
            let values = try decoder.decode(SearchResponse.self, from: json!)
            if let doc = try? Kanna.HTML(html: values.d.results, encoding: .utf8) {
                for row in doc.css("td:nth-child(2)") {
                    let link = row.at_css("a.result-title-tf")!
                    let location = row.at_css("a[target=_blank]")!
                    let schoolID = link["href"]!.components(separatedBy: "SchoolID=")[1]
                    searchResults.append(["location": location.text!, "school": link.text!, "id":schoolID])
                }
            }
            completionHandler(searchResults)
        } catch let error {
            print(error)
        }
    }
}
