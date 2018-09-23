//
//  TeamSearchController.swift
//  Statlete
//
//  Created by Peter Stenger on 9/22/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import UIKit

class TeamSearchController: UITableViewController, UISearchBarDelegate, UISearchResultsUpdating {

    var searchResultsArray = [[String:String]]()
    var shouldShowSearchResults = false
    var searchController: UISearchController!
    var searchControllerHeight = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        print("view loading...")
        configureTableView()
        configureSearchController()
    }
    func configureSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search here..."
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.sizeToFit()
        searchController.definesPresentationContext = true
        self.tableView.tableHeaderView = searchController.searchBar
        
        
    }
    func configureTableView() {
        let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
        let displayWidth: CGFloat = self.view.frame.size.width
        let displayHeight: CGFloat = self.view.frame.size.height
        
        //myTableView = UITableView(frame: CGRect(x: 0, y: barHeight, width: displayWidth, height: displayHeight - barHeight))
        //myTableView.dataSource = self
        //myTableView.delegate = self
        self.tableView.rowHeight = (displayHeight - barHeight) / 10
        //myTableView.isHidden = true
        //self.view.addSubview(myTableView)
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchResultsArray.count
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //get the cell based on the indexPath
        let schoolID = searchResultsArray[indexPath[1]]["id"]!
        // self.isHidden = true
        searchController.isActive = false
        //self.navigationController?.popViewController(animated: true)
        
        let athleteSearch = AthleteSearchController()
        athleteSearch.schoolID = schoolID
        let settingsController = SettingsController()
        athleteSearch.sportMode = settingsController.getSportMode()
        self.navigationController?.pushViewController(athleteSearch, animated: true)
    }
    func updateSearchResults(for searchController: UISearchController) {
        let searchString = searchController.searchBar.text
        if (searchString!.count >= 3) {
            searchRequest(search: searchString!, searchType: "t:t") { response in
                self.searchResultsArray = response
                self.tableView.reloadData()
            }
        } else if searchResultsArray != [] {
            searchResultsArray = []
            self.tableView.reloadData()
        }
    }
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.shouldShowSearchResults = true
        
        self.tableView.reloadData()
    }
    
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.shouldShowSearchResults = false
        self.tableView.reloadData()
        
    }


}
