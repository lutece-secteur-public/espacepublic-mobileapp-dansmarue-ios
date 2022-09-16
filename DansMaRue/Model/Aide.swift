//
//  Aide.swift
//  DansMaRue
//
//  Created by geoffroy.huet on 26/04/2022.
//  Copyright © 2022 VilleDeParis. All rights reserved.
//

import UIKit

class Aide : NSObject {
    
    //MARK: Properties
    var libelle: String
    var hypertexteUrl: String
    var imageUrl: String
    
    struct PropertyKey {
        static let libelle = "libelle"
        static let imageUrl = "image_url"
        static let hypertexteUrl = "hypertexte_url"
    }

    
    //MARK: Initialization
    override init() {
        self.libelle = ""
        self.imageUrl = ""
        self.hypertexteUrl = ""
    }
    
    init(libelle: String, imageUrl: String, hypertexteUrl: String) {
        self.libelle = libelle
        self.imageUrl = imageUrl
        self.hypertexteUrl = hypertexteUrl
    }
}

