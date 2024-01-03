//
//  UIColor+DMR.swift
//  DansMaRue
//
//  Created by xavier.noel on 28/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: CGFloat(a)/255)
    }

    class func pinkButtonDmr() -> UIColor {
        return UIColor(hexString: "#B1002D")
    }

    class func pinkDmr() -> UIColor {
        return UIColor(hexString: "#B1002D")
    }

    class func lightGreyDmr() -> UIColor {
        return UIColor(red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1.0)
    }

    class func midLightGreyDmr() -> UIColor {
        return UIColor(red: 200.0/255.0, green: 200.0/255.0, blue: 200.0/255.0, alpha: 1.0)
    }

    class func greyDmr() -> UIColor {
        return UIColor(hexString: "#6D6F72")
    }

    class func blueDmr() -> UIColor {
        return UIColor(red: 12/255.0, green: 81/255.0, blue: 138/255.0, alpha: 0.5)
    }

    class func greenDmr() -> UIColor {
        return UIColor(red: 67/255.0, green: 181/255.0, blue: 126/255.0, alpha: 1)
    }

    class func orangeDmr() -> UIColor {
        return UIColor(red: 247/255.0, green: 127/255.0, blue: 104/255.0, alpha: 1)
    }
}
