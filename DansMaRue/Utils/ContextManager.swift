//
//  ContextManager.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 24/10/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import Foundation

class ContextManager {
    
    var typeContribution: TypeContribution = .outdoor {
        didSet {
            if typeContribution == .outdoor {
                typeEquipementSelected = nil
                equipementSelected = nil
            } else if typeContribution == .indoor {
                
            }
        }
    }
    
    var typeEquipementSelected: TypeEquipement?
    var equipementSelected: Equipement?

    static let shared : ContextManager = {
        let instance = ContextManager()
        
        return instance
    }()
    
}

enum TypeContribution {
    case outdoor
    case indoor
}
