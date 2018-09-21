//
//  ViewController.swift
//  Statlete
//
//  Created by Peter Stenger on 9/18/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import UIKit
import SnapKit //ui layout
import Alamofire //networking
import Kanna //html parsing

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()


    }
    override func viewDidAppear(_ animated: Bool) {
        let finishedSetup = UserDefaults.standard.bool(forKey: "finishedSetup")
        if finishedSetup {
            print("finished Setup")
        } else {
            let settingsController:UIViewController = SettingsController()
            self.present(settingsController, animated: true)
        }
    }


}

