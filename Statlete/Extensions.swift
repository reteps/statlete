//
//  Extensions.swift
//  Statlete
//
//  Created by Peter Stenger on 12/24/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
// https://stackoverflow.com/questions/24263007/how-to-use-hex-color-values
extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}
extension String {
    func matchingStrings(regex: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: []) else { return [] }
        let nsString = self as NSString
        let results = regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))
        return results.map { result in
            (0..<result.numberOfRanges).map { result.range(at: $0).location != NSNotFound
                ? nsString.substring(with: result.range(at: $0))
                : ""
            }
        }
    }
}
// https://stackoverflow.com/questions/49538546/how-to-obtain-a-uialertcontroller-observable-reactivecocoa-or-rxswift
extension UIAlertController {
    
    static func present(
        in viewController: UIViewController,
        title: String,
        message: String?,
        style: UIAlertController.Style,
        options: [String])
        -> Single<Int>
    {
        return Single<Int>.create { single in
            let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let actions = options.enumerated().map { offset, element in
                UIAlertAction(title: element, style: .default) { _ in
                    return single(.success(offset))
                }
            }
            for action in actions + [cancelAction] {
                alertController.addAction(action)
            }
            
            viewController.present(alertController, animated: true, completion: nil)
            return Disposables.create {
                alertController.dismiss(animated: true, completion: nil)
            }
        }
        
    }
    
}

extension UISearchBar {
    var textField: UITextField? {
        return self.value(forKey: "searchField") as? UITextField
    }
    var textFieldBackground: UIView? {
        return textField?.subviews.first
    }
}
