//
//  TypeEquipement.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 17/10/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit

class TypeEquipement : NSObject {
    //MARK: Properties
    var typeEquipementId: String
    var msgAlertNoEquipement: String
    var msgPhoto: String
    var placeholder: String
    var name: String
    var parentId: String
    var iconBase64: String
    var icon: UIImage?
    var imageBase64: String
    var image: UIImage?
    
    var childrensId: [String]
    var categoriesAnomaliesId: [String]

    struct PropertyKey {
        static let typeEquipementId = "typeEquipementId"
        static let name = "libelleEcranMobile"
        static let msgAlertNoEquipement = "msg_alert_no_equipement"
        static let msgPhoto = "msg_alert_photo"
        static let placeholder = "placeholder_searchbar"
        static let parentId = "parent_id"
        static let childrensId = "children_id"
        static let icon = "icon"
        static let image = "image"
        static let categoriesAnomaliesId = "categoriesAnomaliesId"

    }
    
    //MARK: Initialization
    override init() {
        self.typeEquipementId = ""
        self.name = ""
        self.msgAlertNoEquipement = ""
        self.msgPhoto = ""
        self.placeholder = ""
        self.parentId = "0"
        self.iconBase64 = ""
        self.imageBase64 = ""
        self.childrensId = []
        self.categoriesAnomaliesId = []
    }
    
}

class TypeContributionEquipement {
    var name: String = "Anomalie Equipement public"
    var icon: UIImage?
    
    static let shared: TypeContributionEquipement = {
        let instance = TypeContributionEquipement()
        
        return instance
    }()
}
