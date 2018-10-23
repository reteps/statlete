//
//  TeamStatsController.swift
//  Statlete
//
//  Created by Peter Stenger on 9/28/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import UIKit

class TeamStatsController: UIViewController {
    var schoolName = UserDefaults.standard.string(forKey: "schoolName")
    let sportMode = UserDefaults.standard.string(forKey: "sportMode")
    var schoolID = UserDefaults.standard.string(forKey: "schoolID")

    override func viewDidLoad() {
        super.viewDidLoad()
        let times = teamTimes(type: "TrackAndField", teamID: self.schoolID!)
        print(times)
    }

}
