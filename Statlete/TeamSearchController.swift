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

class TeamSearchController: UITableViewController, UISearchBarDelegate {

    var searchController: UISearchController!
    var searchControllerHeight = 0
    let disposeBag = DisposeBag()
    let selectedTeam = PublishRelay<[String:String]>()
    override func viewDidLoad() {
        super.viewDidLoad()
        print("view loading...")
        self.tableView.dataSource = nil
        self.tableView.delegate = nil
        // self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        // self.tableView.register(cellClass: myCell.self, forCellReuseIdentifier: "Cell")
        configureTableView()
        configureSearchController()
        configureObservables()
    }
    func configureSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search here..."

        searchController.searchBar.delegate = self
        searchController.searchBar.sizeToFit()
        searchController.definesPresentationContext = true
        self.tableView.tableHeaderView = searchController.searchBar
    }
    func configureObservables() {
        // https://medium.com/@navdeepsingh_2336/creating-an-ios-app-with-mvvm-and-rxswift-in-minutes-b8800633d2e8
        // https://github.com/ReactiveX/RxSwift/issues/1714
        let cancelTextObservable = self.searchController.searchBar.rx.textDidEndEditing.map({ _ in
            return ""
        })
        let searchTextObservable = self.searchController.searchBar.rx.text.orEmpty.asObservable()
        Observable.of(cancelTextObservable, searchTextObservable).merge()
        .throttle(0.1, scheduler: MainScheduler.instance)
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
        
        self.tableView.rx.modelSelected([String:String].self).bind(to: self.selectedTeam).disposed(by: disposeBag)
        self.selectedTeam.asObservable().subscribe(onNext: { _ in
            self.navigationController?.popViewController(animated: true)
        })
        // self.navigationController?.popViewController(animated: true)
        // https://medium.com/@dhruv.n.singh/passing-data-between-viewcontrollers-using-rxswift-be763fe10ba7

    }

    // https://www.thedroidsonroids.com/blog/rxswift-by-examples-1-the-basics/

    func configureTableView() {
        let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
        let displayHeight: CGFloat = self.view.frame.size.height
        self.tableView.rowHeight = (displayHeight - barHeight) / 10
    }

}
