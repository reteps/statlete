//
//  WelcomeViewController.swift
//  Statlete
//
//  Created by Peter Stenger on 12/24/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import UIKit
import SnapKit
import RxCocoa
import RxSwift
import SwiftyJSON

class WelcomeViewController: UIViewController {
    let welcomeLabel = UILabel()
    let nextButton = UIBarButtonItem(title: "Next", style: .plain, target: nil, action: nil)
    let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .blue
        self.view.addSubview(welcomeLabel)
        welcomeLabel.text = "Welcome to Statlete. Please detup your team to start."
        welcomeLabel.snp.makeConstraints { make in
            make.height.width.equalTo(200)
            make.centerX.centerY.equalToSuperview()
        }
        let teamSearch = TeamSearchController()
        let athleteSearch = AthleteSearchController()
        self.navigationItem.rightBarButtonItem = nextButton
        nextButton.rx.tap.subscribe(onNext: {
            self.navigationController?.setNavigationBarHidden(true, animated: true)

            self.navigationController?.pushViewController(teamSearch, animated: true)
        }).disposed(by: disposeBag)
        teamSearch.selectedTeam.subscribe(onNext: { team in
            athleteSearch.schoolID = team["id"] ?? ""
            self.navigationController?.pushViewController(athleteSearch, animated: true)
        }).disposed(by: disposeBag)
        athleteSearch.selectedAthlete.subscribe(onNext: { athlete in
            print(athlete)
        }).disposed(by: disposeBag)
        
        // Do any additional setup after loading the view.
    }
}
