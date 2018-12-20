//
//  UpdatedSettings.swift
//  Statlete
//
//  Created by Peter Stenger on 12/20/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import UIKit
import RxSwift
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
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        let dataSource = createDataSource()
    }
    func initUI() {
        self.view.addSubview(tableView)
        self.view.backgroundColor = .white

        initTableView()
    }
    func initTableView() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    func createDataSource() -> RxTableViewSectionedReloadDataSource<MultipleSectionModel> {
        return RxTableViewSectionedReloadDataSource<MultipleSectionModel>(
            configureCell: { (dataSource, table, idxPath, _) in
                switch dataSource[idxPath] {
                case let .InformationSectionItem(title):
                    let cell: InformationTableViewCell = table.dequeueReusableCell(forIndexPath: idxPath)
                    cell.titleLabel.text = title

                    return cell
                case let .PickableSectionItem(title, picker):
                    let cell: PickableTableViewCell = table.dequeueReusableCell(forIndexPath: idxPath)
                    cell.titleLabel.text = title
                    cell.picker = picker

                    return cell
                case let .ToggleSectionItem(title, enabled):
                    let cell: ToggleTableViewCell = table.dequeueReusableCell(forIndexPath: idxPath)
                    cell.switchControl.isOn = enabled
                    cell.titleLabel.text = title

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
    case InformationSection(title: String, items: [SectionItem])
    case ToggleSection(title: String, items: [SectionItem])
    case PickableSection(title: String, items: [SectionItem])
}

enum SectionItem {
    case InformationSectionItem(title: String)
    case ToggleSectionItem(title: String, enabled: Bool)
    case PickableSectionItem(title: String, picker: UIViewController)
}




extension MultipleSectionModel: SectionModelType {
    typealias Item = SectionItem

    var items: [SectionItem] {
        switch self {
        case .PickableSection(title: _, items: let items):
            return items.map { $0 }
        case .InformationSection(title: _, items: let items):
            return items.map { $0 }
        case .ToggleSection(title: _, items: let items):
            return items.map { $0 }
        }
    }

    init(original: MultipleSectionModel, items: [Item]) {
        switch original {
        case let .PickableSection(title: title, items: _):
            self = .PickableSection(title: title, items: items)
        case let .InformationSection(title, _):
            self = .InformationSection(title: title, items: items)
        case let .ToggleSection(title, _):
            self = .ToggleSection(title: title, items: items)
        }
    }
}

extension MultipleSectionModel {
    var title: String {
        switch self {
        case .PickableSection(title: let title, items: _):
            return title
        case .InformationSection(title: let title, items: _):
            return title
        case .ToggleSection(title: let title, items: _):
            return title
        }
    }
}

