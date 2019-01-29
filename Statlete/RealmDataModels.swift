//
//  RealmDataModels.swift
//  Statlete
//
//  Created by Peter Stenger on 1/29/19.
//  Copyright © 2019 Peter Stenger. All rights reserved.
//

import Foundation
import RealmSwift

public class Settings: Object {
    @objc dynamic var label = ""
    @objc dynamic var teamID = ""
    @objc dynamic var teamName = ""
    @objc dynamic var athleteName = ""
    @objc dynamic var athleteID = ""
    @objc dynamic var sport = ""
    @objc dynamic var lastUpdated: Date = Date()
}
