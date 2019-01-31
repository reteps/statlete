//
//  YearPicker.swift
//  Statlete
//
//  Created by Peter Stenger on 1/29/19.
//  Copyright © 2019 Peter Stenger. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class YearPicker: UIViewController {
    let picker = UIPickerView()
    let yearSelected = PublishSubject<String>()
    var id = ""
    var sport = Sport.None
    let invisButton = UIButton()
    let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        self.view.isOpaque = false
        self.view.addSubview(invisButton)
        self.view.addSubview(picker)
        picker.backgroundColor = .white
        picker.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(300)
        }
        getCalendarYears(sport: sport, teamID: id).bind(to: self.picker.rx.itemTitles) { _, item in
            return item
        }.disposed(by: disposeBag)
        
        self.picker.rx.modelSelected(String.self).subscribe(onNext: { _ in
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
        self.picker.rx.modelSelected(String.self).map { $0[0] }
        .bind(to: self.yearSelected).disposed(by: disposeBag)
        invisButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        invisButton.rx.tap.subscribe(onNext: { [unowned self] _ in
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
    }
    

}
