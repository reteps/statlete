//
//  AthleteSearchController.swift
//  Statlete
//
//  Created by Peter Stenger on 9/22/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import UIKit

class AthleteSearchController: UITableViewController, UISearchBarDelegate, UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        let searchString = searchController.searchBar.text!
        self.filteredResultsArray = allResultsArray.filter({( athlete: Athlete) -> Bool in
            return athlete.name.lowercased().contains(searchString.lowercased())
        })
        self.tableView.reloadData()
    }
    
    var filteredResultsArray = [Athlete]()
    var allResultsArray = [Athlete]()
    var shouldShowSearchResults = false
    var searchController: UISearchController!
    var searchControllerHeight = 0
    var schoolID = ""
    var sportMode = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("view loading...")
        //configureTableView()
        //configureSearchController()
        teamRequest(schoolID: self.schoolID, type: self.sportMode) { TokenData, TeamData in
            self.allResultsArray = TeamData.athletes
            self.filteredResultsArray = TeamData.athletes
            self.tableView.reloadData()

        }
        self.configureTableView()
        self.configureSearchController()
        print(self.schoolID)
        print(self.sportMode)
    }
    func configureSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search for athlete here..."
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
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        //myTableView = UITableView(frame: CGRect(x: 0, y: barHeight, width: displayWidth, height: displayHeight - barHeight))
        //myTableView.dataSource = self
        //myTableView.delegate = self
        // self.tableView.rowHeight = (displayHeight - barHeight) / 10
        //myTableView.isHidden = true
        //self.view.addSubview(myTableView)
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.shouldShowSearchResults {
            return self.filteredResultsArray.count
        }
        return self.allResultsArray.count
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        if self.shouldShowSearchResults {
            cell.textLabel?.text = filteredResultsArray[indexPath.row].name
        } else {
            cell.textLabel?.text = allResultsArray[indexPath.row].name
        }
        
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //get the cell based on the indexPath
        if self.shouldShowSearchResults {
            let name = filteredResultsArray[indexPath[1]].name
            print(name)
        } else {
            let name = allResultsArray[indexPath[1]].name
            print(name)
        }
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.shouldShowSearchResults = true
        self.tableView.reloadData()
    }
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.shouldShowSearchResults = false
        self.tableView.reloadData()
        
    }
    
    
}

