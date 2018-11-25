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
import FontAwesome_swift
import SafariServices

class MeetViewController: UITableViewController, UISearchBarDelegate {
    var schoolName = UserDefaults.standard.string(forKey: "schoolName")
    let sportMode = UserDefaults.standard.string(forKey: "sportMode")
    var schoolID = UserDefaults.standard.string(forKey: "schoolID")
    var shouldShowSearchResults = false
    var searchController: UISearchController!
    var searchControllerHeight = 0
    let disposeBag = DisposeBag()
    let meetPicker = UIPickerView()
    let meetPickerBar = UIToolbar()
    let meetPickerContainer = UIView()
    let yearPicker = UIPickerView()
    let yearPickerBar = UIToolbar()
    let yearPickerContainer = UIView()
    let races = PublishSubject<[JSON]>()
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.meetPickerContainer.isExclusiveTouch = false
        self.meetPickerContainer.isHidden = true
        self.yearPickerContainer.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.tableView.delegate = nil
        self.tableView.dataSource = nil
        // Meet Picker
        meetPicker.delegate = nil
        meetPicker.dataSource = nil
        self.view.addSubview(meetPickerContainer)
        meetPickerContainer.addSubview(self.meetPicker)
        meetPickerContainer.addSubview(self.meetPickerBar)
        meetPickerContainer.backgroundColor = .white
        meetPickerContainer.snp.makeConstraints { make in
            make.left.right.bottom.width.equalTo(self.view)
            make.top.equalTo(self.view.snp.centerY)
            //make.top.equalTo(self.view.snp.centerY)
        }
        self.meetPicker.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(self.meetPickerContainer)
            make.top.equalTo(self.meetPickerContainer).offset(50)
        }
        self.meetPickerBar.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(self.meetPickerContainer)
            make.height.equalTo(50)
        }
        // Year Picker
        yearPicker.delegate = nil
        yearPicker.dataSource = nil
        self.view.addSubview(yearPickerContainer)
        yearPickerContainer.addSubview(self.yearPicker)
        yearPickerContainer.addSubview(self.yearPickerBar)
        yearPickerContainer.backgroundColor = .white
        yearPickerContainer.snp.makeConstraints { make in
            make.left.right.bottom.width.equalTo(self.view)
            make.top.equalTo(self.view.snp.centerY)
            //make.top.equalTo(self.view.snp.centerY)
        }
        self.yearPicker.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(self.yearPickerContainer)
            make.top.equalTo(self.yearPickerContainer).offset(50)
        }
        self.yearPickerBar.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(self.yearPickerContainer)
            make.height.equalTo(50)
        }
        
        self.tableView.estimatedRowHeight = 40
        self.tableView.rowHeight = UITableView.automaticDimension

        self.navigationItem.title = self.schoolName


        initPicker()
        initPickerBar()
        self.tableView.register(MeetCell.self, forCellReuseIdentifier: "MeetCell")

        self.navigationItem.leftBarButtonItem = UIBarButtonItem()
        
        configureRxSwift()

    }
    // https://github.com/ReactiveX/RxSwift/blob/master/RxExample/RxExample/Examples/SimpleTableViewExample/SimpleTableViewExampleViewController.swift
    func configureRxSwift() {
        // https://stackoverflow.com/questions/42179134/how-to-filter-array-of-observable-element-rxswift
        // https://rxswift.slack.com/messages/C051G5Y6T/convo/C051G5Y6T-1538834969.000100/?thread_ts=1538834969.000100
        // Bind table to getCalendar


        self.tableView.rx.modelSelected(JSON.self).filter {
            // filters for results
            return $0["MeetHasResults"].intValue == 1
        }.flatMap(meetInfoFor(sport: self.sportMode!))
        .do(onNext: { _ in
            self.meetPickerContainer.isHidden = false
            self.meetPickerContainer.isExclusiveTouch = true
        })
        .bind(to: self.meetPicker.rx.itemTitles) { index, item in

            return item.Name + " (\(item.Gender))"
        }.disposed(by: disposeBag)
        
        self.meetPicker.rx.modelSelected(MeetEvent.self).subscribe(onNext: { meet in
            print(meet[0].URL)
            let indivMeet = IndividualMeetController()
            indivMeet.meet = meet[0]
            self.navigationController?.pushViewController(indivMeet, animated: true)
        }).disposed(by: disposeBag)
        let button = UIBarButtonItem(title: "Team", style: .done, target: self, action: nil)
        button.rx.tap.subscribe(onNext: {
            let url = "https://www.athletic.net/\(self.sportMode!)/School.aspx?SchoolID=\(self.schoolID!)"
            let svc = SFSafariViewController(url: URL(string: url)!)
            self.present(svc, animated: true, completion: nil)
        }).disposed(by: disposeBag)
        self.navigationItem.rightBarButtonItem = button
        let leftButton = UIBarButtonItem()
        self.navigationItem.leftBarButtonItem = leftButton

        leftButton.rx.tap.flatMap { [weak self] _ in
            return getCalendarYears(sport: self!.sportMode!, schoolID: self!.schoolID!)
            }.do(onNext: { _ in
                self.yearPickerContainer.isHidden = false
                self.yearPickerContainer.isExclusiveTouch = true
            })
            .bind(to: self.yearPicker.rx.itemTitles) { index, item in
                
                return item
            }.disposed(by: disposeBag)

        let yearSelected = self.yearPicker.rx.modelSelected(String.self).startWith(["2018"]).do(onNext: { _ in
            self.yearPickerContainer.isHidden = true
            self.yearPickerContainer.isExclusiveTouch = false
        }).map { $0[0] }
        
        yearSelected.bind(to: leftButton.rx.title)
        yearSelected.flatMap { year in
            return getCalendar(year: year, sport: self.sportMode!, schoolID: self.schoolID!)
            }.bind(to:
            self.tableView.rx.items) { (tableView, row, element) in
                let cell = tableView.dequeueReusableCell(withIdentifier: "MeetCell") as! MeetCell
                cell.meetName.text = element["Name"].stringValue
                if element["MeetHasResults"].intValue == 0 {
                    cell.meetStatusWrapper.image = UIImage.fontAwesomeIcon(name: .calendarTimes, style: .solid, textColor: .black, size: CGSize(width: 30, height: 30))
                } else {
                    cell.meetStatusWrapper.image = UIImage.fontAwesomeIcon(name: .calendarCheck, style: .solid, textColor: .black, size: CGSize(width: 30, height: 30))
                }
                return cell
            }.disposed(by: disposeBag)
    
    }
    func initPickerBar() {
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: nil, action: nil)
        // https://www.hackingwithswift.com/example-code/uikit/how-to-add-a-flexible-space-to-a-uibarbuttonitem
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: nil, action: nil)
        doneButton.rx.tap.subscribe(onNext: { _ in
            // TODO
            print(self.meetPicker.selectedRow(inComponent: 0))
        }).disposed(by: disposeBag)
        
        cancelButton.rx.tap.subscribe(onNext: { _ in
            self.meetPickerContainer.isHidden = true
        }).disposed(by: disposeBag)
        self.meetPickerBar.setItems([cancelButton, spacer, doneButton], animated: false)
        self.meetPickerBar.sizeToFit()
        self.meetPickerBar.isUserInteractionEnabled = true
        
    }
    
    func initPicker() {
        self.meetPicker.backgroundColor = .white
        
    }
    //
}

class MeetCell: UITableViewCell {
    let meetName = UILabel()
    let meetStatusWrapper = UIImageView()
    let meetDate = UILabel()
    var disposeBag = DisposeBag()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(meetName)
        self.contentView.addSubview(meetStatusWrapper)
        self.contentView.addSubview(meetDate)
        self.meetName.snp.makeConstraints { make in
            make.left.equalTo(self.contentView).offset(30)
            make.height.equalTo(30)
        }
        self.meetStatusWrapper.snp.makeConstraints { make in
            make.width.height.equalTo(30)
        }
        self.meetDate.snp.makeConstraints { make in
            make.height.equalTo(30)
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // https://github.com/ReactiveX/RxSwift/issues/437
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag() // because life cicle of every cell ends on prepare for reuse
    }
}
