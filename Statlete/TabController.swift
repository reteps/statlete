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

        // Do any additional setup after loading the view.
        let settings = UINavigationController(rootViewController: SettingsController())
        viewControllers = [settings]
        let finishedSetup = UserDefaults.standard.bool(forKey: "finishedSetup")
        if finishedSetup {
            print("finished Setup")
        } else {
            self.selectedIndex = 0
        }
    }
    

}
