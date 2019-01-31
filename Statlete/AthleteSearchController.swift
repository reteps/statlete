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
import SnapKit

public struct SearchSettings {
    var sport: Sport
    var year: String?
    var id: String
    var name: String
    init(sport: Sport = Sport.None, year: String? = nil, id: String = "", name: String = "") {
        self.sport = sport
        self.year = year
        self.id = id
        self.name = name
    }
}

class AthleteSearchController: UIViewController {

    let tableView = UITableView()
    let searchBar = UISearchBar()
    let selectedAthlete = PublishSubject<AthleteResult>()
    let disposeBag = DisposeBag()
    let tableHeaderView = UIView()
    let filterButton = UIBarButtonItem()
    let filterView = UIView()
    var state = SearchSettings()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        initUI()
        configureRxSwift()
    }
    func initUI() {
        initTableView()
        initSearchBar()
        initNavBar()
    }

    func initNavBar() {
        self.navigationItem.titleView = searchBar
        filterButton.title = "Filter"
        self.navigationItem.rightBarButtonItem = filterButton

    }
    func initSearchBar() {
        searchBar.placeholder = "Search"
        searchBar.delegate = nil
        searchBar.sizeToFit()
    }

    func initTableView() {
        self.view.addSubview(tableView)
        tableView.dataSource = nil
        tableView.delegate = nil
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(self.view.safeAreaLayoutGuide)

        }
        tableView.estimatedRowHeight = 40
        tableView.rowHeight = UITableView.automaticDimension
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    func configureRxSwift() {
        let af = AthleteFilter()
        let afWrapper = UINavigationController(rootViewController: af)
        afWrapper.modalPresentationStyle = .overCurrentContext
        
        filterButton.rx.tap.subscribe(onNext: { [unowned self] tap in
            af.settings = self.state
            print("currentState",self.state)
            self.present(afWrapper, animated: true,completion: nil)
            
        }).disposed(by: disposeBag)
        af.savedSettings.subscribe(onNext: { s in
            print("returnedState",s)
            self.state = s
        }).disposed(by: disposeBag)
        let searchFilter = self.searchBar.rx.text.orEmpty
        let stateUpdates = af.savedSettings.debug("stateUpdate").startWith(self.state)
        
        let allAthletes = stateUpdates.flatMap { getAthletes(year: $0.year, sport: $0.sport, teamID: $0.id) }.debug("athletes")
        
        Observable.combineLatest(allAthletes, searchFilter) { athletes, text -> [TeamAthlete] in
            (text.isEmpty) ? athletes : athletes.filter {
                $0.name.range(of: text, options: .caseInsensitive) != nil
            }
        }.bind(to: self.tableView.rx.items(cellIdentifier: "cell", cellType: UITableViewCell.self))
        { (row, element, cell) in
            cell.textLabel?.text = element.name
        }.disposed(by: disposeBag)

        self.tableView.rx.modelSelected(AthleteResult.self)
            .debug("selectedAthlete")
            .bind(to: self.selectedAthlete)
            .disposed(by: disposeBag)
    }
}
