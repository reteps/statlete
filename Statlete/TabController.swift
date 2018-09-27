//
//  TabController.swift
//  Statlete
//
//  Created by Peter Stenger on 9/23/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import UIKit

class TabController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create View Controllers
        let settings = UINavigationController(rootViewController: SettingsController())
        let individual = IndividualAthleteController()
        
        // Set Icons
        // https://stackoverflow.com/questions/34039475/programmatically-set-the-uitabbaritem-icon-for-every-linked-viewcontroller/43591493
        // https://medium.com/@unicornmobile/uitabbarcontroller-programmatically-316b89b5b21b
        viewControllers = [settings, individual]
        let finishedSetup = UserDefaults.standard.bool(forKey: "finishedSetup")
        if finishedSetup {
            self.selectedIndex = 1
        } else {
            self.selectedIndex = 0
        }
    }
    

}
