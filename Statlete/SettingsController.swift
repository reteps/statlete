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
    let selectedSegmentIndex: Int = 0
    let setupComplete: Bool = {
        return UserDefaults.standard.bool(forKey: "finishedSetup")
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        if setupComplete {
            let settingsButton = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(handleClick))
            self.navigationItem.leftBarButtonItem = settingsButton
        } else {
            self.tabBarController?.tabBar.isHidden = true
            self.title = "Setup"
            CreateModeSwitcher()
            CreateSearchTeamButton()
        }

    }
    @objc func segmentedControlAction(sender: UISegmentedControl!) {
        let selectedSegmentIndex = sender.selectedSegmentIndex

    }
    @objc func handleClick(sender: UIBarButtonItem) {
        print("settings clicked")
    }
    @objc func teamButtonAction(sender: UIButton!) {
        let teamSearch = TeamSearchController()

        self.navigationController?.pushViewController(teamSearch, animated: true)
    }
    @objc func athleteButtonAction(sender: UIButton!) {

    }
    public func getSportMode() -> String {
        let modes = ["CrossCountry", "Track"]

        return modes[selectedSegmentIndex]
    }
    func CreateModeSwitcher() {
        let segmentedControl = UISegmentedControl(items: ["Cross Country", "Track"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentedControlAction), for: .valueChanged)
        self.view.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view).offset(-200)
            make.height.equalTo(50)
            make.width.equalTo(300)
        }
    }
    func CreateSearchTeamButton() {
        let teamButton = UIButton()
        teamButton.backgroundColor = .blue
        teamButton.clipsToBounds = true
        teamButton.setTitle("Search Team", for: .normal)
        teamButton.layer.cornerRadius = 5
        teamButton.addTarget(self, action: #selector(teamButtonAction), for: .touchUpInside)
        self.view.addSubview(teamButton)
        teamButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view).offset(-100)
            make.height.equalTo(50)
            make.width.equalTo(150)
        }
    }
    func CreateSearchAthleteButton() {
        let athleteButton = UIButton()
        athleteButton.backgroundColor = .blue
        athleteButton.setTitle("Choose Athlete", for: .normal)
        athleteButton.addTarget(self, action: #selector(athleteButtonAction), for: .touchUpInside)
        self.view.addSubview(athleteButton)
        athleteButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view).offset(0)
            make.height.equalTo(50)
            make.width.equalTo(150)
        }
    }



}


