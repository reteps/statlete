//
//  SettingsController.swift
//  Statlete
//
//  Created by Peter Stenger on 9/20/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import UIKit
import Alamofire
import Kanna
import SnapKit

extension String {
    func matchingStrings(regex: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: []) else { return [] }
        let nsString = self as NSString
        let results  = regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))
        return results.map { result in
            (0..<result.numberOfRanges).map { result.range(at: $0).location != NSNotFound
                ? nsString.substring(with: result.range(at: $0))
                : ""
            }
        }
    }
}

class SettingsController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    private var myTableView: UITableView!
    
    var searchResultsArray = [[String:String]]()
    var shouldShowSearchResults = false
    var searchController: UISearchController!
    var searchControllerHeight = 0;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        CreateSearchTeamButton()
        configureTableView()
        configureSearchController()
    }
    @objc func buttonAction(sender: UIButton!) {
        myTableView.isHidden = false
    }
    func CreateSearchTeamButton() {
        let button = UIButton()
        button.backgroundColor = .blue
        button.setTitle("Search Team", for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.view.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view).offset(-100)
            make.height.equalTo(50)
            make.width.equalTo(150)
        }
    }
    func CreateSearchAthleteButton() {
        let button = UIButton()
        button.backgroundColor = .blue
        button.setTitle("Search Team", for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.view.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view).offset(0)
            make.height.equalTo(50)
            make.width.equalTo(150)
        }
    }
    func configureSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search here..."
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.sizeToFit()
        searchController.definesPresentationContext = true
        self.myTableView.tableHeaderView = searchController.searchBar


    }
    func configureTableView() {
        let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
        let displayWidth: CGFloat = self.view.frame.size.width
        let displayHeight: CGFloat = self.view.frame.size.height
        myTableView = UITableView(frame: CGRect(x: 0, y: barHeight, width: displayWidth, height: displayHeight - barHeight))
        myTableView.dataSource = self
        myTableView.delegate = self
        myTableView.rowHeight = (displayHeight - barHeight) / 10
        myTableView.isHidden = true
        self.view.addSubview(myTableView)
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchResultsArray.count
    }
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") else {
                return UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
            }
            return cell
        }()
        if self.shouldShowSearchResults {
            cell.textLabel?.text = searchResultsArray[indexPath.row]["school"]!
            cell.detailTextLabel?.text = searchResultsArray[indexPath.row]["location"]!
        }

        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //get the cell based on the indexPath
        let id = searchResultsArray[indexPath[1]]["id"]!
        teamRequest(schoolID: id)
        myTableView.isHidden = true
        
    }
    public func updateSearchResults(for searchController: UISearchController) {
        let searchString = searchController.searchBar.text
        if (searchString!.count >= 3) {
            searchRequest(search: searchString!, searchType: "t:t") { response in
                self.searchResultsArray = response
                self.myTableView.reloadData()
            }
        } else if searchResultsArray != [] {
            searchResultsArray = []
            self.myTableView.reloadData()
        }
    }
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.shouldShowSearchResults = true
        
        myTableView.reloadData()
    }


    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.shouldShowSearchResults = false
        myTableView.reloadData()
        myTableView.isHidden = true

    }

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
    func teamRequest(schoolID: String, type: String = "CrossCountry") {
        let url = URL(string: "https://www.athletic.net/\(type)/School.aspx?SchoolID=\(schoolID)")!
        Alamofire.request(url).responseString { response in
            let htmlString = response.result.value!
            let tokenData = htmlString.matchingStrings(regex: "constant\\(\"params\", (.+)\\)")[0][1]
            let teamData = htmlString.matchingStrings(regex: "constant\\(\"initialData\", (.+)\\)")[0][1]
            print(tokenData)
            // print("\n\n", tokenData[0][1].count)
        }
    }
}
// https://stackoverflow.com/questions/27880650/swift-extract-regex-matches


