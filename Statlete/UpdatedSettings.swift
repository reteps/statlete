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

class Settings: Object {
    @objc dynamic var teamID = 0
    @objc dynamic var teamName = ""
    @objc dynamic var athleteID = 0
    @objc dynamic var athleteName = ""
    @objc dynamic var athleteMode = ""
    @objc dynamic var teamMode = ""
    @objc dynamic var hypotheticalEnabled = true
}

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

        initDataSource()
        initTableView()
    }
    func initTableView() {

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    func initDataSource() {
        dataSource.sections = [
            Section(header: "Settings", rows: [
                Row(text: "Change Athlete", detailText: "JIM BO", selection: {
                    print("athlete changer tapped")
                }, accessory: .disclosureIndicator),
                Row(text: "Change Team", detailText: "JIM's TEAM", selection: {
                    print("this tapped")
                }, accessory: .disclosureIndicator),
                Row(text: "Cross Country", accessory: .switchToggle(value: true, { (bool) in
                    print("this changed", bool)
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

