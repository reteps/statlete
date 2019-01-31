//
//  IndividualMeetController.swift
//  Statlete
//
//  Created by Peter Stenger on 11/15/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import SafariServices
import RxDataSources
import FontAwesome_swift

extension Round: SectionModelType {
    typealias Item = RaceResult

    init(original: Round, items: [Item]) {
        self = original
        self.items = items
    }
}

class IndividualMeetController: UIViewController {

    var meet: CalendarMeet? = nil
    var events = [String: MeetEvent]()
    var disposeBag = DisposeBag()
    let tableView = UITableView()
    var filterActionSheet = UIAlertController()
    let searchBar = UISearchBar()
    let sortButton: UIBarButtonItem = {
        var s = UIBarButtonItem()
        s.title = "Sort"
        return s
    }()
    var titleButton: UIButton = {
        let b = UIButton(type: .system)
        b.tintColor = .black
        b.setImage(UIImage.fontAwesomeIcon(name: .chevronDown, style: .solid, textColor: .black, size: CGSize(width: 20, height: 20)), for: .normal)
        b.semanticContentAttribute = .forceRightToLeft
        return b
    }()
    
    func initSearchBar() {
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top )
            make.height.equalTo(40)
        }
        searchBar.backgroundColor = .white
        searchBar.rx.searchButtonClicked.subscribe(onNext: { _ in
            self.searchBar.endEditing(true)
        }).disposed(by: disposeBag)

    }
    
    func initTableView() {
        tableView.allowsSelection = false
        tableView.snp.makeConstraints { make in
            make.top.equalTo(self.searchBar.snp.bottom)
            make.left.right.bottom.equalTo(self.view)
        }
        tableView.delegate = nil
        tableView.dataSource = nil
        //https://www.atomicbird.com/blog/uistackview-table-cells
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(ResultCell.self, forCellReuseIdentifier: "ResultCell")

    }
    func initUI() {
        view.addSubview(tableView)
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = sortButton
        navigationItem.titleView = titleButton
        
        initSearchBar()
        initTableView()

    }
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        configureRx()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    // https://github.com/RxSwiftCommunity/RxDataSources
    func createDataSource() -> RxTableViewSectionedReloadDataSource<Round> {
        return RxTableViewSectionedReloadDataSource<Round>(
            configureCell: { dataSource, tableView, indexPath, item in
                let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath) as! ResultCell
                let grade = item.grade == nil ? "" : " (\(item.grade!))"
                cell.nameLabel.text = item.athleteName + grade
                cell.placeLabel.text = (item.place == nil || item.place == 0) ? "-" : String(item.place!)
                cell.timeLabel.text = item.time
                cell.teamLabel.text = item.team ?? "N/A"
                if (item.resultCode == nil) {
                    cell.infoButton.isHidden = true
                }

                cell.infoButton.rx.tap.subscribe(onNext: { [unowned self] _ in
                    let url = "https://athletic.net/result/\(item.resultCode!)"
                    let svc = SFSafariViewController(url: URL(string: url)!)
                    self.present(svc, animated: true, completion: nil)
                }).disposed(by: cell.disposeBag)
                return cell
            }, titleForHeaderInSection: { dataSource, index in
                return dataSource.sectionModels[index].name
            })
    }
    func configureRx() {
        let dataSource = createDataSource()
        let meetInfoUpdater = meetInfoFor(meet: meet!).debug("info").share()
        
        meetInfoUpdater.debug("data").subscribe(onNext: { [unowned self] data in
            self.events = Dictionary(data.map { ($0.name + " (\($0.gender))", $0) }) { first, _ in first }
        }).disposed(by: disposeBag)
        
        let startObservable = meetInfoUpdater
        .map { meet -> String in
            if (meet.count == 0) {
                return "No Races"
            }
            return meet.first!.name +  " (\(meet.first!.gender))"
        }

        let tapObservable = titleButton.rx.tap.debug("tapped").withLatestFrom(meetInfoUpdater)
        .map { $0.map { $0.name + " (\($0.gender))" } }
        .flatMap { [unowned self] names -> PublishSubject<[Sport:String]> in
            let eventSelection = EventSelection()
            eventSelection.data = [Sport.None:names]
            self.navigationController?.pushViewController(eventSelection, animated: true)
            return eventSelection.eventSelected
        }.map { $0.values.first! }.share()
        
        let currentEventNames = Observable.merge(startObservable, tapObservable)
        let currentEventRounds = currentEventNames
        .filter { [unowned self] _ in self.events.count != 0 }
        .map { [unowned self] event in self.events[event]!.url }
        .map { [unowned self] url in raceInfoFor(url: url, sport: self.meet!.sport) }
        .flatMap { $0.map { $0.rounds } }
        
        currentEventNames.subscribe(onNext: { [unowned self] eventName in
            self.titleButton.setTitle(eventName, for: .normal)
            self.titleButton.sizeToFit()
        }).disposed(by: disposeBag)

    
        
        let options = ["Time (Fast → Slow)", "Time (Slow → Fast)", "Name (A → Z)", "Name (Z → A)", "Team (A → Z)", "Team (Z → A)"]
        let sortValue = sortButton.rx.tap.flatMap {
            return UIAlertController.present(in: self, title: "Sort By", message: nil, style: .actionSheet, options: options)
        }.startWith(0)
        let searchText = searchBar.rx.text.orEmpty

        Observable.combineLatest(sortValue, currentEventRounds, searchText) { (index, rounds, search) in
            var newRounds = rounds
            newRounds = rounds.map { round in
                var newRound = round
                switch index {
                case 0:
                    newRound.items = round.items.sorted { $0.sortValue < $1.sortValue }

                case 1:
                    newRound.items = round.items.sorted { $0.sortValue > $1.sortValue }

                case 2:
                    newRound.items = round.items.sorted { $0.athleteName.components(separatedBy: " ").reversed().joined(separator: " ") < $1.athleteName.components(separatedBy: " ").reversed().joined(separator: " ") }
                case 3:
                    newRound.items = round.items.sorted { $0.athleteName.components(separatedBy: " ").reversed().joined(separator: " ") > $1.athleteName.components(separatedBy: " ").reversed().joined(separator: " ") }
                case 4:
                    newRound.items = round.items.sorted {
                        if $0.team == $1.team {
                            return $0.sortValue < $1.sortValue
                        }
                        return $0.team ?? "" < $1.team ?? ""
                    }
                case 5:
                    newRound.items = round.items.sorted {
                        if $0.team == $1.team {
                            return $0.sortValue < $1.sortValue
                        }
                        return $0.team ?? "" > $1.team ?? ""
                    }
                default:
                    return newRound
                }
                if !search.isEmpty {
                    newRound.items = newRound.items.filter { return $0.athleteName.range(of: search, options: .caseInsensitive) != nil || ($0.team ?? "").range(of: search, options: .caseInsensitive) != nil
                    }
                }
                return newRound
            }
            return newRounds

        }.bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)


    }
}

class ResultCell: UITableViewCell {
    let placeLabel = UILabel()
    let nameLabel = UILabel()
    let timeLabel = UILabel()
    let infoButton = UIButton(type: .infoLight)
    let teamLabel = UILabel()
    var disposeBag = DisposeBag()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(placeLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(infoButton)
        contentView.addSubview(teamLabel)
        teamLabel.font = UIFont.systemFont(ofSize: 10)
        placeLabel.layer.borderColor = UIColor.black.cgColor
        placeLabel.layer.borderWidth = 2.0
        placeLabel.font = UIFont.systemFont(ofSize: 11.5)
        placeLabel.layer.cornerRadius = 5.0
        placeLabel.textColor = .black
        placeLabel.snp.makeConstraints { make in
            make.height.equalTo(30)
            make.width.equalTo(30)
            make.left.equalTo(self.contentView).offset(10)
            make.centerY.equalTo(self.contentView)
        }
        placeLabel.textAlignment = .center

        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(placeLabel.snp.right).offset(20)
            make.top.equalTo(placeLabel).offset(-10)
            make.bottom.equalTo(placeLabel).offset(-10)
        }
        teamLabel.snp.makeConstraints { make in
            make.left.right.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom)
            make.bottom.equalTo(placeLabel)
        }
        timeLabel.snp.makeConstraints { make in
            make.right.equalTo(self.contentView).offset(-50)
            make.top.bottom.equalTo(placeLabel).offset(5)

        }
        infoButton.snp.makeConstraints { make in
            make.top.bottom.equalTo(placeLabel)
            make.right.equalTo(self.contentView).offset(-10)
        }
        nameLabel.textColor = .black
        timeLabel.textColor = .black

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        self.disposeBag = DisposeBag() // because life cicle of every cell ends on prepare for reuse
    }
}
