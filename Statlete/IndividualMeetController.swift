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

class IndividualMeetController: UITableViewController, UISearchBarDelegate {
    
    var meet: MeetEvent? = nil
    var disposeBag = DisposeBag()
    var bindResults: Bool = true
    override func viewDidLoad() {
        super.viewDidLoad()
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
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationItem.title = meet!.Name + " (\(meet!.Gender))"

    }
    func configureRx() {
        raceInfoFor(url: meet!.URL)
            .filter { _ in
                return self.bindResults == true
            }.bind(to: self.tableView.rx.items) { myTableView, row, element in
                // https://rxswift.slack.com/messages/C051G5Y6T/convo/C051G5Y6T-1538834969.000100/?thread_ts=1538834969.000100
                let cell = myTableView.dequeueReusableCell(withIdentifier: "ResultCell") as! ResultCell
                print("Running bind, \(element["Place"].stringValue)")
                cell.placeLabel.text = element["Place"].stringValue
                cell.nameLabel.text = element["FirstName"].stringValue + " " + element["LastName"].stringValue
                cell.timeLabel.text = element["Result"].stringValue.replacingOccurrences(of: "[awch]", with: "", options: .regularExpression, range: nil)
                cell.infoButton.rx.tap.subscribe(onNext: { _ in
                    let url = "https://athletic.net/result/\(element["ShortCode"].stringValue)"
                    let svc = SFSafariViewController(url: URL(string: url)!)
                    self.present(svc, animated: true, completion: nil)
                }).disposed(by: self.disposeBag)
                return cell
            }.disposed(by: disposeBag)
        
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
