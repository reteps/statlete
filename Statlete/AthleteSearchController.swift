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

    var shouldShowSearchResults = false
    var searchController: UISearchController!
    var searchControllerHeight = 0
    var schoolID = ""
    var schoolName = ""
    var sportMode = ""
    let selectedAthlete = PublishRelay<JSON>()
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        print("view loading...")

        self.configureSearchController()
        configureRxSwift()
    }
    // https://github.com/ReactiveX/RxSwift/blob/master/RxExample/RxExample/Examples/SimpleTableViewExample/SimpleTableViewExampleViewController.swift
    func configureSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search for athlete here..."
        searchController.searchBar.delegate = self
        searchController.searchBar.sizeToFit()
        searchController.definesPresentationContext = true
        self.tableView.tableHeaderView = searchController.searchBar
        self.tableView.delegate = nil
        self.tableView.dataSource = nil
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    func configureRxSwift() {
        // https://stackoverflow.com/questions/42179134/how-to-filter-array-of-observable-element-rxswift
        // https://rxswift.slack.com/messages/C051G5Y6T/convo/C051G5Y6T-1538834969.000100/?thread_ts=1538834969.000100
        let allAthletes = teamRequest(schoolID: self.schoolID, type: self.sportMode).map { $0[1]["athletes"].arrayValue }
        let searchFilter = self.searchController.searchBar.rx.text.orEmpty.asObservable()
        let cancelFilter = self.searchController.searchBar.rx.textDidEndEditing.map( { "" } )
        let combinedFilter = Observable.of(searchFilter, cancelFilter).merge()
        // https://en.wikipedia.org/wiki/Ternary_operation
        Observable.combineLatest(allAthletes, combinedFilter) { athletes, text in
            text.isEmpty ? athletes : athletes.filter { $0["Name"].stringValue.range(of: text, options: .caseInsensitive) != nil }
            }.bind(to: self.tableView.rx.items(cellIdentifier: "cell", cellType: UITableViewCell.self)) { (row, element, cell) in
            cell.textLabel?.text = element["Name"].stringValue
        }.disposed(by: disposeBag)
        
        self.tableView.rx.modelSelected(JSON.self).debug("selectedAthlete").subscribe(onNext: { model in
            
            self.selectedAthlete.accept(model)
            self.searchController.isActive = false
            self.navigationController?.popViewController(animated: true)
        }).disposed(by: disposeBag)
        

    }
}

