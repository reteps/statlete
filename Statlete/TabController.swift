//
//  TabController.swift
//  Statlete
//
//  Created by Peter Stenger on 9/23/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import UIKit
import FontAwesome_swift

class TabController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create View Controllers
        //
        let options = UINavigationController(rootViewController: OptionsController())
        let individual = IndividualStatsController()
        let team = TeamStatsController()
        let rankings = TeamRankingsController()
        self.viewControllers = [options, team, individual, rankings]
        let viewControllerIcons: [FontAwesome] = [.slidersH, .users, .user, .medal]
        for index in 0..<self.viewControllers!.count {
            
            let icon = UIImage.fontAwesomeIcon(name: viewControllerIcons[index], style: .solid, textColor: UIColor.black, size: CGSize(width: 30, height: 30))
            print(icon)
            let tabBar = UITabBarItem()
            tabBar.image = icon
            //title: self.viewControllers![index].title, image: icon, selectedImage: icon)
            print(tabBar)
            self.viewControllers![index].tabBarItem = tabBar
        }
        // items[.user]!.tabBarItem = FontAwesomeTabBarItem()

        // Set Icons
        // https://stackoverflow.com/questions/34039475/programmatically-set-the-uitabbaritem-icon-for-every-linked-viewcontroller/43591493
        // https://medium.com/@unicornmobile/uitabbarcontroller-programmatically-316b89b5b21b
        // https://stackoverflow.com/questions/30849030/swift-how-to-execute-an-action-when-uitabbaritem-is-pressed
        let finishedSetup = UserDefaults.standard.bool(forKey: "finishedSetup")
        if finishedSetup {
            self.selectedIndex = 1
        } else {
            self.selectedIndex = 0
        }
    }
    

}
