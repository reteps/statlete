//
//  jsonDecoders.swift
//  Statlete
//
//  Created by Peter Stenger on 9/20/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import Foundation
/*
Search Data
*/

struct SearchResponse: Codable {
    let d: ResponseData
}
struct ResponseData: Codable {
    let count: Int
    let results: String
    let __type: String
    let runTime: String
    let pager: String
}
/*
Token Data
*/
struct TokenData: Codable {
    let sport: String
    let SchoolID, SeasonID, MembershipLevel: Int
    let TwitterUser: JSONNull?
    let addEventUrl: String
    let UserID: Int
    let photoStyle: String?
    let isCoach, isAuthenticatedWithGoodStanding, editPermission, admin: Bool
    let isTeamAthlete: Bool
    let publicToken: String
    let editToken, uploadToken: JSONNull?
    let guid, embedToken: String
    let coverPhoto: JSONNull?
    let isTLogAdmin: Bool
    let athleteCoachToken: String
    let stripeKey: JSONNull?
    let live: Bool

}

/*
 Team Data
*/

struct TeamData: Codable {
    let team: TeamDataTeam
    let grades: [Grade]
    let teamNav: TeamNav
    let regions: [Region]
    let seasons: [String: Season]
    let currentCal: [CurrentCal]
    let inviteRequests: JSONNull?
    let athletes: [Athlete]
    let coaches: [Coach]
    let adHTML, tLog, userInfo: String?
    let vendors: [JSONAny]
    let cartAmounts, cartFees, subscriptions, tipOfTheDayHistory: JSONNull?
}

struct Athlete: Codable {
    let id: Int
    let name: String
    let gender: Gender
    
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case name = "Name"
        case gender = "Gender"
    }
}

enum Gender: String, Codable {
    case f = "F"
    case m = "M"
}

struct Coach: Codable {
    let id: Int
    let name, position: String
    let photoURL: JSONNull?
    let daysSinceActive: Int
    let photoToken: String
    
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case name = "Name"
        case position = "Position"
        case photoURL = "PhotoUrl"
        case daysSinceActive = "DaysSinceActive"
        case photoToken = "PhotoToken"
    }
}

struct CurrentCal: Codable {
    let id, dateDiff, endDateDiff: Int
    let name: String
    let type, calHasResults, meetID, meetHasResults: Int
    let streetAddress, city, state, postalCode: String?
    let country, location, date, startDate: String
    let endDate: String
    let athleteLock: String?
    let meetDepart, meetReturn: String?
    let gender: String
    let notes: String?
    let owner, meetOwner, regStatus: Int
    let regEnabled: Bool
    let invoiceID, invoiceKey, invStatus, invPreAuth: JSONNull?
    let invPayOnline: JSONNull?
    let invHasEntryFees, publishEntries, calToken, meetToken: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case dateDiff = "DateDiff"
        case endDateDiff = "EndDateDiff"
        case name = "Name"
        case type = "Type"
        case calHasResults = "CalHasResults"
        case meetID = "MeetID"
        case meetHasResults = "MeetHasResults"
        case streetAddress = "StreetAddress"
        case city = "City"
        case state = "State"
        case postalCode = "PostalCode"
        case country = "Country"
        case location = "Location"
        case date = "Date"
        case startDate = "StartDate"
        case endDate = "EndDate"
        case athleteLock = "AthleteLock"
        case meetDepart = "MeetDepart"
        case meetReturn = "MeetReturn"
        case gender = "Gender"
        case notes = "Notes"
        case owner = "Owner"
        case meetOwner = "MeetOwner"
        case regStatus = "RegStatus"
        case regEnabled = "RegEnabled"
        case invoiceID = "InvoiceID"
        case invoiceKey = "InvoiceKey"
        case invStatus = "InvStatus"
        case invPreAuth = "InvPreAuth"
        case invPayOnline = "InvPayOnline"
        case invHasEntryFees = "InvHasEntryFees"
        case publishEntries = "PublishEntries"
        case calToken = "CalToken"
        case meetToken = "MeetToken"
    }
}

struct Grade: Codable {
    let idGrade: Int
    let gradeDesc: String
    
    enum CodingKeys: String, CodingKey {
        case idGrade = "IDGrade"
        case gradeDesc = "GradeDesc"
    }
}

struct Region: Codable {
    let id: Int
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case name = "Name"
    }
}

struct Season: Codable {
    let id: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "ID"
    }
}

struct TeamDataTeam: Codable {
    let name: String?
    let level, teamRecords: Int
    let address, city, state, zipCode: String?
    let phone: String?
    let fax: String?
    let url, urlTeam: String?
    let prefStore, prepSportID, accountLock, regionID: Int
    let hasPhotos: Bool
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case level = "Level"
        case teamRecords = "TeamRecords"
        case address = "Address"
        case city = "City"
        case state = "State"
        case zipCode = "ZipCode"
        case phone = "Phone"
        case fax = "Fax"
        case url = "URL"
        case urlTeam = "URLTeam"
        case prefStore = "PrefStore"
        case prepSportID = "PrepSportID"
        case accountLock = "AccountLock"
        case regionID = "RegionID"
        case hasPhotos
    }
}

struct TeamNav: Codable {
    let team: TeamNavTeam
    let userAthleteIDOnTeam: Int
    let hasCoachAccess: Bool
    let mascotToken: String?
    let grades: [Grade]
    let divisions: [Division]
    let customLists: CustomLists
    let customDivisions: [JSONAny]
    
    enum CodingKeys: String, CodingKey {
        case team
        case userAthleteIDOnTeam = "userAthleteIdOnTeam"
        case hasCoachAccess, mascotToken, grades, divisions, customLists, customDivisions
    }
}

struct CustomLists: Codable {
}

struct Division: Codable {
    let id, b: Int
    let name: String
}

struct TeamNavTeam: Codable {
    let name: String
    let level: Int
    let city, state: String
    let mascot: String?
    let mascotGUID: String?
    let teamRecords, siteSupport: Int
    let colors: [String?]
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case level = "Level"
        case city = "City"
        case state = "State"
        case mascot = "Mascot"
        case mascotGUID = "MascotGUID"
        case teamRecords = "TeamRecords"
        case siteSupport, colors
    }
}

// MARK: Encode/decode helpers

class JSONNull: Codable, Hashable {
    
    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }
    
    public var hashValue: Int {
        return 0
    }
    
    public init() {}
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

class JSONCodingKey: CodingKey {
    let key: String
    
    required init?(intValue: Int) {
        return nil
    }
    
    required init?(stringValue: String) {
        key = stringValue
    }
    
    var intValue: Int? {
        return nil
    }
    
    var stringValue: String {
        return key
    }
}

class JSONAny: Codable {
    let value: Any
    
    static func decodingError(forCodingPath codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode JSONAny")
        return DecodingError.typeMismatch(JSONAny.self, context)
    }
    
    static func encodingError(forValue value: Any, codingPath: [CodingKey]) -> EncodingError {
        let context = EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode JSONAny")
        return EncodingError.invalidValue(value, context)
    }
    
    static func decode(from container: SingleValueDecodingContainer) throws -> Any {
        if let value = try? container.decode(Bool.self) {
            return value
        }
        if let value = try? container.decode(Int64.self) {
            return value
        }
        if let value = try? container.decode(Double.self) {
            return value
        }
        if let value = try? container.decode(String.self) {
            return value
        }
        if container.decodeNil() {
            return JSONNull()
        }
        throw decodingError(forCodingPath: container.codingPath)
    }
    
    static func decode(from container: inout UnkeyedDecodingContainer) throws -> Any {
        if let value = try? container.decode(Bool.self) {
            return value
        }
        if let value = try? container.decode(Int64.self) {
            return value
        }
        if let value = try? container.decode(Double.self) {
            return value
        }
        if let value = try? container.decode(String.self) {
            return value
        }
        if let value = try? container.decodeNil() {
            if value {
                return JSONNull()
            }
        }
        if var container = try? container.nestedUnkeyedContainer() {
            return try decodeArray(from: &container)
        }
        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self) {
            return try decodeDictionary(from: &container)
        }
        throw decodingError(forCodingPath: container.codingPath)
    }
    
    static func decode(from container: inout KeyedDecodingContainer<JSONCodingKey>, forKey key: JSONCodingKey) throws -> Any {
        if let value = try? container.decode(Bool.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Int64.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Double.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(String.self, forKey: key) {
            return value
        }
        if let value = try? container.decodeNil(forKey: key) {
            if value {
                return JSONNull()
            }
        }
        if var container = try? container.nestedUnkeyedContainer(forKey: key) {
            return try decodeArray(from: &container)
        }
        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key) {
            return try decodeDictionary(from: &container)
        }
        throw decodingError(forCodingPath: container.codingPath)
    }
    
    static func decodeArray(from container: inout UnkeyedDecodingContainer) throws -> [Any] {
        var arr: [Any] = []
        while !container.isAtEnd {
            let value = try decode(from: &container)
            arr.append(value)
        }
        return arr
    }
    
    static func decodeDictionary(from container: inout KeyedDecodingContainer<JSONCodingKey>) throws -> [String: Any] {
        var dict = [String: Any]()
        for key in container.allKeys {
            let value = try decode(from: &container, forKey: key)
            dict[key.stringValue] = value
        }
        return dict
    }
    
    static func encode(to container: inout UnkeyedEncodingContainer, array: [Any]) throws {
        for value in array {
            if let value = value as? Bool {
                try container.encode(value)
            } else if let value = value as? Int64 {
                try container.encode(value)
            } else if let value = value as? Double {
                try container.encode(value)
            } else if let value = value as? String {
                try container.encode(value)
            } else if value is JSONNull {
                try container.encodeNil()
            } else if let value = value as? [Any] {
                var container = container.nestedUnkeyedContainer()
                try encode(to: &container, array: value)
            } else if let value = value as? [String: Any] {
                var container = container.nestedContainer(keyedBy: JSONCodingKey.self)
                try encode(to: &container, dictionary: value)
            } else {
                throw encodingError(forValue: value, codingPath: container.codingPath)
            }
        }
    }
    
    static func encode(to container: inout KeyedEncodingContainer<JSONCodingKey>, dictionary: [String: Any]) throws {
        for (key, value) in dictionary {
            let key = JSONCodingKey(stringValue: key)!
            if let value = value as? Bool {
                try container.encode(value, forKey: key)
            } else if let value = value as? Int64 {
                try container.encode(value, forKey: key)
            } else if let value = value as? Double {
                try container.encode(value, forKey: key)
            } else if let value = value as? String {
                try container.encode(value, forKey: key)
            } else if value is JSONNull {
                try container.encodeNil(forKey: key)
            } else if let value = value as? [Any] {
                var container = container.nestedUnkeyedContainer(forKey: key)
                try encode(to: &container, array: value)
            } else if let value = value as? [String: Any] {
                var container = container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
                try encode(to: &container, dictionary: value)
            } else {
                throw encodingError(forValue: value, codingPath: container.codingPath)
            }
        }
    }
    
    static func encode(to container: inout SingleValueEncodingContainer, value: Any) throws {
        if let value = value as? Bool {
            try container.encode(value)
        } else if let value = value as? Int64 {
            try container.encode(value)
        } else if let value = value as? Double {
            try container.encode(value)
        } else if let value = value as? String {
            try container.encode(value)
        } else if value is JSONNull {
            try container.encodeNil()
        } else {
            throw encodingError(forValue: value, codingPath: container.codingPath)
        }
    }
    
    public required init(from decoder: Decoder) throws {
        if var arrayContainer = try? decoder.unkeyedContainer() {
            self.value = try JSONAny.decodeArray(from: &arrayContainer)
        } else if var container = try? decoder.container(keyedBy: JSONCodingKey.self) {
            self.value = try JSONAny.decodeDictionary(from: &container)
        } else {
            let container = try decoder.singleValueContainer()
            self.value = try JSONAny.decode(from: container)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        if let arr = self.value as? [Any] {
            var container = encoder.unkeyedContainer()
            try JSONAny.encode(to: &container, array: arr)
        } else if let dict = self.value as? [String: Any] {
            var container = encoder.container(keyedBy: JSONCodingKey.self)
            try JSONAny.encode(to: &container, dictionary: dict)
        } else {
            var container = encoder.singleValueContainer()
            try JSONAny.encode(to: &container, value: self.value)
        }
    }
}
