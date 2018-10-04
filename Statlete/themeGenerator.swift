//
//  themeGenerator.swift
//  Statlete
//
//  Created by Peter Stenger on 10/3/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import Foundation
import ChameleonFramework
import RxSwift

//https://github.com/RxSwiftCommunity/RxTheme
//https://docs.swift.org/swift-book/LanguageGuide/Protocols.html
protocol Theme {
    var themeName: String { get }
    var primaryColor: UIColor { get }
    var secondaryColor: UIColor { get }
    var lightText: UIColor { get }
    var darkText: UIColor { get }
}
class LightTheme: Theme {

    var primaryColor = UIColor(hexString: "#03a9f4")!
    var secondaryColor = UIColor(hexString: "#fdd835")!
    var lightText = UIColor.white
    var darkText = UIColor.black
    var themeName = "Dark"
}

