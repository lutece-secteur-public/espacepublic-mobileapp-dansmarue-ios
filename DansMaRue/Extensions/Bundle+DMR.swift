//
//  Bundle+DMR.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 30/11/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import Foundation

extension Bundle {
    var displayName: String {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? ""
    }
    
    var version : String {
        return object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }
    
    var build : String {
        return object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    }
}
