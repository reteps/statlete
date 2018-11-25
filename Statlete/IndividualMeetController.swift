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

// https://stackoverflow.com/questions/49538546/how-to-obtain-a-uialertcontroller-observable-reactivecocoa-or-rxswift
extension UIAlertController {
    
        static func present(
            in viewController: UIViewController,
            title: String,
            message: String?,
            style: UIAlertController.Style,
            options: [String])
            -> Single<Int>
        {
            return Single<Int>.create { single in
                let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let actions = options.enumerated().map { offset, element in
                    UIAlertAction(title: element, style: .default) { _ in
                        return single(.success(offset))
                    }
                }
                for action in actions + [cancelAction] {
                    alertController.addAction(action)
                }
                
                viewController.present(alertController, animated: true, completion: nil)
                return Disposables.create {
                    alertController.dismiss(animated: true, completion: nil)
                }
            }
            
        }
    
}

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
    var filterView = UIView()
    let tableView = UITableView()
    var filterActionSheet = UIAlertController()
    let filterButton = UIButton()
    let searchBar = UISearchBar()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.filterView)
        self.filterView.snp.makeConstraints { make in
            make.width.left.right.equalTo(self.view)
            make.top.equalTo(self.topLayoutGuide.snp.bottom)
            make.height.equalTo(40)
        }
        self.filterView.addSubview(self.filterButton)
        self.filterView.addSubview(self.searchBar)
        self.searchBar.snp.makeConstraints { make in
            make.top.bottom.right.equalToSuperview()
            make.left.equalTo(self.filterButton.snp.right)
        }
        self.filterButton.snp.makeConstraints { make in
            make.top.bottom.left.equalToSuperview()
            make.width.equalTo(100)
        }
        self.searchBar.rx.text.orEmpty.subscribe( onNext: { text in
            print(text)
        })
        self.filterButton.setTitle("Sort", for: .normal)
        self.filterView.backgroundColor = .white
        self.filterButton.setTitleColor(.black, for: .normal)
        self.tableView.snp.makeConstraints { make in
            make.top.equalTo(self.filterView).offset(40)
            make.left.right.bottom.equalTo(self.view)
        }
        self.tableView.delegate = nil
        self.tableView.dataSource = nil
        //https://www.atomicbird.com/blog/uistackview-table-cells
        self.tableView.estimatedRowHeight = 44
        self.tableView.rowHeight = UITableView.automaticDimension
        let button = UIBarButtonItem(title: "Race Info", style: .done, target: self, action: nil)
        button.rx.tap.subscribe(onNext: {
            let svc = SFSafariViewController(url: URL(string: self.meet!.URL)!)
            self.present(svc, animated: true, completion: nil)
        }).disposed(by: disposeBag)
        configureRx()
        self.navigationItem.rightBarButtonItem = button
        self.tableView.register(ResultCell.self, forCellReuseIdentifier: "ResultCell")
    }
    // https://stackoverflow.com/questions/49538546/how-to-obtain-a-uialertcontroller-observable-reactivecocoa-or-rxswift
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationItem.title = meet!.Name + " (\(meet!.Gender))"

    }
    // https://github.com/RxSwiftCommunity/RxDataSources

    func configureRx() {
        let dataSource = RxTableViewSectionedReloadDataSource<Round>(
            configureCell: { dataSource, tableView, indexPath, item in
                let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath) as! ResultCell
                let grade = (item.Grade == nil) ? "" :  " (\(item.Grade!))"

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
                }).disposed(by: self.disposeBag)
                return cell
        }, titleForHeaderInSection: { dataSource, index in
            return dataSource.sectionModels[index].Name
        })
        let raceRounds = raceInfoFor(url: self.meet!.URL, sport: self.meet!.Sport).map { race in
            return race.Rounds
        }
        let options = ["Time (Fast → Slow)", "Time (Slow → Fast)", "Name (A → Z)",  "Name (Z → A)", "Team (A → Z)", "Team (Z → A)" ]

        let sortValue = self.filterButton.rx.tap.flatMap {
            return UIAlertController.present(in: self, title: "Sort By", message: nil, style: .actionSheet, options: options)
        }.startWith(0)
        Observable.combineLatest(sortValue, raceRounds) { (index, rounds) in
            var newRounds = rounds
            print("index: \(index)")
            newRounds = rounds.map { round in
                var newRound = round
                switch index {
                case 0:
                    newRound.items = round.items.sorted { $0.SortValue < $1.SortValue }

                case 1:
                    newRound.items = round.items.sorted { $0.SortValue > $1.SortValue }

                case 2:
                    newRound.items = round.items.sorted { $0.AthleteName.components(separatedBy: " ").reversed().joined(separator: " ") < $1.AthleteName.components(separatedBy: " ").reversed().joined(separator: " ")  }
                case 3:
                    newRound.items = round.items.sorted { $0.AthleteName.components(separatedBy: " ").reversed().joined(separator: " ") > $1.AthleteName.components(separatedBy: " ").reversed().joined(separator: " ") }
                case 4:
                    newRound.items = round.items.sorted { $0.Team ?? "" < $1.Team ?? ""}
                case 5:
                    newRound.items = round.items.sorted { $0.Team ?? "" > $1.Team ?? ""}
                default:
                    return newRound
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
            make.top.bottom.equalTo(placeLabel)

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
        disposeBag = DisposeBag() // because life cicle of every cell ends on prepare for reuse
    }
}
