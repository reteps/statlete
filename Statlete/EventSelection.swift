//
//  EventSelection.swift
//  Statlete
//
//  Created by Peter Stenger on 1/29/19.
//  Copyright © 2019 Peter Stenger. All rights reserved.
//

import UIKit
import SnapKit
import RxDataSources
import RxSwift


class EventSelection: UIViewController {
    let tableView = UITableView()
    var data = [Sport:[String]]()
    let disposeBag = DisposeBag()
    let eventSelected = PublishSubject<[Sport:String]>()
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Select Event"
        view.addSubview(tableView)
        let newData = data.map { return SectionModel(model: $0, items: $1) }
        tableView.register(UITableViewCell.self , forCellReuseIdentifier: "cell")
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        let dataSource = createDataSource()
        Observable.just(newData).bind(to: tableView.rx.items(dataSource: dataSource)).disposed(by: disposeBag)
        
        tableView.rx.itemSelected.map { path in
            return [dataSource[path[0]].model:dataSource[path]]
        }.bind(to: eventSelected).disposed(by: disposeBag)
        
        eventSelected.subscribe(onNext: { _ in
            self.navigationController?.popViewController(animated: true)
        }).disposed(by: disposeBag)
        
        
    }
    func createDataSource() -> RxTableViewSectionedReloadDataSource<SectionModel<Sport,String>> {
        let model = RxTableViewSectionedReloadDataSource<SectionModel<Sport,String>>(
            configureCell: { (dataSource, tableView, indexPath, item) in
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
                cell.textLabel?.text = item
                return cell
        }, titleForHeaderInSection: { dataSource, index in
            return dataSource[index].model.display
        })
        return model
    }
}
