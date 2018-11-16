//
//  SettingsController.swift
//  Statlete
//
//  Created by Peter Stenger on 9/20/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import UIKit
import Alamofire
import Kanna
import SnapKit
import RxSwift
import RxCocoa
import SwiftyJSON


// https://stackoverflow.com/questions/27880650/swift-extract-regex-matches
// Extend String to match regex
extension String {
    func matchingStrings(regex: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: []) else { return [] }
        let nsString = self as NSString
        let results = regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))
        return results.map { result in
            (0..<result.numberOfRanges).map { result.range(at: $0).location != NSNotFound
                    ? nsString.substring(with: result.range(at: $0))
                    : ""
            }
        }
    }
}

class SettingsController: UIViewController {
    
    // Create Initial Variables
    let teamButton = UIButton()
    let segmentedControl = UISegmentedControl(items: ["Cross Country", "Track"])
    let athleteButton = UIButton()
    var schoolID = ""
    var schoolName = ""
    var sportMode = ""
    var athleteID = 0
    var athleteName = ""
    let disposeBag = DisposeBag()
    var setupComplete = false
    var completedSettings = PublishSubject<[[String:String]:JSON]>()
    let lightBlue = UIColor(red: 21/255, green: 126/255, blue: 251/255, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        initModeSwitcher()
        self.navigationItem.title = "Setup"
        initSearchTeamButton()

        if setupComplete {
            retrieveDefaults()
            self.navigationItem.title = "Settings"
            initSearchAthleteButton()
            self.teamButton.setTitle(self.schoolName + " >", for: .normal)
            self.athleteButton.setTitle(self.athleteName + " >", for: .normal)
        }

    }
    func retrieveDefaults() {
        self.schoolName = UserDefaults.standard.string(forKey: "schoolName")!
        self.schoolID = UserDefaults.standard.string(forKey: "schoolID")!
        self.sportMode = UserDefaults.standard.string(forKey: "sportMode")!
        self.athleteName = UserDefaults.standard.string(forKey: "athleteName")!
    }
    func saveSettings() {
            UserDefaults.standard.set(self.athleteID,
            forKey: "athleteID")
            UserDefaults.standard.set(self.sportMode,
            forKey: "sportMode")
            UserDefaults.standard.set(self.schoolID,
            forKey: "schoolID")
            UserDefaults.standard.set(self.schoolName,
            forKey: "schoolName")
            UserDefaults.standard.set(self.athleteName,
            forKey:"athleteName")
            UserDefaults.standard.set(true,
            forKey:"setupComplete")
    }
    func initModeSwitcher() {
        let modes = ["":0,"CrossCountry":0,"TrackAndField":1]
        segmentedControl.selectedSegmentIndex = modes[self.sportMode]!
        let font: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17)]
        segmentedControl.setTitleTextAttributes(font, for: .normal)
        self.view.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view).offset(-100)
            make.height.equalTo(50)
            make.width.equalTo(300)
        }
    }
    func initSearchTeamButton() {
        teamButton.backgroundColor = lightBlue
        teamButton.clipsToBounds = true
        teamButton.setTitle("Select Team", for: .normal)
        teamButton.layer.cornerRadius = 10
        // slack
        teamButton.rx.tap.flatMapFirst(presentTeamController(on: self.navigationController!))
            .subscribe(onNext: { team in
                self.schoolID = team["id"]!
                self.schoolName = team["result"]!
                self.teamButton.setTitle(self.schoolName, for: .normal)
                if !self.setupComplete {
                    self.initSearchAthleteButton()
                }
                self.athleteButton.setTitle("Choose Athlete", for: .normal)
            }).disposed(by: disposeBag)
        
        self.view.addSubview(teamButton)
        teamButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view).offset(-200)
            make.height.equalTo(50)
            make.width.equalTo(300)
        }
    }
    func getSchoolID() -> String {
        return self.schoolID
    }
    func getSportMode() -> String {
        return self.sportMode
    }
    func initSearchAthleteButton() {
        athleteButton.backgroundColor = lightBlue
        athleteButton.setTitle("Choose Athlete", for: .normal)
        athleteButton.layer.cornerRadius = 10
        athleteButton.rx.tap.do(onNext: { _ in
            let modes = ["CrossCountry", "TrackAndField"]
            self.sportMode = modes[self.segmentedControl.selectedSegmentIndex]
            print("SM:"+self.sportMode)
            print(self.schoolID)
        }).flatMapFirst(presentAthleteController(on: self.navigationController!, teamID: getSchoolID(), sportMode: getSportMode()))
            .subscribe(onNext: { athlete in
                let indivStats = self.tabBarController!.viewControllers![1] as! IndividualStatsController
                self.athleteID = athlete["ID"].intValue
                self.athleteName = athlete["Name"].stringValue
                indivStats.athleteName = self.athleteName
                indivStats.athleteID = self.athleteID
                self.athleteButton.setTitle(self.athleteName, for: .normal)
                if !self.setupComplete {
                    self.setupComplete = true
                }
                self.saveSettings()
            }).disposed(by: disposeBag)
        self.view.addSubview(athleteButton)
        athleteButton.snp.makeConstraints { (make) in
            make.centerX.centerY.equalTo(self.view)
            make.height.equalTo(50)
            make.width.equalTo(300)
        }
    }
}
