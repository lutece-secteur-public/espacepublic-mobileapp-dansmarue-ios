//
//  UIButton+AnomalieDMR.swift
//  DansMaRue
//
//  Created by geoffroy.huet on 03/05/2022.
//  Copyright © 2022 VilleDeParis. All rights reserved.
//

import UIKit

class AnomalieUIButton: UIButton {
    var anomalie: Anomalie
    
    override init(frame: CGRect) {
        self.anomalie = Anomalie(id: "", address: "", latitude: 0, longitude: 0, categorieId: "", descriptive: "", priorityId: "", anomalieStatus: .Brouillon, photoCloseUrl: nil, photoFarUrl: nil, photoDoneUrl: nil, number: "", messagesSFGeneric: [(id: String, message: String)](),messagesSFTypologie:[(id: String, message: String)]())
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        self.anomalie = Anomalie(id: "", address: "", latitude: 0, longitude: 0, categorieId: "", descriptive: "", priorityId: "", anomalieStatus: .Brouillon, photoCloseUrl: nil, photoFarUrl: nil, photoDoneUrl: nil, number: "", messagesSFGeneric: [(id: String, message: String)](),messagesSFTypologie:[(id: String, message: String)]())
        super.init(coder: aDecoder)
    }
}
