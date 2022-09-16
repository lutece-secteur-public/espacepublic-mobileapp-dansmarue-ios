//
//  Actualite.swift
//  DansMaRue
//
//  Created by geoffroy.huet on 20/04/2022.
//  Copyright © 2022 VilleDeParis. All rights reserved.
//

import UIKit

class Actualite : NSObject {
    
    //MARK: Properties
    var actualiteId: String
    var libelle: String
    var texte: String
    var imageUrl: String
    var actif: Bool
    
    
    struct PropertyKey {
        static let actualiteId = "id"
        static let libelle = "libelle"
        static let texte = "texte"
        static let imageUrl = "image_url"
        static let actif = "actif"
    }

    
    //MARK: Initialization
    override init() {
        self.actualiteId = ""
        self.libelle = ""
        self.texte = ""
        self.imageUrl = ""
        self.actif = false
    }
    
    init(actualiteId: String, libelle: String, imageUrl: String, actif: Bool, texte: String) {
        self.actualiteId = actualiteId
        self.libelle = libelle
        self.imageUrl = imageUrl
        self.actif = actif
        self.texte = texte
       }
}
