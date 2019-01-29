//
//  UpdatedSettings.swift
//  Statlete
//
//  Created by Peter Stenger on 12/20/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import SnapKit
import RealmSwift
import Realm
import Static


class UpdatedSettings: UIViewController {
    let tableView = UITableView(frame: CGRect.zero, style: .grouped)
    let disposeBag = DisposeBag()
    let dataSource = DataSource()


    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()

    }
    func initUI() {
        self.view.addSubview(self.tableView)
        self.view.backgroundColor = .white
        self.navigationItem.title = "Settings"
        initDataSource()
        initTableView()
    }
    func initTableView() {

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    func initDataSource() {
        let realm = try! Realm()
        let settings = realm.objects(Settings.self).first!
        dataSource.sections = [
            Section(header: "Settings", rows: [
                Row(text: "Change Athlete", detailText: settings.athleteName, selection: {
                    let athleteSearch = AthleteSearchController()
                    self.present(athleteSearch, animated:true)
                }, accessory: .disclosureIndicator),
                Row(text: "Change Team", detailText: settings.teamName, selection: {
                    let teamSearch = TeamSearchController()
                    self.present(teamSearch, animated:true)
                }, accessory: .disclosureIndicator),
                Row(text: "Cross Country", accessory: .switchToggle(value: settings.sport == Sport.XC.raw, { (bool) in
                    try! realm.write {
                        settings.sport = bool ? Sport.XC.raw : Sport.TF.raw
                    }
                }))
                ]),
            Section(header: "Information", rows: [
                Row(text: "Version", detailText: "1.0"),
                Row(text: "Created By", detailText: "Peter Stenger")
                ])
        ]
        dataSource.tableView = tableView

    }
}

