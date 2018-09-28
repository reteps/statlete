//
//  AthleteSearchController.swift
//  Statlete
//
//  Created by Peter Stenger on 9/22/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import UIKit
import SwiftyJSON

class AthleteSearchController: UITableViewController, UISearchBarDelegate, UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        let searchString = searchController.searchBar.text!
        if searchString != "" {
            self.filteredResultsArray = allResultsArray.filter({( athlete: JSON) -> Bool in
                return athlete["Name"].stringValue.lowercased().contains(searchString.lowercased())
            })
        } else {
            self.filteredResultsArray = self.allResultsArray
        }
        self.tableView.reloadData()
    }
    
    var filteredResultsArray = [JSON()]
    var allResultsArray = [JSON()]
    var shouldShowSearchResults = false
    var searchController: UISearchController!
    var searchControllerHeight = 0
    var schoolID = ""
    var schoolName = ""
    var sportMode = ""
    var athleteSelection:((String) -> ())?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("view loading...")
        //configureTableView()
        //configureSearchController()
        teamRequest(schoolID: self.schoolID, type: self.sportMode) { TokenData, TeamData in
            self.allResultsArray = TeamData["athletes"].arrayValue
            print(self.allResultsArray)
            self.filteredResultsArray = TeamData["athletes"].arrayValue
            self.tableView.reloadData()

        }
        // self.configureTableView()
        self.configureSearchController()
        //salf.navigationController?
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
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
    }
    /*func configureTableView() {
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
    }*/
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
            cell.textLabel?.text = filteredResultsArray[indexPath.row]["Name"].stringValue
        } else {
            cell.textLabel?.text = allResultsArray[indexPath.row]["Name"].stringValue
        }
        
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //get the cell based on the indexPath
        var cellJSON: JSON
        if self.shouldShowSearchResults {
            cellJSON = filteredResultsArray[indexPath[1]]
        } else {
            cellJSON = allResultsArray[indexPath[1]]
        }
        self.athleteSelection!(cellJSON["Name"].stringValue)
        UserDefaults.standard.set(cellJSON["Name"].stringValue, forKey:"athleteName")
        UserDefaults.standard.set(cellJSON["ID"].intValue, forKey:"athleteID")
        UserDefaults.standard.set(self.schoolID, forKey:"teamID")
        UserDefaults.standard.set(self.schoolName, forKey:"teamName")
        UserDefaults.standard.set(self.sportMode, forKey:"sportMode")
        UserDefaults.standard.set(true, forKey:"finishedSetup")
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.popViewController(animated: true)
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

