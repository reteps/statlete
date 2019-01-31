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
    var settings = SearchSettings()
    let disposeBag = DisposeBag()
    let filterNavBar = UINavigationBar()
    let filterNavItem = UINavigationItem()
    let dataSource = DataSource()
    let savedSettings = PublishSubject<SearchSettings>()
    
    let yearPicker = UIPickerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
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
        let yp = YearPicker()
        yp.modalPresentationStyle = .overCurrentContext
        yp.sport = self.settings.sport
        yp.id = self.settings.id
        yp.yearSelected.subscribe(onNext: { year in
            print("selected", year)
            self.settings.year = year
        }).disposed(by: self.disposeBag)
        let teamPicker = TeamSearchController()
        teamPicker.selectedTeam.subscribe(onNext: { team in
            self.settings.id = team.code
            self.settings.name = team.name
            teamPicker.navigationController?.popViewController(animated: true)
            self.navigationController?.isNavigationBarHidden = true
        }).disposed(by: self.disposeBag)
        
        dataSource.sections = [
            Section(rows: [
                // TODO fix this
                Row(text: "Change Year", detailText: settings.year ?? "Current", selection: {
                    self.present(yp, animated: true)
                    
                }, accessory: .disclosureIndicator),
                Row(text: "Change Team", detailText: settings.name, selection: {
                    self.navigationController?.isNavigationBarHidden = false
                    self.navigationController?.pushViewController(teamPicker, animated: true)

                }, accessory: .disclosureIndicator),
                Row(text: "Cross Country", accessory: .switchToggle(value: settings.sport == Sport.XC,
                { (bool) in
                    self.settings.sport = bool ? Sport.XC : Sport.TF
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
        let doneButton = UIBarButtonItem()
        doneButton.title = "Save"
        doneButton.rx.tap.subscribe(onNext: { _ in
            self.savedSettings.onNext(self.settings)
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
        filterNavItem.rightBarButtonItem = doneButton
        filterNavBar.items = [filterNavItem]
    }
}
