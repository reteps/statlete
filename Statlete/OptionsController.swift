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
    var setupComplete = PublishRelay<Bool>()
    let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.navigationItem.title = "Options"
        let setupComplete = UserDefaults.standard.bool(forKey: "setupComplete")
        if setupComplete {
                print("setup Complete")
                self.tabBarController?.tabBar.isHidden = false
                self.navigationController?.isNavigationBarHidden = false
                setDefaultValues()
                initSearchTeamButton()
                initSearchAthleteButton()
                initSettingsBarButton()
                self.teamButton.setTitle(self.schoolName, for: .normal)
                self.athleteButton.setTitle(self.athleteName, for: .normal)
            } else {
                print("setup is not complete")
                let settings = SettingsController()
                self.tabBarController?.tabBar.isHidden = true
                settings.setupComplete = false
                self.navigationController?.isNavigationBarHidden = true
                self.navigationController?.pushViewController(settings, animated: true)
            }
        

    }
    //https://stackoverflow.com/questions/11254697/difference-between-viewdidload-and-viewdidappear
    //https://stackoverflow.com/questions/5630649/what-is-the-difference-between-viewwillappear-and-viewdidappear
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("view appearing...")
    }
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
            settings.sportMode = self.sportMode
            self.navigationController?.pushViewController(settings, animated: true)
        }).disposed(by: self.disposeBag)
        self.navigationItem.leftBarButtonItem = settingsButton
    }
    func initSearchAthleteButton() {
        athleteButton.backgroundColor = lightBlue
        athleteButton.setTitle(self.athleteName, for: .normal)
        athleteButton.layer.cornerRadius = 10
        // credit to @danielt1263 on slack
        print(self.schoolID, self.sportMode)
        athleteButton.rx.tap.debug("athleteOptions").flatMapFirst(presentAthleteController(on: self.navigationController!, teamID: self.schoolID, sportMode: self.sportMode))
            .subscribe(onNext: { athlete in

                let indivStats = self.tabBarController!.viewControllers![1] as! IndividualStatsController
                self.athleteName = athlete["Name"].stringValue
                self.athleteID = athlete["ID"].intValue
                indivStats.athleteName = self.athleteName
                indivStats.athleteID = self.athleteID
                self.athleteButton.setTitle(self.athleteName, for: .normal)
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
        teamButton.setTitle(self.schoolName, for: .normal)
        teamButton.layer.cornerRadius = 10
        teamButton.rx.tap.flatMapFirst(presentTeamController(on: self.navigationController!))
        .subscribe(onNext: { team in
            self.schoolID = team["id"]!
            self.schoolName = team["result"]!
            self.teamButton.setTitle(self.schoolName, for: .normal)
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
func presentAthleteController(on navigation: UINavigationController, teamID: String, sportMode: String) -> () -> Observable<JSON> {
    return { [weak navigation] in
        Observable.create { observer in
            print("AC",teamID, sportMode)
            guard let nav = navigation else {
                print("error 2")
                return Disposables.create()
            }
            let viewController = AthleteSearchController()
            viewController.schoolID = teamID
            viewController.sportMode = sportMode

            let disposable = viewController
                .selectedAthlete
                .takeWhile { _ in
                    return navigation != nil
                }
                .bind(to: observer)
            nav.pushViewController(viewController, animated: true)

            return Disposables.create {
                nav.popViewController(animated: true)
                disposable.dispose()
            }
        }
    }
}
func presentTeamController(on nav: UINavigationController) -> () -> Observable<[String:String]> {
    return { [weak nav] in
        Observable.create { observer in
            guard let nav = nav else {
                print("error!!")
                return Disposables.create()
            }
            let viewController = TeamSearchController()
            let disposable = viewController
                .selectedTeam
                .takeWhile { _ in
                    return nav != nil
                }
                .bind(to: observer)
            nav.pushViewController(viewController, animated: true)
            return Disposables.create {
                nav.popViewController(animated: true)
                disposable.dispose()
            }
        }
    }
}
