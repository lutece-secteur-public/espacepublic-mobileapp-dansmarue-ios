//
//  Equipement.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 16/10/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit
import CoreLocation

class Equipement : NSObject {
    //MARK: Properties
    var equipementId : String
    var name: String
    var adresse: String
    var longitude: Double
    var latitude: Double
    var parentId : String
    
    var position: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var anomalies = [AnomalieEquipement]()
    
    struct PropertyKey {
        static let equipementId = "equipementId"
        static let name = "name"
        static let adresse = "adresse"
        static let longitude = "longitude"
        static let latitude = "latitude"
        static let parentId = "parent_id"
    }

    
    //MARK: Initialization
    override init() {
        self.equipementId = ""
        self.name = ""
        self.adresse = ""
        self.longitude = 0
        self.latitude = 0
        self.parentId = ""
    }
    
}
