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
        let setup = UserDefaults.standard.rx.observe(Bool.self, "setupComplete")
        setup.subscribe(onNext: { complete in
            if complete == true {
                self.tabBarController?.tabBar.isHidden = false
                self.navigationController?.isNavigationBarHidden = false
                self.CreateSearchAthleteButton()
                self.CreateSearchTeamButton()
                let settingsButton = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(self.handleClick))
                self.navigationItem.leftBarButtonItem = settingsButton
                self.setDefaultValues()
                self.teamButton.setTitle(self.schoolName, for: .normal)
                self.athleteButton.setTitle(self.athleteName, for: .normal)
            } else {
                let settings = SettingsController()
                self.tabBarController?.tabBar.isHidden = true
                settings.setupComplete = false
                self.navigationController?.isNavigationBarHidden = true
                self.navigationController?.pushViewController(settings, animated: true)
            }
        }).disposed(by: disposeBag)
        

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
    @objc func handleClick(sender: UIBarButtonItem) {
        let settings = SettingsController()
        settings.setupComplete = true
        self.navigationController?.pushViewController(settings, animated: true)
    }
    @objc func buttonAction(sender: UIButton!) {
        print("button pressed")
        if (sender == teamButton) {
            let teamSearch = TeamSearchController()
            teamSearch.selectedTeam.asObservable().subscribe(onNext: { team in
                //let teamStats = self.tabBarController!.viewControllers![1] as! InvididualStatsController
                self.schoolID = team["id"]!
                self.schoolName = team["result"]!
                //teamStats.schoolID = self.schoolID
                //teamStats.schoolName = self.schoolName
                self.teamButton.setTitle(self.schoolName + " >", for: .normal)
                self.athleteButton.setTitle("Choose Athlete", for: .normal)
            }).disposed(by: disposeBag)
            self.navigationController?.pushViewController(teamSearch, animated: true)
            
        } else if (sender == athleteButton) {
            let athleteSearch = AthleteSearchController()
            athleteSearch.sportMode = self.sportMode
            athleteSearch.schoolID = self.schoolID
            athleteSearch.selectedAthlete.asObservable().subscribe(onNext: {athlete in
                self.athleteButton.setTitle(athlete["Name"].stringValue, for: .normal)
                let indivStats = self.tabBarController!.viewControllers![1] as! IndividualStatsController
                indivStats.athleteName = athlete["Name"].stringValue
                indivStats.athleteID = athlete["ID"].intValue
                
            })
            self.navigationController?.pushViewController(athleteSearch, animated: true)
        }
    }
    func CreateSearchAthleteButton() {
        athleteButton.backgroundColor = lightBlue
        athleteButton.setTitle(self.athleteName, for: .normal)
        athleteButton.layer.cornerRadius = 10
        athleteButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.view.addSubview(athleteButton)
        athleteButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view).offset(0)
            make.height.equalTo(50)
            make.width.equalTo(300)
        }
    }
    func CreateSearchTeamButton() {
        teamButton.backgroundColor = lightBlue
        teamButton.clipsToBounds = true
        teamButton.setTitle(self.schoolName, for: .normal)
        teamButton.layer.cornerRadius = 10
        teamButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.view.addSubview(teamButton)
        teamButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view).offset(-200)
            make.height.equalTo(50)
            make.width.equalTo(300)
        }
    }

    
}
