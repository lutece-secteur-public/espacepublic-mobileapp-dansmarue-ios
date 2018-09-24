//
//  TypeAnomalie.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 30/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit

class TypeAnomalie : NSObject {
    
    //MARK: Properties
    var categorieId: String
    var parentId: String
    var name: String
    var alias: String
    var childrensId: [String]
    var imageFromWS: UIImage
    
    var image: UIImage {
        if let image = UIImage(named: "icon_\(categorieId)") {
            return image
        }        
        return imageFromWS
    }
    
    var isRootCategorie: Bool {
        return parentId == "0"
    }

    struct PropertyKey {
        static let name = "name"
        static let alias = "alias"
        static let categorieId = "categorieId"
        static let parentId = "parent_id"
        static let childrensId = "children_id"
        static let image = "image"
        static let image_mobile = "image_mobile"
    }

    
    //MARK: Initialization
    override init() {
        self.categorieId = ""
        self.parentId = ""
        self.name = ""
        self.alias = ""
        self.childrensId = []
        self.imageFromWS = UIImage()
    }

}
