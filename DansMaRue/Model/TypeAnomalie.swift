//
//  TypeAnomalie.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 30/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit

class TypeAnomalie : NSObject, NSCopying {
    
    //MARK: Properties
    var categorieId: String
    var parentId: String
    var name: String
    var alias: String
    var childrensId: [String]
    var imageFromWS: UIImage
    var isAgent: Bool
    var messageBO: String
    
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
        static let isAgent = "isAgent"
        static let messageBO = "messageBO"
        static let horsDMR = "horsDMR"
        static let messageHorsDMR = "messageHorsDMR"
    }

    
    //MARK: Initialization
    override init() {
        self.categorieId = ""
        self.parentId = ""
        self.name = ""
        self.alias = ""
        self.childrensId = []
        self.imageFromWS = UIImage()
        self.isAgent = false
        self.messageBO = ""
    }
    
    init(categorieId: String, parentId: String, name: String, alias: String, childrensId: [String], imageFromWS: UIImage, isAgent: Bool, messageBO: String) {
        self.categorieId = categorieId
        self.parentId = parentId
        self.name = name
        self.alias = alias
        self.childrensId = childrensId
        self.imageFromWS = imageFromWS
        self.isAgent = isAgent
        self.messageBO = messageBO
       }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = TypeAnomalie(categorieId: categorieId, parentId: parentId, name: name, alias: alias, childrensId: childrensId, imageFromWS: imageFromWS, isAgent: isAgent, messageBO: messageBO)
        return copy
    }
        
    override func isEqual(_ object: Any?) -> Bool {
        return categorieId == (object as? TypeAnomalie)?.categorieId
    }

}
