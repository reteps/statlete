//
//  UpdatedSettings.swift
//  Statlete
//
//  Created by Peter Stenger on 12/20/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import SnapKit
// Section 3
// Display Version and Creator
// Section 2
// Add Cross Country and Track Toggle
// Add Hypothetical Activated Switch
// Section 1
// Add Home Team Picker
// Add Home Athlete Picker

class UpdatedSettings: UIViewController {
    let tableView = UITableView()
    let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        let dataSource = createDataSource()
        let sections: [MultipleSectionModel] = [
            .pickableSection(title: "Section 1",
        items: [.pickableSectionItem(title: "Default Values", view: AthleteSearchController())]),
            .toggleSection(title: "Section 2",
                               items: [.toggleSectionItem(title: "Cross Country", enabled: true)]),
            .informationSection(title: "Information",
                                items: [.informationSectionItem(title: "App Version -> 1.0")])
        ]
        Observable.just(sections)
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        self.tableView.rx.modelSelected(SectionItem.self).filter { item in
            if case SectionItem.pickableSectionItem = item {
                return true
            }
            return false

        }.map { model -> UIViewController in
            if case SectionItem.pickableSectionItem = model {
                return model.view
            }
            return UIViewController()
            // self.present(model, animated: true)
        }
        
    }
    func initUI() {
        self.view.addSubview(self.tableView)
        self.view.backgroundColor = .white
        
        initTableView()
    }
    func initTableView() {
        tableView.register(PickableTableViewCell.self, forCellReuseIdentifier: "PickableCell")
        tableView.register(ToggleTableViewCell.self, forCellReuseIdentifier: "ToggleCell")

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    func createDataSource() -> RxTableViewSectionedReloadDataSource<MultipleSectionModel> {
        return RxTableViewSectionedReloadDataSource<MultipleSectionModel>(
            configureCell: { (dataSource, table, indexPath, _) in
                switch dataSource[indexPath] {
                case let .informationSectionItem(title):
                    let cell: UITableViewCell = table.dequeueReusableCell(withIdentifier: "DefaultCell") ?? UITableViewCell(style:.default, reuseIdentifier: "DefaultCell")
                    cell.textLabel?.text = title
                    return cell
                case let .pickableSectionItem(title, view):
                    let cell: PickableTableViewCell = table.dequeueReusableCell(withIdentifier: "PickableCell",for: indexPath) as! PickableTableViewCell
                    cell.textLabel?.text = title
                    cell.viewToPresent = view

                    return cell
                case let .toggleSectionItem(title, enabled):
                    let cell: ToggleTableViewCell = table.dequeueReusableCell(withIdentifier: "ToggleCell",for: indexPath) as! ToggleTableViewCell
                    cell.toggle.isEnabled = enabled
                    cell.textLabel?.text = title

                    return cell
                }
            },
            titleForHeaderInSection: { dataSource, index in
                let section = dataSource[index]
                return section.title
            }
        )
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}
// https://github.com/RxSwiftCommunity/RxDataSources
// https://github.com/RxSwiftCommunity/RxDataSources/blob/master/Examples/Example/Example4_DifferentSectionAndItemTypes.swift
enum MultipleSectionModel {
    case informationSection(title: String, items: [SectionItem])
    case toggleSection(title: String, items: [SectionItem])
    case pickableSection(title: String, items: [SectionItem])
}

enum SectionItem {
    case informationSectionItem(title: String)
    case toggleSectionItem(title: String, enabled: Bool)
    case pickableSectionItem(title: String, view: UIViewController)
}




extension MultipleSectionModel: SectionModelType {
    typealias Item = SectionItem

    var items: [SectionItem] {
        switch self {
        case .pickableSection(title: _, items: let items):
            return items.map { $0 }
        case .informationSection(title: _, items: let items):
            return items.map { $0 }
        case .toggleSection(title: _, items: let items):
            return items.map { $0 }
        }
    }

    init(original: MultipleSectionModel, items: [Item]) {
        switch original {
        case let .pickableSection(title: title, items: _):
            self = .pickableSection(title: title, items: items)
        case let .informationSection(title, _):
            self = .informationSection(title: title, items: items)
        case let .toggleSection(title, _):
            self = .toggleSection(title: title, items: items)
        }
    }
}

extension MultipleSectionModel {
    var title: String {
        switch self {
        case .pickableSection(title: let title, items: _):
            return title
        case .informationSection(title: let title, items: _):
            return title
        case .toggleSection(title: let title, items: _):
            return title
        }
    }
}



class ToggleTableViewCell: UITableViewCell {
    var disposeBag = DisposeBag()
    var toggle = UISwitch()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(toggle)
        toggle.snp.makeConstraints { make in
            make.height.equalTo(50)
            make.width.equalTo(50)
            make.top.bottom.left.equalToSuperview()
        }
    }
    required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        self.disposeBag = DisposeBag()
    }
}

class PickableTableViewCell: UITableViewCell {
    var disposeBag = DisposeBag()
    var viewToPresent = UIViewController()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        self.disposeBag = DisposeBag()
    }
}

