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

class MeetViewController: UIViewController {
    var schoolName = UserDefaults.standard.string(forKey: "schoolName")
    var sport = UserDefaults.standard.string(forKey: "sport")
    var teamID = UserDefaults.standard.string(forKey: "teamID")
    var shouldShowSearchResults = false
    var searchBar = UISearchBar()//Controller!
    let disposeBag = DisposeBag()
    let meetPicker = UIPickerView()
    let meetPickerBar = UIToolbar()
    let meetPickerContainer = UIView()
    let yearPicker = UIPickerView()
    let yearPickerBar = UIToolbar()
    let yearPickerContainer = UIView()
    let races = PublishSubject<[JSON]>()
    let dateFormatter = DateFormatter()
    var shouldUpdateData = false
    var manualRefresh = PublishSubject<String>()
    var tableView = UITableView()
    var titleButton: UIButton = {
        let b = UIButton(type: .system)
        b.tintColor = .black
        b.setImage(UIImage.fontAwesomeIcon(name: .chevronDown, style: .solid, textColor: .black, size: CGSize(width: 20, height: 20)), for: .normal)
        b.semanticContentAttribute = .forceRightToLeft
        return b
    }()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldUpdateData {
            manualRefresh.onNext(String(getYear()))
            self.navigationItem.title = self.schoolName
            shouldUpdateData.toggle()
        }
        titleButton.setTitle(self.schoolName, for: .normal)
        self.meetPickerContainer.isExclusiveTouch = false
        self.meetPickerContainer.isHidden = true
        self.yearPickerContainer.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        configureRxSwift()

    }
    func initTable() {
        self.tableView.delegate = nil
        self.tableView.dataSource = nil
        self.tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.tableView.estimatedRowHeight = 40
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.register(MeetCell.self, forCellReuseIdentifier: "MeetCell")

    }
    func initNavigationItem() {
        self.navigationItem.titleView = titleButton
        self.navigationItem.leftBarButtonItem = UIBarButtonItem()

    }
    func initUI() {
        self.view.backgroundColor = .white
        self.view.addSubview(tableView)
        initMeetPickerView()
        initMeetPicker()
        initYearPickerView()
        initYearPicker()
        initTable()
        initNavigationItem()
    }
    // https://github.com/ReactiveX/RxSwift/blob/master/RxExample/RxExample/Examples/SimpleTableViewExample/SimpleTableViewExampleViewController.swift
    func configureRxSwift() {
        // https://stackoverflow.com/questions/42179134/how-to-filter-array-of-observable-element-rxswift
        // https://rxswift.slack.com/messages/C051G5Y6T/convo/C051G5Y6T-1538834969.000100/?thread_ts=1538834969.000100
        // Bind table to getCalendar

        let meetSelected = self.tableView.rx.modelSelected(JSON.self).filter {
            // filters for results
            return $0["MeetHasResults"].intValue == 1
        }
        meetSelected.flatMap { [unowned self] meet -> Observable<[MeetEvent]> in
            let sport = self.sport!
            return meetInfoFor(sport: sport, meet: meet)
        }
        .do(onNext: { _ in
            self.meetPickerContainer.isHidden = false
            self.meetPickerContainer.isExclusiveTouch = true
        })
        .bind(to: self.meetPicker.rx.itemTitles) { index, item in
                
            return item.Name + " (\(item.Gender))"
        }.disposed(by: disposeBag)
        
        let infoTapped = self.meetPickerBar.items![2].rx.tap
        let meetURL = meetSelected.map { [unowned self] meet -> String in
            return "https://www.athletic.net/\(self.sport!)/meet/\(meet["MeetID"].stringValue)/results"
        }
        infoTapped.withLatestFrom(meetURL).subscribe(onNext: { url in
            let svc = SFSafariViewController(url: URL(string: url)!)
            self.present(svc, animated: true, completion: nil)
        }).disposed(by: disposeBag)

        
        self.meetPicker.rx.modelSelected(MeetEvent.self).map { $0[0] }.subscribe(onNext: { meet in
            let indivMeet = IndividualMeetController()
            indivMeet.meet = meet
            self.navigationController?.pushViewController(indivMeet, animated: true)
        }).disposed(by: disposeBag)
        
        let button = UIBarButtonItem(title: "Info", style: .done, target: self, action: nil)
        button.rx.tap.subscribe(onNext: { [unowned self] _ in
            let url = "https://www.athletic.net/\(self.sport!)/School.aspx?SchoolID=\(self.teamID!)"
            let svc = SFSafariViewController(url: URL(string: url)!)
            self.present(svc, animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        self.navigationItem.rightBarButtonItem = button
        let leftButton = UIBarButtonItem()
        self.navigationItem.leftBarButtonItem = leftButton

        let yearPicker = YearPicker()
        
        let yearSelected = leftButton.rx.tap.flatMap { _  -> PublishSubject<String> in
            yearPicker.sport = self.sport!
            yearPicker.id = self.teamID!
            self.present(yearPicker, animated: true)
            return yearPicker.yearSelected
        }
        yearSelected.bind(to: leftButton.rx.title).disposed(by: disposeBag)
        
        
        Observable.merge(yearSelected, manualRefresh).flatMap { [unowned self] year -> Observable<[JSON]> in
            let sport = self.sport!
            let teamID = self.teamID!
            return getCalendar(year: year, sport: sport, teamID: teamID)
            }.bind(to:
            self.tableView.rx.items) { (tableView, row, element) in
                let cell = tableView.dequeueReusableCell(withIdentifier: "MeetCell") as! MeetCell
                cell.meetName.text = element["Name"].stringValue
                if element["MeetHasResults"].intValue == 0 {
                    cell.meetStatusWrapper.image = UIImage.fontAwesomeIcon(name: .calendarTimes, style: .solid, textColor: .black, size: CGSize(width: 30, height: 30))
                } else {
                    cell.meetStatusWrapper.image = UIImage.fontAwesomeIcon(name: .calendarCheck, style: .solid, textColor: .black, size: CGSize(width: 30, height: 30))
                }
                let rawDate = element["Date"].stringValue
                self.dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                let date = self.dateFormatter.date(from: rawDate)
                self.dateFormatter.dateFormat = "MMM dd, Y"
                cell.meetDate.text = self.dateFormatter.string(from: date!)
                cell.meetLocation.text = element["Location"].stringValue
                return cell
            }.disposed(by: disposeBag)
    
    }
    func initMeetPickerView() {
        // https://www.hackingwithswift.com/example-code/uikit/how-to-add-a-flexible-space-to-a-uibarbuttonitem
        self.view.addSubview(meetPickerContainer)
        self.meetPickerContainer.addSubview(self.meetPicker)
        self.meetPickerContainer.addSubview(self.meetPickerBar)
        self.meetPickerContainer.backgroundColor = .white
        self.meetPickerContainer.snp.makeConstraints { make in
            make.left.right.bottom.width.equalTo(self.view)
            make.top.equalTo(self.view.snp.centerY)
            //make.top.equalTo(self.view.snp.centerY)
        }

        
    }
    
    func initMeetPicker() {
        self.meetPicker.delegate = nil
        self.meetPicker.dataSource = nil
        self.meetPicker.backgroundColor = .white
        self.meetPicker.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(self.meetPickerContainer)
            make.top.equalTo(self.meetPickerContainer).offset(50)
        }
        self.meetPickerBar.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(self.meetPickerContainer)
            make.height.equalTo(50)
        }
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: nil, action: nil)
        let meetInfoButton = UIBarButtonItem(title: "Meet Info", style: .plain, target: nil, action: nil)
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        cancelButton.rx.tap.subscribe(onNext: { _ in
            self.meetPickerContainer.isHidden = true
        }).disposed(by: disposeBag)
        self.meetPickerBar.setItems([cancelButton, space, meetInfoButton], animated: false)
        self.meetPickerBar.sizeToFit()
        self.meetPickerBar.isUserInteractionEnabled = true
    }
    func initYearPicker() {
        yearPicker.delegate = nil
        yearPicker.dataSource = nil

        self.yearPicker.backgroundColor = .white
        self.yearPicker.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(self.yearPickerContainer)
            make.top.equalTo(self.yearPickerContainer).offset(50)
        }
        self.yearPickerBar.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(self.yearPickerContainer)
            make.height.equalTo(50)
        }
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: nil, action: nil)
        
        cancelButton.rx.tap.subscribe(onNext: { _ in
            self.yearPickerContainer.isHidden = true
        }).disposed(by: disposeBag)
        self.yearPickerBar.setItems([cancelButton], animated: false)
        self.yearPickerBar.sizeToFit()
        self.yearPickerBar.isUserInteractionEnabled = true
    }
    
    func initYearPickerView() {
        self.view.addSubview(yearPickerContainer)
        yearPickerContainer.addSubview(self.yearPicker)
        yearPickerContainer.addSubview(self.yearPickerBar)
        yearPickerContainer.backgroundColor = .white
        yearPickerContainer.snp.makeConstraints { make in
            make.left.right.bottom.width.equalTo(self.view)
            make.top.equalTo(self.view.snp.centerY)
            //make.top.equalTo(self.view.snp.centerY)
        }
    }
    //
}

class MeetCell: UITableViewCell {
    let meetName = UILabel()
    let meetStatusWrapper = UIImageView()
    let meetDate = UILabel()
    let meetLocation = UILabel()
    let meetLocationIcon = UIImageView()
    var disposeBag = DisposeBag()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(meetName)
        self.contentView.addSubview(meetStatusWrapper)
        self.contentView.addSubview(meetDate)
        self.contentView.addSubview(meetLocation)
        self.contentView.addSubview(meetLocationIcon)

        self.meetName.snp.makeConstraints { make in
            make.left.equalTo(self.contentView).offset(30)
            make.height.equalTo(30)
        }
        self.meetStatusWrapper.snp.makeConstraints { make in
            make.width.height.equalTo(30)
        }
        
        meetDate.font = UIFont.systemFont(ofSize: 10)

        self.meetDate.snp.makeConstraints { make in
            make.left.equalTo(meetName)
            make.top.equalTo(meetName.snp.bottom)
            make.height.equalTo(10)
            make.width.greaterThanOrEqualTo(0)
        }
        self.meetLocationIcon.snp.makeConstraints { make in
            make.left.equalTo(meetDate.snp.right).offset(5)
            make.width.height.equalTo(10)
            make.top.equalTo(meetDate)
        }
        self.meetLocationIcon.image = UIImage.fontAwesomeIcon(name: .mapMarkerAlt, style: .solid, textColor: .black, size: CGSize(width: 10, height: 10))
        meetLocation.font = UIFont.systemFont(ofSize: 10)
        self.meetLocation.snp.makeConstraints { make in
            make.top.bottom.equalTo(meetDate)
            make.left.equalTo(meetLocationIcon.snp.right).offset(5)
            // make.right.equalToSuperview()
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
