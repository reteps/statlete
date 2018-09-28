//
//  IndividualAthleteController.swift
//  Statlete
//
//  Created by Peter Stenger on 9/26/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import UIKit

class IndividualStatsController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Stats"
        self.view.backgroundColor = .white        
        let athleteName = UserDefaults.standard.string(forKey: "athleteName")!
        let sportMode = UserDefaults.standard.string(forKey: "sportMode")!
        let athleteID = UserDefaults.standard.integer(forKey: "athleteID")
        let athlete = individualAthlete(athleteID: athleteID, athleteName: athleteName, type: sportMode)
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
