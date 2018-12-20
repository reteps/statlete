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
    let disposeBag = DisposeBag()
    let selectedTeam = PublishSubject<[String:String]>()
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        configureObservables()
    }
    func initUI() {
        initTableView()
        initSearchController()
    }
    func initSearchController() {
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
        
        self.tableView.rx.modelSelected([String:String].self).debug("selectedTeam").do(onNext: { _ in
            self.searchController.isActive = false

        }).take(1).bind(to: self.selectedTeam).disposed(by: disposeBag)
        // self.navigationController?.popViewController(animated: true)
        // https://medium.com/@dhruv.n.singh/passing-data-between-viewcontrollers-using-rxswift-be763fe10ba7

    }

    // https://www.thedroidsonroids.com/blog/rxswift-by-examples-1-the-basics/

    func initTableView() {
        self.tableView.dataSource = nil
        self.tableView.delegate = nil
        let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
        let displayHeight: CGFloat = self.view.frame.size.height
        self.tableView.rowHeight = (displayHeight - barHeight) / 10
    }
    override func viewWillDisappear(_ animated: Bool) {
        self.selectedTeam.onCompleted()
    }
}
