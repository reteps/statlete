//
//  FilterViewController.swift
//  Statlete
//
//  Created by Peter Stenger on 1/28/19.
//  Copyright © 2019 Peter Stenger. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import Static

class AthleteFilter: UIViewController {
    let filterView = UIView()
    let optionsTable = UITableView(frame: CGRect.zero, style: .grouped)
    let giantInvisibleButton = UIButton()
    let disposeBag = DisposeBag()
    let filterNavBar = UINavigationBar()
    let filterNavItem = UINavigationItem()
    let dataSource = DataSource()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.clear
        // self.view.isOpaque = false

        initUI()
    }
    func initUI() {
        initBack()
        initFilterView()
        initTable()
        initNavBar()
    }
    func initBack() {
        self.view.addSubview(giantInvisibleButton)
        giantInvisibleButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        giantInvisibleButton.rx.tap.subscribe(onNext: { [unowned self] _ in
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)

    }
    func initFilterView() {
        self.view.addSubview(filterView)

        filterView.addSubview(filterNavBar)
        filterView.addSubview(optionsTable)

        filterView.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(300)
        }
    }
    func initTable() {

        dataSource.sections = [
            Section(rows: [
                Row(text: "Change Year", detailText: "2018", accessory: .disclosureIndicator),
                Row(text: "Change Team", detailText: "Huron", accessory: .disclosureIndicator),
                Row(text: "Cross Country", accessory: .switchToggle(value: true, { (bool) in
                    print("this changed", bool)
                }))
            ])
        ]
        dataSource.tableView = optionsTable
        optionsTable.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.top.equalTo(filterNavBar.snp.bottom)
        }

    }
    func initNavBar() {
        filterNavBar.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
        let clearButton = UIBarButtonItem()
        let doneButton = UIBarButtonItem()
        clearButton.title = "Clear"
        doneButton.title = "Save"
        filterNavItem.leftBarButtonItem = clearButton
        filterNavItem.rightBarButtonItem = doneButton
        filterNavBar.items = [filterNavItem]
    }
}
