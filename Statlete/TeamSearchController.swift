//
//  TeamSearchController.swift
//  Statlete
//
//  Created by Peter Stenger on 9/22/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

class TeamSearchController: UIViewController {

    let disposeBag = DisposeBag()
    let tableView = UITableView()
    var searchBar = UISearchBar()
    let selectedTeam = PublishSubject<[String:String]>()
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        configureObservables()
    }
    func initUI() {
        self.view.addSubview(tableView)
        initSearchController()
        initTableView()
        
    }
    func initSearchController() {
        // searchController.dimsBackgroundDuringPresentation = false
        searchBar.placeholder = "Search for a team here..."
        
        searchBar.delegate = nil
        searchBar.sizeToFit()
        searchBar.showsScopeBar = true
        searchBar.scopeButtonTitles = ["Cross Country", "Track"]
        // searchController.definesPresentationContext = true
    }

    func initTableView() {
        tableView.dataSource = nil
        tableView.delegate = nil
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.tableHeaderView = searchBar

        tableView.estimatedRowHeight = 40
        tableView.rowHeight = UITableView.automaticDimension
    }
    override func viewWillDisappear(_ animated: Bool) {
        self.selectedTeam.onCompleted()
    }
    
    func configureObservables() {
        // https://medium.com/@navdeepsingh_2336/creating-an-ios-app-with-mvvm-and-rxswift-in-minutes-b8800633d2e8
        // https://github.com/ReactiveX/RxSwift/issues/1714

        searchBar.rx.text.orEmpty.throttle(0.1, scheduler: MainScheduler.instance)
            .flatMapLatest { text in
                    return searchRequest(search: text, searchType: "t:t")
            }
            .bind(to: self.tableView.rx.items) { myTableView, row, element in
                // https://rxswift.slack.com/messages/C051G5Y6T/convo/C051G5Y6T-1538834969.000100/?thread_ts=1538834969.000100
                let cell = myTableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
                
                cell.textLabel?.text = element["result"]!
                cell.detailTextLabel?.text = element["location"]!
                return cell
            }.disposed(by: disposeBag)
        
        tableView.rx.modelSelected([String:String].self).debug("selectedTeam").do(onNext: { _ in
            // self.searchController.isActive = false

        }).take(1).bind(to: self.selectedTeam).disposed(by: disposeBag)
        // self.navigationController?.popViewController(animated: true)
        // https://medium.com/@dhruv.n.singh/passing-data-between-viewcontrollers-using-rxswift-be763fe10ba7
    }

    // https://www.thedroidsonroids.com/blog/rxswift-by-examples-1-the-basics/


}
