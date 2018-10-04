//
//  AthleteSearchController.swift
//  Statlete
//
//  Created by Peter Stenger on 9/22/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import UIKit
import SwiftyJSON
import RxSwift
import RxCocoa

class AthleteSearchController: UITableViewController, UISearchBarDelegate {

    var filteredResultsArray = [JSON()]
    var allResultsArray = [JSON()]
    var shouldShowSearchResults = false
    var searchController: UISearchController!
    var searchControllerHeight = 0
    var schoolID = ""
    var schoolName = ""
    var sportMode = ""
    var athleteSelection:((Int, String) -> ())?
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("view loading...")
        teamRequest(schoolID: self.schoolID, type: self.sportMode) { TokenData, TeamData in
            self.allResultsArray = TeamData["athletes"].arrayValue
            self.filteredResultsArray = TeamData["athletes"].arrayValue
            self.tableView.reloadData()

        }
        self.configureSearchController()
    }
    func configureSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search for athlete here..."
        searchController.searchBar.delegate = self
        searchController.searchBar.sizeToFit()
        searchController.definesPresentationContext = true
        searchController.searchBar.rx.text.orEmpty.subscribe(onNext: { query in
            
            self.filteredResultsArray = self.allResultsArray.filter( {
                    query == "" || $0["Name"].stringValue.lowercased().contains(query.lowercased())
            })
            self.tableView.reloadData()
        }).disposed(by: disposeBag)
        self.tableView.tableHeaderView = searchController.searchBar
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredResultsArray.count
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.text = filteredResultsArray[indexPath.row]["Name"].stringValue
        
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var cellJSON: JSON
        cellJSON = filteredResultsArray[indexPath[1]]
        print("selected item")
        self.athleteSelection!(cellJSON["ID"].intValue, cellJSON["Name"].stringValue)
        UserDefaults.standard.set(cellJSON["Name"].stringValue, forKey:"athleteName")
        UserDefaults.standard.set(cellJSON["ID"].intValue, forKey:"athleteID")
        UserDefaults.standard.set(self.schoolID, forKey:"schoolID")
        UserDefaults.standard.set(self.schoolName, forKey:"schoolName")
        UserDefaults.standard.set(self.sportMode, forKey:"sportMode")
        UserDefaults.standard.set(true, forKey:"setupComplete")
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.popViewController(animated: true)
    }
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.filteredResultsArray = self.allResultsArray
        self.tableView.reloadData()
        
    }
    
    
}

