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

public struct Team {
    var name: String
    var code: String
    var location: String?
    init(name: String = "", code: String = "", location: String?=nil) {
        self.code = code
        self.name = name
        self.location=location
    }
}

class TeamSearchController: UIViewController {

    let disposeBag = DisposeBag()
    let tableView = UITableView()
    var searchBar = UISearchBar()
    let selectedTeam = PublishSubject<Team>()
    let filterView = UIView()
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
        searchBar.placeholder = "Search for a team"
        searchBar.delegate = nil
        searchBar.sizeToFit()
        self.navigationItem.titleView = searchBar
    }

    func initTableView() {
        tableView.dataSource = nil
        tableView.delegate = nil
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.estimatedRowHeight = 40
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    func configureObservables() {

        searchBar.rx.text.orEmpty.throttle(0.1, scheduler: MainScheduler.instance)
            .flatMapLatest { text in
                    return searchRequest(search: text, searchType: "t:t")
            }
            .bind(to: self.tableView.rx.items) { myTableView, row, team in
                // https://rxswift.slack.com/messages/C051G5Y6T/convo/C051G5Y6T-1538834969.000100/?thread_ts=1538834969.000100
                let cell = myTableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
                
                cell.textLabel?.text = team.name
                cell.detailTextLabel?.text = team.location
                return cell
            }.disposed(by: disposeBag)
        
        tableView.rx.modelSelected(Team.self)
        .bind(to: self.selectedTeam).disposed(by: disposeBag)
    }


}
