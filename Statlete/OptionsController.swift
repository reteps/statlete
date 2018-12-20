//
//  OptionsController.swift
//  Statlete
//
//  Created by Peter Stenger on 9/28/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ChameleonFramework
import SwiftyJSON

class OptionsController: UIViewController {
    var teamButton = UIButton()
    var athleteButton = UIButton()
    let lightBlue = UIColor(red: 21/255, green: 126/255, blue: 251/255, alpha: 1.0)
    var schoolID = ""
    var schoolName = ""
    var athleteName = ""
    var sportMode = ""
    var athleteID = 0
    var sentToSetup = false
    let disposeBag = DisposeBag()
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.sentToSetup {
            initUI()
            self.sentToSetup.toggle()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.navigationItem.title = "Options"
        let setupComplete = UserDefaults.standard.bool(forKey: "setupComplete")
        if setupComplete {
            setDefaultValues()
            initUI()
        } else {
                self.sentToSetup = true
                self.navigationController?.pushViewController(SettingsController(), animated: true)
                print("yeah do this")
        }
        

    }
    func initUI() {
        initSearchTeamButton()
        initSearchAthleteButton()
        initSettingsBarButton()
        self.teamButton.setTitle(self.schoolName + " ➤", for: .normal)
        self.athleteButton.setTitle(self.athleteName + " ➤", for: .normal)
    }
    //https://stackoverflow.com/questions/11254697/difference-between-viewdidload-and-viewdidappear
    //https://stackoverflow.com/questions/5630649/what-is-the-difference-between-viewwillappear-and-viewdidappear

    func setDefaultValues() {
        self.sportMode = UserDefaults.standard.string(forKey: "sportMode")!
        self.schoolID = UserDefaults.standard.string(forKey: "schoolID")!
        self.schoolName = UserDefaults.standard.string(forKey: "schoolName")!
        self.athleteID = UserDefaults.standard.integer(forKey: "athleteID")
        self.athleteName = UserDefaults.standard.string(forKey: "athleteName")!
    }

    // https://stackoverflow.com/questions/27651507/passing-data-between-tab-viewed-controllers-in-swift
    func initSettingsBarButton() {
        let settingsButton = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: nil)
        settingsButton.rx.tap.subscribe(onNext: {
            let settings = SettingsController()
            settings.setupComplete = true
            self.navigationController?.pushViewController(settings, animated: true)
        }).disposed(by: self.disposeBag)
        self.navigationItem.leftBarButtonItem = settingsButton
    }
    func initSearchAthleteButton() {
        athleteButton.backgroundColor = lightBlue
        athleteButton.setTitle(self.athleteName + " ➤", for: .normal)
        athleteButton.layer.cornerRadius = 10
        // credit to @danielt1263 on slack
        print(self.schoolID, self.sportMode)
        athleteButton.rx.tap.debug("athleteOptions").flatMapFirst { [unowned self] _ -> Observable<JSON> in
            let schoolID = self.schoolID
            let sportMode = self.sportMode
            return presentAthleteController(nav: self.navigationController!, teamID: schoolID, sportMode: sportMode)
            }.do(onNext: { [unowned self] _ in
                self.navigationController!.popViewController(animated: true)
            })
            .subscribe(onNext: { athlete in

                let indivStats = self.tabBarController!.viewControllers![1] as! IndividualStatsController
                self.athleteName = athlete["Name"].stringValue
                self.athleteID = athlete["ID"].intValue
                indivStats.shouldUpdateData = true
                indivStats.athleteName = self.athleteName
                indivStats.athleteID = self.athleteID
                self.athleteButton.setTitle(self.athleteName + " ➤", for: .normal)
            }).disposed(by: disposeBag)
        self.view.addSubview(athleteButton)
        athleteButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view)
            make.height.equalTo(50)
            make.width.equalTo(300)
        }
    }
    func initSearchTeamButton() {
        teamButton.backgroundColor = lightBlue
        teamButton.clipsToBounds = true
        teamButton.setTitle(self.schoolName + " ➤", for: .normal)
        teamButton.layer.cornerRadius = 10
        teamButton.rx.tap.flatMapFirst { _ -> Observable<[String: String]> in
            return presentTeamController(nav: self.navigationController!)
        }.do(onNext: { [unowned self] _ in
                self.navigationController!.popViewController(animated: true)
            })
        .subscribe(onNext: { team in
            
            let meetViewNav = self.tabBarController!.viewControllers![2] as! UINavigationController
            let meetView = meetViewNav.topViewController as! MeetViewController
            self.schoolID = team["id"]!
            self.schoolName = team["result"]!
            meetView.schoolName = self.schoolName
            meetView.schoolID = self.schoolID
            meetView.shouldUpdateData = true

            self.teamButton.setTitle(self.schoolName + " ➤", for: .normal)
            self.athleteButton.setTitle("Choose Athlete", for: .normal)
        })
        .disposed(by: disposeBag)
        self.view.addSubview(teamButton)
        teamButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view).multipliedBy(0.75)
            make.height.equalTo(50)
            make.width.equalTo(300)
        }
    }

    
}
func presentAthleteController(nav: UINavigationController, teamID: String, sportMode: String) -> Observable<JSON> {
            let viewController = AthleteSearchController()
            viewController.schoolID = teamID
            viewController.sportMode = sportMode

            let athlete = viewController
                .selectedAthlete

            nav.pushViewController(viewController, animated: true)

            return athlete
}
func presentTeamController(nav: UINavigationController) -> Observable<[String: String]> {
    let viewController = TeamSearchController()
    
    let team = viewController
        .selectedTeam
    nav.pushViewController(viewController, animated: true)
    
    return team
}
