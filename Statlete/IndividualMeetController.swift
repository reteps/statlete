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

    var meet: MeetEvent? = nil
    var disposeBag = DisposeBag()
    let tableView = UITableView()
    var filterActionSheet = UIAlertController()
    let searchBar = UISearchBar()
    let sortButton = UIBarButtonItem()
    var titleButton: UIButton = {
        let b = UIButton(type: .system)
        b.tintColor = .black
        b.setImage(UIImage.fontAwesomeIcon(name: .chevronDown, style: .solid, textColor: .black, size: CGSize(width: 20, height: 20)), for: .normal)
        b.semanticContentAttribute = .forceRightToLeft
        return b
    }()
    
    func initSearchBar() {
        self.view.addSubview(searchBar)
        self.searchBar.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top )
            make.height.equalTo(40)
        }

    }
    
    func initTableView() {
        self.tableView.allowsSelection = false
        self.tableView.snp.makeConstraints { make in
            make.top.equalTo(self.searchBar.snp.bottom)
            make.left.right.bottom.equalTo(self.view)
        }
        self.tableView.delegate = nil
        self.tableView.dataSource = nil
        //https://www.atomicbird.com/blog/uistackview-table-cells
        self.tableView.estimatedRowHeight = 44
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.register(ResultCell.self, forCellReuseIdentifier: "ResultCell")

    }
    func initSortButton() {
        sortButton.title = "Sort"
        self.navigationItem.rightBarButtonItem = sortButton

    }
    func initUI() {
        self.view.addSubview(self.tableView)
        self.view.backgroundColor = .white
        initSearchBar()
        initTableView()
        initSortButton()
        initTitleButton()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        configureRx()
    }
    // https://stackoverflow.com/questions/49538546/how-to-obtain-a-uialertcontroller-observable-reactivecocoa-or-rxswift
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }

    func initTitleButton() {
        titleButton.setTitle(meet!.Name + " (\(meet!.Gender))", for: .normal)
        titleButton.rx.tap.subscribe(onNext: { _ in
            print("tapped")
        })
        self.navigationItem.titleView = titleButton
    }
    // https://github.com/RxSwiftCommunity/RxDataSources
    func createDataSource() -> RxTableViewSectionedReloadDataSource<Round> {
        return RxTableViewSectionedReloadDataSource<Round>(
            configureCell: { dataSource, tableView, indexPath, item in
                let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath) as! ResultCell
                let grade = (item.Grade == nil) ? "" : " (\(item.Grade!))"

                cell.nameLabel.text = item.AthleteName + grade
                cell.placeLabel.text = (item.Place == nil || item.Place == 0) ? "-" : String(item.Place!)
                cell.timeLabel.text = item.Result
                cell.teamLabel.text = item.Team ?? "N/A"
                if (item.ResultCode == nil) {
                    cell.infoButton.isHidden = true
                }

                cell.infoButton.rx.tap.subscribe(onNext: { _ in
                    let url = "https://athletic.net/result/\(item.ResultCode!)"
                    let svc = SFSafariViewController(url: URL(string: url)!)
                    self.present(svc, animated: true, completion: nil)
                }).disposed(by: cell.disposeBag)
                return cell
            }, titleForHeaderInSection: { dataSource, index in
                return dataSource.sectionModels[index].Name
            })
    }
    func configureRx() {
        let dataSource = createDataSource()
        let raceRounds = raceInfoFor(url: self.meet!.URL, sport: self.meet!.Sport).map { race in
            return race.Rounds
        }
        let options = ["Time (Fast → Slow)", "Time (Slow → Fast)", "Name (A → Z)", "Name (Z → A)", "Team (A → Z)", "Team (Z → A)"]
        let sortValue = self.sortButton.rx.tap.flatMap {
            return UIAlertController.present(in: self, title: "Sort By", message: nil, style: .actionSheet, options: options)
        }.startWith(0)
        // sortValue.map { options[$0] }.bind(to: self.filterButton.rx.title(for: .normal))
        let searchBar = self.searchBar.rx.text.orEmpty
        Observable.combineLatest(sortValue, raceRounds, searchBar) { (index, rounds, search) in
            var newRounds = rounds
            newRounds = rounds.map { round in
                var newRound = round
                switch index {
                case 0:
                    newRound.items = round.items.sorted { $0.SortValue < $1.SortValue }

                case 1:
                    newRound.items = round.items.sorted { $0.SortValue > $1.SortValue }

                case 2:
                    newRound.items = round.items.sorted { $0.AthleteName.components(separatedBy: " ").reversed().joined(separator: " ") < $1.AthleteName.components(separatedBy: " ").reversed().joined(separator: " ") }
                case 3:
                    newRound.items = round.items.sorted { $0.AthleteName.components(separatedBy: " ").reversed().joined(separator: " ") > $1.AthleteName.components(separatedBy: " ").reversed().joined(separator: " ") }
                case 4:
                    newRound.items = round.items.sorted {
                        if $0.Team == $1.Team {
                            return $0.SortValue < $1.SortValue
                        }
                        return $0.Team ?? "" < $1.Team ?? ""
                    }
                case 5:
                    newRound.items = round.items.sorted {
                        if $0.Team == $1.Team {
                            return $0.SortValue < $1.SortValue
                        }
                        return $0.Team ?? "" > $1.Team ?? ""
                    }
                default:
                    return newRound
                }
                if !search.isEmpty {
                    newRound.items = newRound.items.filter { return $0.AthleteName.range(of: search, options: .caseInsensitive) != nil || ($0.Team ?? "").range(of: search, options: .caseInsensitive) != nil
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
    // https://medium.com/app-coder-io/27-ios-open-source-libraries-to-skyrocket-your-development-301b67d3124c
    // https://medium.com/app-coder-io/33-ios-open-source-libraries-that-will-dominate-2017-4762cf3ce449
    // https://stackoverflow.com/questions/25413239/custom-uitableviewcell-programmatically-using-swift
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(placeLabel)
        self.contentView.addSubview(nameLabel)
        self.contentView.addSubview(timeLabel)
        self.contentView.addSubview(infoButton)
        self.contentView.addSubview(teamLabel)
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
    // https://github.com/ReactiveX/RxSwift/issues/437
    override func prepareForReuse() {
        super.prepareForReuse()
        self.disposeBag = DisposeBag() // because life cicle of every cell ends on prepare for reuse
    }
}
