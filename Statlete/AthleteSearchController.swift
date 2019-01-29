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
    var sport: String
    var year: String?
    var id: String
    var name: String
    init(sport: String = "", year: String? = nil, id: String = "", name: String = "") {
        self.sport = sport
        self.year = year
        self.id = id
        self.name = name
    }
}

class AthleteSearchController: UIViewController {

    let tableView = UITableView()
    let searchBar = UISearchBar()
    var shouldShowSearchResults = false
    var team: Team = Team()
    var sport = ""
    let selectedAthlete = PublishSubject<JSON>()
    let disposeBag = DisposeBag()
    let tableHeaderView = UIView()
    let filterButton = UIBarButtonItem()
    let filterView = UIView()


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
        searchBar.placeholder = "Search for an athlete"
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
        af.modalPresentationStyle = .overCurrentContext
        
        filterButton.rx.tap.subscribe(onNext: { [unowned self] tap in
            let settings = SearchSettings(sport: self.sport, year: nil, id: self.team.code, name: self.team.name)
            af.settings = settings

            self.present(af, animated: true, completion: nil)
            
        }).disposed(by: disposeBag)
        let url = "https://www.athletic.net/\(self.sport)/School.aspx?SchoolID=\(team.code)"
        var allAthletes = dataRequest(url: url).map {
            $0[1]["athletes"].arrayValue
        }
        // TODO fix this
        af.savedSettings.subscribe(onNext: { settings in
            let url = "https://www.athletic.net/\(settings.sport)/School.aspx?SchoolID=\(settings.id)?year=\(settings.year)"
            print("URL:",url)
            allAthletes.next(dataRequest(url: url).map {
                $0[1]["athletes"].arrayValue
            })
        })

        let searchFilter = searchBar.rx.text.orEmpty.asObservable()

        Observable.combineLatest(allAthletes, searchFilter) { athletes, text in
            text.isEmpty ? athletes : athletes.filter {
                $0["Name"].stringValue.range(of: text, options: .caseInsensitive) != nil
            }
        }.bind(to: self.tableView.rx.items(cellIdentifier: "cell", cellType: UITableViewCell.self))
        { (row, element, cell) in
            cell.textLabel?.text = element["Name"].stringValue
        }.disposed(by: disposeBag)

        self.tableView.rx.modelSelected(JSON.self)
            .debug("selectedAthlete")
            .bind(to: self.selectedAthlete)
            .disposed(by: disposeBag)
    }
}
