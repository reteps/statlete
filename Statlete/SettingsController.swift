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
    var selectedSegmentIndex: Int = 0
    let teamButton = UIButton()
    let segmentedControl = UISegmentedControl(items: ["Cross Country", "Track"])
    let athleteButton = UIButton()
    let spectateButton = UIButton()
    var schoolID = ""
    var schoolName = ""
    let disposeBag = DisposeBag()
    var setupComplete = false
    let lightBlue = UIColor(red: 21/255, green: 126/255, blue: 251/255, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        CreateModeSwitcher()
        CreateSearchTeamButton()
        if setupComplete {
            self.schoolName = UserDefaults.standard.string(forKey: "schoolName")!
            self.schoolID = UserDefaults.standard.string(forKey: "schoolID")!
            let athleteName = UserDefaults.standard.string(forKey: "athleteName")!
            self.teamButton.setTitle(self.schoolName + " >", for: .normal)
            self.CreateSearchAthleteButton()
            self.athleteButton.setTitle(athleteName + " >", for: .normal)
            self.CreateSpectateButton()
        }

    }
    @objc func buttonAction(sender: UIButton!) {
        if (sender == teamButton) {
            let teamSearch = TeamSearchController()
            teamSearch.selectedTeam.asObservable().debug("receive").subscribe(onNext: { team in
                self.schoolID = team["id"]!
                self.schoolName = team["result"]!
                self.teamButton.setTitle(self.schoolName + " >", for: .normal)
                self.CreateSearchAthleteButton()
                self.CreateSpectateButton()
            }).disposed(by: disposeBag)
            print("pushing team search")
            self.navigationController?.pushViewController(teamSearch, animated: true)

        } else if sender == athleteButton {
            let athleteSearch = AthleteSearchController()
            let modes = ["CrossCountry", "TrackAndField"]
            athleteSearch.sportMode = modes[segmentedControl.selectedSegmentIndex]
            athleteSearch.schoolID = self.schoolID
            athleteSearch.schoolName = self.schoolName
            /*athleteSearch.athleteSelection = { (_, athleteName) in
                self.athleteButton.setTitle(athleteName, for: .normal)
                self.navigationController?.popViewController(animated: true)
            }*/
            self.navigationController?.pushViewController(athleteSearch, animated: true)
        } else if sender == spectateButton {
            print("spectate Button clicked")
        }
    }

    func CreateModeSwitcher() {
        segmentedControl.selectedSegmentIndex = selectedSegmentIndex
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
    func CreateSearchTeamButton() {
        teamButton.backgroundColor = lightBlue
        teamButton.clipsToBounds = true
        teamButton.setTitle("Select Team", for: .normal)
        teamButton.layer.cornerRadius = 10
        teamButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.view.addSubview(teamButton)
        teamButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view).offset(-200)
            make.height.equalTo(50)
            make.width.equalTo(150)
        }
    }
    func CreateSearchAthleteButton() {
        athleteButton.backgroundColor = lightBlue
        athleteButton.setTitle("Choose Athlete", for: .normal)
        athleteButton.layer.cornerRadius = 10
        athleteButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.view.addSubview(athleteButton)
        athleteButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view).offset(-90)
            make.centerY.equalTo(self.view).offset(0)
            make.height.equalTo(50)
            make.width.equalTo(150)
        }
    }
    func CreateSpectateButton() {
        spectateButton.backgroundColor = .white
        let lightBlue = UIColor(red: 21/255, green: 126/255, blue: 251/255, alpha: 1.0)
        spectateButton.layer.borderColor = lightBlue.cgColor
        spectateButton.layer.cornerRadius = 10
        spectateButton.layer.borderWidth = 1
        spectateButton.setTitleColor(lightBlue, for: .normal)
        spectateButton.setTitle("Spectate Team", for: .normal)
        spectateButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.view.addSubview(spectateButton)
        spectateButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view).offset(90)
            make.centerY.equalTo(self.view).offset(0)
            make.height.equalTo(50)
            make.width.equalTo(150)
        }
    }


}
