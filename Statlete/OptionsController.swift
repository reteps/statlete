//
//  OptionsController.swift
//  Statlete
//
//  Created by Peter Stenger on 9/28/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import UIKit

class OptionsController: UIViewController {
    var setupComplete = UserDefaults.standard.bool(forKey: "finishedSetup")

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Options"
        self.view.backgroundColor = .white
        if setupComplete {
            createView()
        } else {
            let settings = SettingsController()
            self.tabBarController?.tabBar.isHidden = true
            settings.setupComplete = setupComplete
            self.navigationController?.pushViewController(settings, animated: true)
        }
    }
    func createView() {
        let settingsButton = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(handleClick))
        self.navigationItem.leftBarButtonItem = settingsButton
    }
    @objc func handleClick(sender: UIBarButtonItem) {
        let settings = SettingsController()
        settings.setupComplete = setupComplete
        self.navigationController?.pushViewController(settings, animated: true)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
