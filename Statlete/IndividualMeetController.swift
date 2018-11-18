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
    
    struct AlertAction {
        var title: String?
        var style: UIAlertAction.Style
        // Helper for creating an AlertAction
        static func action(title: String?, style: UIAlertAction.Style = .default) -> AlertAction {
            return AlertAction(title: title, style: style)
        }
    }
    
    static func present(
        in viewController: UIViewController,
        title: String?,
        message: String?,
        style: UIAlertController.Style,
        actions: [AlertAction])
        -> Observable<Int>
    {
        return Observable.create { observer in
            let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
            
            actions.enumerated().forEach { index, action in
                let action = UIAlertAction(title: action.title, style: action.style) { _ in
                    observer.onNext(index)
                    observer.onCompleted()
                }
                alertController.addAction(action)
            }
            
            viewController.present(alertController, animated: true, completion: nil)
            return Disposables.create {
                // Dismisses on .dispose()
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
    var bindResults: Bool = true
    var filterView = UIView()
    let tableView = UITableView()
    var filterActionSheet = UIAlertController()
    let testButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.filterView)
        self.filterView.snp.makeConstraints { make in
            make.width.top.left.right.equalTo(self.view)
            make.height.equalTo(200)
        }
        self.filterView.addSubview(self.testButton)
        self.testButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.testButton.setTitle("Filter", for: .normal)
        self.testButton.rx.tap.subscribe(onNext: {
            self.presentActionSheet()
        })
        self.filterView.backgroundColor = .blue
        self.tableView.snp.makeConstraints { make in
            make.top.equalTo(self.view).offset(200)
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
    func presentActionSheet() {
        // sort by: time, team,
        let actions: [UIAlertController.AlertAction] = [
            .action(title: "Time (Descending)", style: .default),
            .action(title: "Time (Ascending)", style: .default),

            .action(title: "Cancel", style: .cancel)
        ]
        UIAlertController.present(in: self, title: "Sort By", message: nil, style: .actionSheet, actions: actions)
        .subscribe(onNext: { buttonIndex in
            print(buttonIndex)
        })
        .disposed(by: disposeBag)
        

    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationItem.title = meet!.Name + " (\(meet!.Gender))"

    }
    // https://github.com/RxSwiftCommunity/RxDataSources

    func configureRx() {
        let dataSource = RxTableViewSectionedReloadDataSource<Round>(
            configureCell: { dataSource, tableView, indexPath, item in
                let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath) as! ResultCell
                cell.nameLabel.text = item.AthleteName
                cell.placeLabel.text = (item.Place == nil) ? "-" : String(item.Place!)
                cell.timeLabel.text = item.Result
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
        raceInfoFor(url: self.meet!.URL, sport: self.meet!.Sport).map { race in
            return race.Rounds
            
            }.bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        /*
        raceInfoFor(url: meet!.URL, sport: meet!.Sport)
            .filter { _ in
                return self.bindResults == true
            }.flatMapLatest {
                $0.Rounds
            }.bind(to: self.tableView.rx.items) { myTableView, row, element in
                // https://rxswift.slack.com/messages/C051G5Y6T/convo/C051G5Y6T-1538834969.000100/?thread_ts=1538834969.000100
                let cell = myTableView.dequeueReusableCell(withIdentifier: "ResultCell") as! ResultCell
                cell.placeLabel.text = element.Name
                cell.nameLabel.text = element.AthleteName
                cell.timeLabel.text = element["Result"].stringValue.replacingOccurrences(of: "[awch]", with: "", options: .regularExpression, range: nil)

                return cell
            }.disposed(by: disposeBag)*/
        
    }
}

class ResultCell: UITableViewCell {
    let placeLabel = UILabel()
    let nameLabel = UILabel()
    let timeLabel = UILabel()
    let infoButton = UIButton(type: .infoLight)
    var disposeBag = DisposeBag()
    // https://stackoverflow.com/questions/25413239/custom-uitableviewcell-programmatically-using-swift
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        print(self.contentView.frame.width)
        print(self.contentView.frame.height)
        self.contentView.addSubview(placeLabel)
        self.contentView.addSubview(nameLabel)
        self.contentView.addSubview(timeLabel)
        self.contentView.addSubview(infoButton)
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
            make.top.bottom.equalTo(placeLabel)
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
