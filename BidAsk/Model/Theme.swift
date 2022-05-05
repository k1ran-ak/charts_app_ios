//
//  File.swift
//  BidAsk
//
//  Created by admin on 3/25/22.
//

import Foundation
import UIKit
@propertyWrapper
struct Theme {
    let light: UIColor
    let dark: UIColor
    var wrappedValue: UIColor {
    if #available(iOS 13, *){
        return UIColor {(traitCollection: UITraitCollection) -> UIColor in
            
            if traitCollection.userInterfaceStyle == .dark {
                return self.dark
            } else {
                return self.light
            }
        }
    }
    else {
        return ThemeManager.isDarkModeSelected ? dark : light
    }
    }
}
enum ThemeManager {
    static var isDarkModeSelected = false
}

extension UIColor {
    @Theme(light: UIColor.white, dark: UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 0.18))
    static var background : UIColor
    
    @Theme(light: UIColor(red: 1, green: 0.4, blue: 0, alpha: 1), dark: UIColor.white)
    static var navigationBar : UIColor
    
    @Theme(light: UIColor.darkGray, dark: UIColor(red: 0.66, green: 0.66, blue: 0.66, alpha: 1))
    static var primaryText : UIColor
    
    @Theme(light: UIColor.black, dark: UIColor(red: 0.33, green: 0.33, blue: 0.33, alpha: 1))
    static var secondaryText : UIColor
}

protocol ThemeProtocol {
    func addThemeChangedObserver()
    func configureThemeColors()
}

extension ThemeProtocol {
    func addThemeChangedObserver() {
        
        
        if #available(iOS 13, *) {
            
        }else {
            NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "ThemeDidChangeNotification"), object: nil, queue: OperationQueue.main, using: { _ in
                self.configureThemeColors()
            })
        }
    }
}
