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
    let selectedAthlete = PublishSubject<TeamAthlete>()
    let disposeBag = DisposeBag()
    let tableHeaderView = UIView()
    let filterButton = UIBarButtonItem()
    let filterView = UIView()
    var state = SearchSettings()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        initUI()
        configureRxSwift()
    }
    func initUI() {
        initTableView()
        initSearchBar()
        initNavBar()
    }

    func initNavBar() {
        navigationItem.titleView = searchBar
        filterButton.title = "Filter"
        navigationItem.rightBarButtonItem = filterButton

    }
    func initSearchBar() {
        searchBar.placeholder = "Search"
        searchBar.delegate = nil
        searchBar.rx.searchButtonClicked.subscribe(onNext: { [unowned self] _ in
            self.searchBar.endEditing(true)
        }).disposed(by: disposeBag)

        searchBar.sizeToFit()
    }

    func initTableView() {
        view.addSubview(tableView)
        tableView.dataSource = nil
        tableView.delegate = nil
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(self.view.safeAreaLayoutGuide)

        }
        tableView.estimatedRowHeight = 40
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    func configureRxSwift() {
        let af = AthleteFilter()
        let afWrapper = UINavigationController(rootViewController: af)
        afWrapper.modalPresentationStyle = .overCurrentContext
        
        filterButton.rx.tap.subscribe(onNext: { [unowned self] tap in
            af.settings = self.state
            self.present(afWrapper, animated: true,completion: nil)
            
        }).disposed(by: disposeBag)
        af.savedSettings.subscribe(onNext: { [unowned self] s in
            self.state = s
        }).disposed(by: disposeBag)
        let searchFilter = searchBar.rx.text.orEmpty
        let stateUpdates = af.savedSettings.debug("stateUpdate").startWith(state)
        
        let allAthletes = stateUpdates.flatMap { getAthletes(year: $0.year, sport: $0.sport, teamID: $0.id) }.debug("athletes")
        
        Observable.combineLatest(allAthletes, searchFilter) { athletes, text -> [TeamAthlete] in
            (text.isEmpty) ? athletes : athletes.filter {
                $0.name.range(of: text, options: .caseInsensitive) != nil
            }
        }.bind(to: tableView.rx.items(cellIdentifier: "cell", cellType: UITableViewCell.self))
        { (row, element, cell) in
            cell.textLabel?.text = element.name
        }.disposed(by: disposeBag)

        tableView.rx.modelSelected(TeamAthlete.self)
            .bind(to: selectedAthlete)
            .disposed(by: disposeBag)
    }
}
