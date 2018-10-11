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

    var data = Variable(JSON())
    var shouldShowSearchResults = false
    var searchController: UISearchController!
    var searchControllerHeight = 0
    var schoolID = ""
    var schoolName = ""
    var sportMode = ""
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        print("view loading...")

        self.configureSearchController()
    }
    // https://github.com/ReactiveX/RxSwift/blob/master/RxExample/RxExample/Examples/SimpleTableViewExample/SimpleTableViewExampleViewController.swift
    func configureSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search for athlete here..."
        searchController.searchBar.delegate = self
        searchController.searchBar.sizeToFit()
        searchController.definesPresentationContext = true
        self.tableView.delegate = nil
        self.tableView.dataSource = nil
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        // https://stackoverflow.com/questions/42179134/how-to-filter-array-of-observable-element-rxswift
        // https://rxswift.slack.com/messages/C051G5Y6T/convo/C051G5Y6T-1538834969.000100/?thread_ts=1538834969.000100
        let allAthletes = teamRequest(schoolID: self.schoolID).map { $0[1]["athletes"].array! }
        let searchFilter = PublishSubject<String>() // publishes changes
    
        Observable.combineLatest(allAthletes, searchFilter) { athletes, text in
                athletes.filter { athlete in
                    return text == "" || athlete["Name"].stringValue.range(of: text, options: .caseInsensitive) != nil
                }
            }.bind(to: self.tableView.rx.items(cellIdentifier: "cell", cellType: UITableViewCell.self)) { (row, element, cell) in
            cell.textLabel?.text = element["Name"].stringValue
        }.disposed(by: disposeBag)

        searchController.searchBar.rx.text.orEmpty.bind(to: searchFilter).disposed(by: disposeBag)
        
        self.tableView.rx.modelSelected(JSON.self).subscribe(onNext: { model in
            print(model)
        }).disposed(by: disposeBag)

        self.tableView.tableHeaderView = searchController.searchBar
    }
}

