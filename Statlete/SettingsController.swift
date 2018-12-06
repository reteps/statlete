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
    let additionalInfo = UILabel()
    let lightBlue = UIColor(red: 21/255, green: 126/255, blue: 251/255, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        initModeSwitcher()
        self.navigationItem.title = "Setup"
        initSearchTeamButton()
        initAdditionalInfo()
        if setupComplete {
            retrieveDefaults()
            self.navigationItem.title = "Settings"
            initSearchAthleteButton()
            self.teamButton.setTitle(self.schoolName  + " ➤", for: .normal)
            self.athleteButton.setTitle(self.athleteName + " ➤", for: .normal)
        } else {
            self.tabBarController?.tabBar.isHidden = true
            self.navigationController?.isNavigationBarHidden = true
        }

    }
    func initAdditionalInfo() {
        self.view.addSubview(additionalInfo)
        additionalInfo.numberOfLines = 0
        additionalInfo.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-100)
            make.left.equalToSuperview().offset(30)
            make.right.equalToSuperview().offset(-30)
            make.height.equalTo(100)
        }
        additionalInfo.layer.borderWidth = 2;
        additionalInfo.layer.borderColor = UIColor.black.cgColor
        additionalInfo.layer.cornerRadius = 10;
        additionalInfo.clipsToBounds = true;
        
        additionalInfo.text = "   Settings are only saved when\n   a new athlete is selected.\n   Created by Peter Stenger"
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
        segmentedControl.rx.value.changed.startWith(0).subscribe(onNext: { [unowned self] value in
            self.sportMode = ["CrossCountry", "TrackAndField"][self.segmentedControl.selectedSegmentIndex]
        }).disposed(by: disposeBag)
    }
    func initSearchTeamButton() {
        teamButton.backgroundColor = lightBlue
        teamButton.clipsToBounds = true
        teamButton.setTitle("Select Team", for: .normal)
        teamButton.layer.cornerRadius = 10
        // slack
        teamButton.rx.tap.flatMapFirst{ _ -> Observable<[String: String]> in
            return presentTeamController(nav: self.navigationController!)
            }
            .do(onNext: { [unowned self] _ in
                self.navigationController!.popViewController(animated: true)
            })
            .subscribe(onNext: { [unowned self] team in
                self.schoolID = team["id"]!
                self.schoolName = team["result"]!
                self.teamButton.setTitle(self.schoolName + " ➤", for: .normal)
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
    func initSearchAthleteButton() {
        athleteButton.backgroundColor = lightBlue
        athleteButton.setTitle("Choose Athlete", for: .normal)
        athleteButton.layer.cornerRadius = 10
        athleteButton.rx.tap.flatMapFirst { [unowned self] _ -> Observable<JSON> in
            let schoolID = self.schoolID
            let sportMode = self.sportMode
            return presentAthleteController(nav: self.navigationController!, teamID: schoolID, sportMode: sportMode)
            }
            .do(onNext: { [unowned self] _ in
                self.navigationController!.popViewController(animated: true)
            })
            .subscribe(onNext: { athlete in

                
                self.athleteID = athlete["ID"].intValue
                self.athleteName = athlete["Name"].stringValue

                self.athleteButton.setTitle(self.athleteName + " ➤", for: .normal)
                self.pushChangesToOtherTabs()
                self.saveSettings()
                if !self.setupComplete {
                    self.setupComplete = true
                    self.tabBarController?.tabBar.isHidden = false
                    self.navigationController?.isNavigationBarHidden = false
                }
            }).disposed(by: disposeBag)
        self.view.addSubview(athleteButton)
        athleteButton.snp.makeConstraints { (make) in
            make.centerX.centerY.equalTo(self.view)
            make.height.equalTo(50)
            make.width.equalTo(300)
        }
    }
    func pushChangesToOtherTabs() {
        let indivStats = self.tabBarController!.viewControllers![1] as! IndividualStatsController
        let meetViewNav = self.tabBarController!.viewControllers![2] as! UINavigationController
        let meetView = meetViewNav.topViewController as! MeetViewController
        meetView.schoolName = self.schoolName
        meetView.schoolID = self.schoolID
        meetView.sportMode = self.sportMode
        meetView.shouldUpdateData = true
        indivStats.athleteName = self.athleteName
        indivStats.athleteID = self.athleteID
        indivStats.sportMode = self.sportMode
        indivStats.shouldUpdateData = true
    }
}
