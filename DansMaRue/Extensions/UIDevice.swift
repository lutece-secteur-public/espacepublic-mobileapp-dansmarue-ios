//
//  UIDevice.swift
//  DansMaRue
//
//  Created by NTDC-Showroom on 21/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import Foundation

import UIKit

public extension UIDevice {
    
    var deviceResolution: [String] {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPhone5,1", "iPhone5,2", "iPhone5,3", "iPhone5,4", "iPhone6,1", "iPhone6,2", "iPhone8,4":    return ["640", "1136"]
        case "iPhone7,2", "iPhone8,1", "iPhone9,1", "iPhone9,3":    return ["750", "1334"]
        case "iPhone7,1", "iPhone8,2", "iPhone9,2", "iPhone9,4":    return ["1242", "2208"]
        default:    return ["640", "1136"]
        }
    }
    
}
