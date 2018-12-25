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


func presentAthleteController(nav: UINavigationController, teamID: String, sportMode: String) -> Observable<JSON> {
    let viewController = AthleteSearchController()
    viewController.schoolID = teamID
    viewController.sportMode = sportMode
    
    let athlete = viewController
        .selectedAthlete
    
    nav.pushViewController(viewController, animated: true)
    
    return athlete
}
func presentTeamController(nav: UINavigationController) -> Observable<[String: String]> {
    let viewController = TeamSearchController()
    
    let team = viewController
        .selectedTeam
    nav.pushViewController(viewController, animated: true)
    
    return team
}

