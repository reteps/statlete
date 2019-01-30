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
import RealmSwift

class MeetViewController: UIViewController {
    var searchBar = UISearchBar()
    let disposeBag = DisposeBag()
    let yearPickerButton: UIBarButtonItem = {
        let b = UIBarButtonItem()
        b.title = "2018"
        return b
    }()
    
    let infoButton: UIBarButtonItem = {
        let b = UIBarButtonItem()
        b.title = "Info"
        return b
    }()
    var titleButton: UIButton = {
        let b = UIButton(type: .system)
        b.tintColor = .black
        b.setImage(UIImage.fontAwesomeIcon(name: .chevronDown, style: .solid, textColor: .black, size: CGSize(width: 20, height: 20)), for: .normal)
        b.semanticContentAttribute = .forceRightToLeft
        return b
    }()
    
    let races = PublishSubject<[JSON]>()
    let dateFormatter = DateFormatter()
    var tableView = UITableView()
    let realm = try! Realm()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let settings = realm.objects(Settings.self).first!
        self.navigationItem.title = settings.teamName
        titleButton.setTitle(settings.teamName, for: .normal)
        initUI()
        configureRxSwift()

    }
    func initTable() {
        self.view.addSubview(tableView)
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
        self.navigationItem.leftBarButtonItem = yearPickerButton
        self.navigationItem.titleView = titleButton
        // self.navigationItem.rightBarButtonItem = infoButton

    }
    func initUI() {
        self.view.backgroundColor = .white
        initTable()
        initNavigationItem()
    }
    func configureRxSwift() {
        let settings = realm.objects(Settings.self).first!
/*
Change year -> get new data
Change team -> get new data
*/
        //
        let individualMeet = IndividualMeetController()
        self.tableView.rx.modelSelected(CalendarMeet.self).filter {
            return $0.hasResults
        }.subscribe(onNext: { meet in
                individualMeet.meet = meet
                self.navigationController?.pushViewController(individualMeet, animated: true)
        }).disposed(by: disposeBag)

        

        let yearSelected = yearPickerButton.rx.tap.flatMap { _  -> PublishSubject<String> in
            let yearPicker = YearPicker()
            yearPicker.modalPresentationStyle = .overCurrentContext
            yearPicker.sport = settings.sport
            yearPicker.id = settings.teamID
            self.present(yearPicker, animated: true)
            return yearPicker.yearSelected
        }.share().startWith("2018")
        
        // Bind Year Selected to Title
        yearSelected.bind(to: yearPickerButton.rx.title).disposed(by: disposeBag)
        // Bind Year Selected to refreshing table
        yearSelected.flatMap { year -> Observable<[CalendarMeet]> in
            let sport = settings.sport
            let teamID = settings.teamID
            return getCalendar(year: year, sport: Sport(rawValue: sport)!, teamID: teamID)
        }.bind(to: self.tableView.rx.items) { (tableView, row, element) in
                let cell = tableView.dequeueReusableCell(withIdentifier: "MeetCell") as! MeetCell
                cell.meetName.text = element.name
                let iconType:FontAwesome = element.hasResults ? .calendarCheck : .calendarTimes
                cell.meetStatusWrapper.image = UIImage.fontAwesomeIcon(name: iconType, style: .solid, textColor: .black, size: CGSize(width: 30, height: 30))
            
                self.dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                let date = self.dateFormatter.date(from: element.date)
            
                self.dateFormatter.dateFormat = "MMM dd, Y"
                cell.meetDate.text = self.dateFormatter.string(from: date!)
            
                cell.meetLocation.text = element.location
                return cell
        }.disposed(by: disposeBag)
    }

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
