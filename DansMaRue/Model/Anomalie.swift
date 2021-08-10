//
//  Anomalie.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 30/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit

class Anomalie : NSObject, NSCoding {
    
    //MARK: Properties
    var id: String
    var address: String
    var streetName: String = ""
    var postalCode: String = ""
    var locality: String = ""
    var latitude: Double
    var longitude: Double
    
    var categorieId: String
    var photo1: UIImage?
    var photo2: UIImage?
    var photo3: UIImage?
    var photoCloseUrl: String
    var photoFarUrl: String
    var photoDoneUrl: String
    
    var firstImageUrl: String {
        return photoFarUrl.isEmpty ? photoCloseUrl : photoFarUrl
    }
    var secondImageUrl: String {
        return photoCloseUrl.isEmpty ? photoFarUrl : photoCloseUrl
    }
    
    var nbPhoto: Int {
        var nb = 0
        if !photoCloseUrl.isEmpty {
            nb += 1
        }
        
        if !photoFarUrl.isEmpty {
            nb += 1
        }
        
        if !photoDoneUrl.isEmpty {
            nb += 1
        }
        
        return nb
    }
    
    var imageCategorie: UIImage {

        if let image = UIImage(named: "image_\(ReferalManager.shared.getRootCategorieId(fromCategorieId: self.categorieId))") {
            return image
        }
        
        return UIImage(named: Constants.Image.ramen)!
    }
    
    var iconCategorie: UIImage {

        if let image = UIImage(named: "icon_\(ReferalManager.shared.getRootCategorieId(fromCategorieId: self.categorieId))") {
            return image
        }
      
        
        return UIImage(named: Constants.Image.noImage)!
    }
    
    var descriptive: String
    var priorityId: String
    
    var anomalieStatus: AnomalieStatus
    
    var mailUser: String
    
    var reporterGuid: String
    var congratulations: Int
    var alias: String
    var confirms: Int
    var followers: Int
    var invalidations: Int
    var date: String
    var hour: String
    var source: AnomalieSource
    var resolvedAuthorization: Bool
    
    var isIncidentFollowedByUser: Bool = false
    
    var dateHour: Date {

        return DateUtils.date(fromDate: date, hour: hour)
    }
    
    var number: String
    
    //MARK: Initialization
    init(address: String, latitude: Double, longitude: Double, categorieId: String?, descriptive: String?, priorityId: String?, photo1: UIImage?, photo2: UIImage?, anomalieStatus: AnomalieStatus, mailUser: String?, number: String?) {
        // Initialize stored properties.
        self.id = ""
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.categorieId = categorieId ?? ""
        self.descriptive = descriptive ?? ""
        self.priorityId = priorityId ?? "3"
        
        self.photo1 = photo1
        self.photo2 = photo2
        self.photoCloseUrl = ""
        self.photoFarUrl = ""
        self.photoDoneUrl = ""
        
        self.anomalieStatus = anomalieStatus
        
        self.mailUser = mailUser ?? ""
        
        self.reporterGuid = ""
        self.congratulations = 0
        self.followers = 0
        self.confirms = 0
        self.invalidations = 0
        self.date = ""
        self.hour = ""
        self.source = .dmr
        self.alias = ""
        self.resolvedAuthorization = false
        self.number = number ?? ""

    }
    
    init(id: String?, address: String, latitude: Double, longitude: Double, categorieId: String?, descriptive: String?, priorityId: String?, anomalieStatus: AnomalieStatus, photoCloseUrl: String?, photoFarUrl: String?, photoDoneUrl: String?, number: String?) {
        // Initialize stored properties.
        self.id = id ?? ""
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.categorieId = categorieId ?? ""
        self.descriptive = descriptive ?? ""
        self.priorityId = priorityId ?? "3"
        
        self.photo1 = nil
        self.photo2 = nil
        self.photoCloseUrl = photoCloseUrl ?? ""
        self.photoFarUrl = photoFarUrl ?? ""
        self.photoDoneUrl = photoDoneUrl ?? ""
        
        self.anomalieStatus = anomalieStatus
        
        self.mailUser =  ""
        
        self.reporterGuid = ""
        self.congratulations = 0
        self.followers = 0
        self.confirms = 0
        self.invalidations = 0
        self.date = ""
        self.hour = ""
        self.source = .dmr
        self.alias = ""
        self.resolvedAuthorization = false
        self.number = number ?? ""
    }

 
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(address, forKey: "address")
        aCoder.encode(streetName, forKey: "streetName")
        aCoder.encode(postalCode, forKey: "postalCode")
        aCoder.encode(latitude, forKey: "latitude")
        aCoder.encode(longitude, forKey: "longitude")
        aCoder.encode(categorieId, forKey: "categorieId")
        aCoder.encode(descriptive, forKey: "descriptive")
        aCoder.encode(priorityId, forKey: "priorityId")
        aCoder.encode(date, forKey: "date")
        aCoder.encode(hour, forKey: "hour")
    }
    
    required init(coder decoder: NSCoder) {
        self.id = decoder.decodeObject(forKey: "id") as? String ?? ""
        self.address = decoder.decodeObject(forKey: "address") as? String ?? ""
        self.streetName = decoder.decodeObject(forKey: "streetName") as? String ?? ""
        self.postalCode = decoder.decodeObject(forKey: "postalCode") as? String ?? ""
        self.latitude = decoder.decodeDouble(forKey: "latitude") 
        self.longitude = decoder.decodeDouble(forKey: "longitude") 
        self.categorieId = decoder.decodeObject(forKey: "categorieId") as? String ?? ""
        self.descriptive = decoder.decodeObject(forKey: "descriptive") as? String ?? ""
        self.priorityId = decoder.decodeObject(forKey: "priorityId") as? String ?? ""
        self.date = decoder.decodeObject(forKey: "date") as? String ?? ""
        self.hour = decoder.decodeObject(forKey: "hour") as? String ?? ""
        self.photoCloseUrl = ""
        self.photoFarUrl = ""
        self.photoDoneUrl = ""
        self.anomalieStatus = .Brouillon
        self.mailUser = ""
        self.reporterGuid = ""
        self.congratulations = 0
        self.followers = 0
        self.confirms = 0
        self.invalidations = 0
        self.source = .dmr
        
        if let type =  ReferalManager.shared.getTypeAnomalie(withId: categorieId) {
            self.alias = type.alias
        } else {
            self.alias = "Type non précisé"
        }
        self.resolvedAuthorization = false
        self.number = ""
    }
    
    func archive() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }
    
   public func saveToDraft() {
        print("Enregistrement de l'anomalie")
        let date = Date()
        self.date = DateUtils.stringDate(from: date)
        self.hour = DateUtils.stringHour(from: date)
        
        var uuid : String
        if !(self.id.isEmpty) {
            uuid = (self.id)
            AnomalieBrouillon.shared.removeWithoutPhotos(anomalie: self)
        } else {
            uuid = UUID().uuidString
            self.id = uuid
        }
        
        // Enregistrement des images
        if let photo1 = self.photo1 {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let dataPath = documentsDirectory.appendingPathComponent(uuid)
            
            do {
                try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                print("Error creating directory: \(error.localizedDescription)")
            }
            
            // Enregistrement photo1
            let image1URL = documentsDirectory.appendingPathComponent("\(uuid)/\(Constants.Image.draftPhoto1)")
            let image1Data = photo1.jpegData(compressionQuality: Constants.Image.compressionQuality)
            try! image1Data?.write(to: image1URL)
            
            if let photo2 = self.photo2 {
                // Enregistrement photo2
                let image2URL = documentsDirectory.appendingPathComponent("\(uuid)/\(Constants.Image.draftPhoto2)")
                let image2Data = photo2.jpegData(compressionQuality: Constants.Image.compressionQuality)!
                try! image2Data.write(to: image2URL)
            }
        }
        
        
        AnomalieBrouillon.shared.append(anomalie: self)
    }
    
}

class AnomalieEquipement: Anomalie {
    var equipementId : String = ""
 
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(equipementId, forKey: "equipementId")
    }
    
    override init(address: String, latitude: Double, longitude: Double, categorieId: String?, descriptive: String?, priorityId: String?, photo1: UIImage?, photo2: UIImage?, anomalieStatus: AnomalieStatus, mailUser: String?, number: String?) {
        super.init(address: address, latitude: latitude, longitude: longitude, categorieId: categorieId, descriptive: descriptive, priorityId: priorityId, photo1: photo1, photo2: photo2, anomalieStatus: anomalieStatus, mailUser: mailUser, number: number)
    }
    
    override init(id: String?, address: String, latitude: Double, longitude: Double, categorieId: String?, descriptive: String?, priorityId: String?, anomalieStatus: AnomalieStatus, photoCloseUrl: String?, photoFarUrl: String?, photoDoneUrl: String?, number: String?) {
        super.init(id: id, address: address, latitude: latitude, longitude: longitude, categorieId: categorieId, descriptive: descriptive, priorityId: priorityId, anomalieStatus: anomalieStatus, photoCloseUrl: photoCloseUrl, photoFarUrl: photoFarUrl, photoDoneUrl: photoDoneUrl, number: number)
    }
    
    required init(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.equipementId = decoder.decodeObject(forKey: "equipementId") as? String ?? ""
        
        if let equipement = ReferalManager.shared.getEquipement(forId: equipementId) {
            if let typeEquipement = ReferalManager.shared.getTypeEquipement(forId: equipement.parentId) {
                if let type = ReferalManager.shared.getTypeAnomalie(forTypeEquipementId: typeEquipement.typeEquipementId, catagorieId: categorieId) {
                    self.alias = type.alias
                } else {
                    self.alias = "Type non précisé"
                }
            } else {
                self.alias = "Type non précisé"
            }
        } else {
            self.alias = "Type non précisé"
        }
        
    }
}

/// Enumeration définissant les différents status d'une anomalie
///
/// - Nouveau: Nouvelle anomalie (par défaut)
/// - Brouillon: Dès qu'une modification a été apporté, l'anomalie passe en brouillon
/// - APublier: Demande de publication de l'anomalie. Reste sur ce status en cas d'échec de l'enregistrement
/// - Ouvert: Status retourné par le service. Nouvelle anomalie créé
/// - Resolu: Status retourné par le service. Anomalie résolu
/// - ATraiter: Status retourné par le service. Anomalie en cours de traitement
public enum AnomalieStatus: String {
    case Nouveau = "N"
    case Brouillon = "B"
    case APublier = "A"
    
    case Ouvert = "O"
    case Resolu = "R"
    case ATraiter = "U"
}

/// Enumeration définissant les différentes sources des anomalies
///
/// - dmr: Anomalie provenant de l'application DansMaRue
/// - ramen: Anomalie provenant de l'application Ramen
public enum AnomalieSource: String {
    case dmr = "DansMaRue"
    case ramen = "Ramen"
}

// MARK: - AnomalieBrouillon
final class AnomalieBrouillon {
    
    private init() { }
    
    static let shared: AnomalieBrouillon = {
        let instance = AnomalieBrouillon()
        // setup code
        instance.anomalies = [String: Anomalie]()
        if let datas = UserDefaults.standard.object(forKey: Constants.Key.anomalieBrouillonList) as? [Data] {
            for data in datas {
                let anomalie = instance.unarchive(decoded: data)
                
                // Récupération des photos
                let docDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let image1URL = docDir.appendingPathComponent("\(anomalie.id)/\(Constants.Image.draftPhoto1)")
                if FileManager.default.fileExists(atPath: image1URL.path) {
                    anomalie.photo1 = UIImage(contentsOfFile: image1URL.path)!
                    
                    // Récupération de la photo2
                    let image2URL = docDir.appendingPathComponent("\(anomalie.id)/\(Constants.Image.draftPhoto2)")
                    if FileManager.default.fileExists(atPath: image2URL.path) {
                        
                        anomalie.photo2 = UIImage(contentsOfFile: image2URL.path)!
                    }
                }
                
                instance.anomalies[anomalie.id] = anomalie
            }
        }
        
        return instance
    }()
    
    // MARK: Local Variable
    var anomalies : [String: Anomalie] = [:]
    
    /// Méthode permettant d'ajouter une anomalie à la liste des brouillons et de la sauvegarder sur le device
    ///
    /// - Parameter anomalie: Instance de l'anomalie à enregistrer
    func append(anomalie: Anomalie) {
        anomalies[anomalie.id] = anomalie
        saveAnomalies()
    }
    
    /// Méthode permettant de supprimer une anomalie de la liste des brouillons et de la supprimer du device
    ///
    /// - Parameter anomalie: Instance de l'anomalie à supprimer
    func remove(anomalie: Anomalie) {
        //Suppression des photos
        let docDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let image1URL = docDir.appendingPathComponent("\(anomalie.id)/\(Constants.Image.draftPhoto1)")
        let image2URL = docDir.appendingPathComponent("\(anomalie.id)/\(Constants.Image.draftPhoto2)")
        if FileManager.default.fileExists(atPath: image1URL.path) {
            try! FileManager.default.removeItem(at: image1URL)
        }
        if FileManager.default.fileExists(atPath: image2URL.path) {
            try! FileManager.default.removeItem(at: image2URL)
        }
        
        anomalies.removeValue(forKey: anomalie.id)
        
        saveAnomalies()
    }
    
    /// Méthode permettant de supprimer une anomalie de la liste des brouillons et de la supprimer du device, sans supprimer les photos
    ///
    /// - Parameter anomalie: Instance de l'anomalie à supprimer
    func removeWithoutPhotos(anomalie: Anomalie) {
        anomalies.removeValue(forKey: anomalie.id)
        saveAnomalies()
    }
    
    //MARK : private Methods
    private func unarchive(decoded: Data) -> Anomalie {
        return NSKeyedUnarchiver.unarchiveObject(with: decoded) as! Anomalie
    }
    
    private func saveAnomalies() {
        var datas = [Data]()
        for anomalie in anomalies.values {
            datas.append(anomalie.archive())
        }
        UserDefaults.standard.set(datas, forKey: Constants.Key.anomalieBrouillonList)
    }
    
}

