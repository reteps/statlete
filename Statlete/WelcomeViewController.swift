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
import RealmSwift

class WelcomeViewController: UIViewController {
    let welcomeLabel = UILabel()
    let infoLabel = UILabel()
    let nextButton = UIBarButtonItem(title: "Next", style: .plain, target: nil, action: nil)
    let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        initReactions()
        self.view.backgroundColor = .white
        self.navigationItem.rightBarButtonItem = nextButton
    }
    func initUI() {
        initWelcomeLabel()
        initInfoLabel() 
    }
    func initWelcomeLabel() {
        self.view.addSubview(welcomeLabel)
        welcomeLabel.text = "Welcome to Statlete."
        welcomeLabel.textAlignment = .center
        welcomeLabel.snp.makeConstraints { make in
            make.height.equalTo(50)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-100)
        }
    }
    func initInfoLabel() {
        self.view.addSubview(infoLabel)
        infoLabel.text = "Please setup your app to start."
        infoLabel.textAlignment = .center
        infoLabel.snp.makeConstraints { make in
            make.height.equalTo(50)
            make.width.equalToSuperview()
            make.top.equalTo(welcomeLabel.snp.bottom).offset(100)
        }
    }
    func initReactions() {
        let realm = try! Realm()
        let settings = Settings()
        settings.label = "default"
        try! realm.write() {
            realm.add(settings)
            settings.sport = Sport.XC.raw
        }
        let teamSearch = TeamSearchController()
        let athleteSearch = AthleteSearchController()
        nextButton.rx.tap.debug("sentToTeam").subscribe(onNext: { [unowned self] in
            self.navigationController?.pushViewController(teamSearch, animated: true)
        }).disposed(by: disposeBag)
        
        teamSearch.selectedTeam.debug("sentToAthlete").subscribe(onNext: { [unowned self] team in
            athleteSearch.team = team
            try! realm.write() {
                settings.teamID = team.code
                settings.teamName = team.name
            }
            self.navigationController?.pushViewController(athleteSearch, animated: true)
        }).disposed(by: disposeBag)
        
        athleteSearch.selectedAthlete.subscribe(onNext: { athlete in
            try! realm.write() {
                settings.athleteName = athlete.name
                settings.athleteID = athlete.id
                settings.lastUpdated = Date()
            }
            UserDefaults.standard.set(true, forKey:"setupComplete")
            self.tabBarController?.selectedIndex = 0
            self.tabBarController?.tabBar.isHidden = false
            self.tabBarController?.viewControllers?.remove(at: 3)
        }).disposed(by: disposeBag)
    }
}
