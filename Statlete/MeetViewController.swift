//
//  TeamStatsController.swift
//  Statlete
//
//  Created by Peter Stenger on 9/28/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import UIKit
import Charts
import RxSwift
import RxCocoa
import SwiftyJSON
import SnapKit
class MeetViewController: UITableViewController, UISearchBarDelegate {
    var schoolName = UserDefaults.standard.string(forKey: "schoolName")
    let sportMode = UserDefaults.standard.string(forKey: "sportMode")
    var schoolID = UserDefaults.standard.string(forKey: "schoolID")
    var shouldShowSearchResults = false
    var searchController: UISearchController!
    var searchControllerHeight = 0
    let disposeBag = DisposeBag()
    let picker = UIPickerView()
    let pickerBar = UIToolbar()
    let pickerContainer = UIView()
    let races = PublishSubject<[JSON]>()
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.pickerContainer.isExclusiveTouch = false
        self.pickerContainer.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.tableView.delegate = nil
        self.tableView.dataSource = nil
        self.picker.delegate = nil
        self.picker.dataSource = nil
        self.tableView.backgroundColor = .orange
        self.view.addSubview(pickerContainer)
        self.pickerContainer.addSubview(self.picker)
        self.pickerContainer.backgroundColor = .purple
        self.pickerContainer.addSubview(self.pickerBar)
        pickerContainer.snp.makeConstraints { make in
            make.left.right.bottom.width.equalTo(self.tableView)
            make.top.equalTo(self.tableView.snp.centerY)
            //make.top.equalTo(self.view.snp.centerY)
        }
        print(self.pickerContainer.frame.width)
        self.picker.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(self.pickerContainer)
            make.top.equalTo(self.pickerContainer).offset(50)
        }
        self.pickerBar.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(self.pickerContainer)
            make.height.equalTo(50)
        }
        initPicker()
        initPickerBar()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        configureRxSwift()

    }
    // https://github.com/ReactiveX/RxSwift/blob/master/RxExample/RxExample/Examples/SimpleTableViewExample/SimpleTableViewExampleViewController.swift
    func configureRxSwift() {
        // https://stackoverflow.com/questions/42179134/how-to-filter-array-of-observable-element-rxswift
        // https://rxswift.slack.com/messages/C051G5Y6T/convo/C051G5Y6T-1538834969.000100/?thread_ts=1538834969.000100
        // Bind table to getCalendar
        getCalendar(year: "2018", sport: self.sportMode!, schoolID: self.schoolID!).bind(to: self.tableView.rx.items(cellIdentifier: "cell", cellType: UITableViewCell.self)) { (row, element, cell) in
            cell.textLabel?.text = element["Name"].stringValue
        }.disposed(by: disposeBag)
        
        self.tableView.rx.modelSelected(JSON.self).debug("selected").filter {
            return $0["MeetHasResults"].intValue == 1
        }.flatMap(meetInfoFor(sport: self.sportMode!))
        .do(onNext: { _ in
            self.pickerContainer.isHidden = false
            self.pickerContainer.isExclusiveTouch = true
        })
        .bind(to: self.picker.rx.itemTitles) { index, item in

            return item.Name + " (\(item.Gender))"
        }.disposed(by: disposeBag)
        
        self.picker.rx.modelSelected(MeetEvent.self).subscribe(onNext: { meet in
            print(meet[0].URL)
            let indivMeet = IndividualMeetController()
            indivMeet.meet = meet[0]
            self.navigationController?.pushViewController(indivMeet, animated: true)
        }).disposed(by: disposeBag)
    }
    func initPickerBar() {
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: nil, action: nil)
        // https://www.hackingwithswift.com/example-code/uikit/how-to-add-a-flexible-space-to-a-uibarbuttonitem
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: nil, action: nil)
        doneButton.rx.tap.subscribe(onNext: { _ in
            print("TODO")
        }).disposed(by: disposeBag)
        cancelButton.rx.tap.subscribe(onNext: { _ in
            self.pickerContainer.isHidden = true
        })
        self.pickerBar.setItems([cancelButton, spacer, doneButton], animated: false)
        self.pickerBar.sizeToFit()
        self.pickerBar.isUserInteractionEnabled = true
        
    }
    
    func initPicker() {
        self.picker.backgroundColor = .white
        
    }
    //
}
