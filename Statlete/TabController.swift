//
//  TabController.swift
//  Statlete
//
//  Created by Peter Stenger on 9/23/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import UIKit
import FontAwesome_swift

class TabController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self

        // https://www.appcoda.com/swift-delegate/
        let options = UINavigationController(rootViewController: OptionsController())
        let individual = IndividualStatsController()
        // let team = TeamStatsController()
        // let rankings = TeamRankingsController()
        self.viewControllers = [options, individual]
        let viewControllerIcons: [FontAwesome] = [.slidersH, .user] //.users*, .medal
        for index in 0..<self.viewControllers!.count {
            
            let icon = UIImage.fontAwesomeIcon(name: viewControllerIcons[index], style: .solid, textColor: UIColor.black, size: CGSize(width: 40, height: 40))
            let tabBar = UITabBarItem(title: "", image: icon, selectedImage: icon)
            // https://stackoverflow.com/questions/26494130/remove-tab-bar-item-text-show-only-image
            tabBar.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
            self.viewControllers![index].tabBarItem = tabBar
        }
        // https://stackoverflow.com/questions/34039475/programmatically-set-the-uitabbaritem-icon-for-every-linked-viewcontroller/43591493
        // https://medium.com/@unicornmobile/uitabbarcontroller-programmatically-316b89b5b21b
        // https://stackoverflow.com/questions/30849030/swift-how-to-execute-an-action-when-uitabbaritem-is-pressed
        let setupComplete = UserDefaults.standard.bool(forKey: "setupComplete")
        let spectatorMode = false
        if setupComplete && spectatorMode {
            self.selectedIndex = 1
        } else if setupComplete {
            self.selectedIndex = 1
        } else {
            self.selectedIndex = 0
        }
    }
    

}
