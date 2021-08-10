//
//  Priority.swift
//  DansMaRue
//
//  Created by NTDC-Showroom on 10/04/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit

public enum Priority: String {
    case genant = "3"
    case tresGenant = "2"
    case dangereux = "1"
    
    var description: String {
        switch self {
        case .dangereux:
            return "Dangereux"
        case .tresGenant:
            return "Très gênant"
        default:
            return "Gênant (valeur par défaut)"
        }
    }
    
    static let allValues = [genant, tresGenant, dangereux]
}



