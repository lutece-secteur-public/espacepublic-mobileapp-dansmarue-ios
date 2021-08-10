//
//  RestApiManager.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 29/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import Foundation
import SwiftyJSON
import GoogleMaps
import TTGSnackbar

typealias ServiceResponse = (JSON, NSError?) -> Void

class RestApiManager: NSObject {
    
    static let sharedInstance = RestApiManager()

    /// Méthode permettant de rechercher toutes les anomalies à proximiter des coordonnées spécifiées.
    ///
    /// - Parameters:
    ///   - coordinates: Coordonnées de l'utilisateur
    ///   - onCompletion: Flux JSON retourné par le service
    func getIncidentsByPosition(coordinates: CLLocationCoordinate2D, onCompletion: @escaping ([Anomalie]) -> Void) {
        let route = Constants.Services.apiBaseUrl + Constants.Services.apiUrl
        
        let guid = User.shared.uid ?? ""
        
        let bodyString = "jsonStream=[{\"position\":{\"latitude\":\(coordinates.latitude),\"longitude\":\(coordinates.longitude)},\"radius\":\"far\",\"request\":\"getIncidentsByPosition\",\"guid\":\"\(guid)\"}]"
        
        let headerList = [
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        
        makeHTTPPostRequest(isJson: false, path: route, body: bodyString, header: headerList, onCompletion: { json, err in
            
            if let jsonArray = json.array {
                for item in jsonArray {
                    if let jsonDict = item.dictionary {
                        if let answer = jsonDict["answer"]?.dictionary {
                            if let incident = answer["closest_incidents"]?.arrayValue {
                                print("Found \(incident.count) malfunctions")
                                
                               var anomalies = [Anomalie]()
                                
                                for marker in incident {
                                    // Create anomalie
                                    var photoCloseUrl = ""
                                    var photoFarUrl = ""
                                    if let pictures = marker["pictures"].dictionary {
                                        if let pictureClose = pictures["close"]?.arrayValue {
                                            if pictureClose.count > 0 {
                                                photoCloseUrl = pictureClose[0].stringValue
                                            } else if let pictureFar = pictures["far"]?.arrayValue {
                                                if pictureFar.count > 0 {
                                                    photoFarUrl = pictureFar[0].stringValue
                                                }
                                            }
                                        }
                                    }
                                    let state = marker["state"].stringValue
                                    let status = AnomalieStatus(rawValue: state) ?? .Ouvert
                                    let categorieId = marker["categoryId"].stringValue
                                    
                                    // On affiche dans la liste que les anos en cours
                                    
                                    let anomalie = Anomalie(id: marker["id"].stringValue, address: marker["address"].stringValue, latitude: Double(marker["lat"].floatValue), longitude: Double(marker["lng"].floatValue), categorieId: categorieId, descriptive: marker["descriptive"].stringValue, priorityId: marker["priorityId"].stringValue, anomalieStatus: status, photoCloseUrl: photoCloseUrl, photoFarUrl: photoFarUrl, photoDoneUrl: nil, number: marker["numero"].stringValue)
                                    
                                    anomalie.isIncidentFollowedByUser = marker["isIncidentFollowedByUser"].boolValue
                                    anomalie.alias = marker["alias"].stringValue
                                    
                                    anomalie.source = AnomalieSource(rawValue: marker["source"].stringValue) ?? .dmr
                                    
                             
                                    anomalies.append(anomalie)
                                    
                                    
                                }
                                
                                onCompletion(anomalies)
                            }
                        }
                    }
                }
            }
            
        })
        
    }
    
    /// Méthode permettant de rechercher une anomalies via son numéro.
    ///
    /// - Parameters:
    ///   - number: Numéro de l'anomalie
    ///   - onCompletion: Flux JSON retourné par le service
    func getIncidentsByNumber(number: String, onCompletion: @escaping ([String : JSON]) -> Void) {
        let route = Constants.Services.apiBaseUrl + "signalement/getAnomalieByNumber/" + number.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.makeHTTPGetRequest(path: route, header: ["":""] , onCompletion: {json, err in
            if let jsonDict = json.dictionary {
                onCompletion(jsonDict)
            } else {
                onCompletion(["erreurBO":"L’application est actuellement indisponible."])
            }
        })
    }
    
    /// Méthode permettant de rechercher toutes les anomalies Ramen à proximiter des coordonnées spécifiées.
    ///
    /// - Parameters:
    ///   - coordinates: Coordonnées de l'utilisateur
    ///   - onCompletion: Flux JSON retourné par le service
    func getDossierRamenByPosition(coordinates: CLLocationCoordinate2D, onCompletion: @escaping ([Anomalie]) -> Void) {
        let route = Constants.Services.apiBaseUrl + "signalement/getDossiersCourrantsByGeomWithLimit"
        
        let bodyString = "{\"latitude\":\(coordinates.latitude),\"longitude\":\(coordinates.longitude)}"
        
        let headerList = [
            "Content-Type": "application/json;"
        ]
        
        makeHTTPPostRequest(isJson: false, path: route, body: bodyString, header: headerList, onCompletion: { json, err in
            if let jsonArray = json.array {
                var anomalies = [Anomalie]()
                for item in jsonArray {
                    if let jsonDict = item.dictionary {
                        // Create anomalie
                        // On affiche dans la liste que les anos en cours
                        let anomalie = Anomalie(id: jsonDict["id"]?.stringValue, address: (jsonDict["adresse"]?.stringValue)!, latitude: Double((jsonDict["lat"]?.floatValue)!), longitude: Double((jsonDict["lng"]?.floatValue)!), categorieId: nil, descriptive: nil, priorityId: nil, anomalieStatus: AnomalieStatus.Ouvert, photoCloseUrl: nil, photoFarUrl: nil, photoDoneUrl: nil, number: "")
                        
                        anomalie.source = AnomalieSource(rawValue: "ramen") ?? .ramen
                        anomalie.alias = "Demande d'enlèvement des objets encombrants"
                        
                        anomalies.append(anomalie)
                    }
                    onCompletion(anomalies)
                }
            }
            
        })
        
    }
    
    
    /// Méthode permettant de récupérer le détail d'une anomalie
    ///
    /// - Parameter id Signalement: Id du signalement sélectionné
    /// - Parameter onCompletion: Flux JSON retourné par le service
    
    func getIncidentById(idSignalement: String, source: AnomalieSource, onCompletion: @escaping (Anomalie) -> Void) {
        let route = Constants.Services.apiBaseUrl + Constants.Services.apiUrl
        
        let guid = User.shared.uid ?? ""
        
        print("Show indicident id \(idSignalement)")
        
        let bodyString = "jsonStream=[{\"id\":\"\(idSignalement)\",\"request\":\"getIncidentById\",\"source\":\"\(source.rawValue)\", \"guid\":\"\(guid)\"}]"
        
        let headerList = [
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        
        makeHTTPPostRequest(isJson: false, path: route, body: bodyString, header: headerList, onCompletion: { json, err in
            
            if let jsonArray = json.array {
                for item in jsonArray {
                    if let jsonDict = item.dictionary {
                        if let answer = jsonDict["answer"]?.dictionary {
                            if let marker = answer["incident"]?.dictionary {
                                
                                // Creation d'une anomalie
                                var photoCloseUrl = ""
                                var photoFarUrl = ""
                                var photoDoneUrl = ""
                                if let pictures = marker["pictures"]?.dictionary {
                                    if let close = pictures["close"]?.arrayValue {
                                        if !close.isEmpty {
                                            photoCloseUrl = (close.first?.stringValue)!
                                            
                                        }
                                    }
                                    
                                    if let far = pictures["far"]?.arrayValue {
                                        if !far.isEmpty {
                                            photoFarUrl = (far.first?.stringValue)!
                                            
                                        }
                                    }
                                    
                                    if let done = pictures["done"]?.arrayValue {
                                        if !done.isEmpty {
                                            photoDoneUrl = (done.first?.stringValue)!
                                            
                                        }
                                    }
                                    
                                }
                                let state = marker["state"]?.stringValue ?? "O"
                                let status = AnomalieStatus(rawValue: state) ?? .Ouvert
                                // On affiche l'anomalie sélectionée dans la liste
                                let selectedAnomaly = Anomalie(id: marker["id"]?.stringValue, address: (marker["address"]?.stringValue)!, latitude: Double((marker["lat"]?.floatValue)!), longitude: Double((marker["lng"]?.floatValue)!), categorieId: marker["categoryId"]?.stringValue, descriptive: marker["descriptive"]?.stringValue, priorityId: marker["priorityId"]?.stringValue, anomalieStatus: status, photoCloseUrl: photoCloseUrl, photoFarUrl: photoFarUrl, photoDoneUrl: photoDoneUrl, number: marker["numero"]?.stringValue)
                                
                                let source = AnomalieSource(rawValue: (marker["source"]?.stringValue)!) ?? .dmr
                                selectedAnomaly.source = source
                                
                                if source == .ramen {
                                    selectedAnomaly.alias = "Demande de retrait des objets encombrants"
                                    
                                    if let encombrants = marker["encombrants"]?.arrayValue {
                                        
                                        for encombrant in encombrants {
                                            let quantity = encombrant["quantity"].intValue
                                            let name = encombrant["name"].stringValue
                                            
                                            selectedAnomaly.descriptive += "\u{2022} \(quantity) \(name) \n"
                                        }
                                    }
                                    
                                } else {
                                    
                                    selectedAnomaly.alias = marker["alias"]?.stringValue ?? ""
                                    
                                    selectedAnomaly.followers = marker["followers"]?.intValue ?? 0
                                    selectedAnomaly.reporterGuid = marker["reporterGuid"]?.stringValue ?? ""
                                    selectedAnomaly.congratulations = marker["congratulations"]?.intValue ?? 0
                                    
                                    selectedAnomaly.confirms = marker["confirms"]?.intValue ?? 0
                                    selectedAnomaly.date = (marker["date"]?.stringValue)!
                                    selectedAnomaly.hour = (marker["hour"]?.stringValue)!
                                    selectedAnomaly.invalidations = marker["invalidations"]?.intValue ?? 0
                                    
                                    selectedAnomaly.isIncidentFollowedByUser = marker["isIncidentFollowedByUser"]?.boolValue ?? false
                                }
                                
                                if let resolvedAuthorization = answer["resolved_authorization"]!.bool {
                                    selectedAnomaly.resolvedAuthorization = resolvedAuthorization
                                }
                                
                                onCompletion(selectedAnomaly)
                            
                                
                            }
                        }
                    }
                }
            }
        })
    }
    
    /// Méthode permettant de récupérer le détail d'une anomalie equipemnet
    ///
    /// - Parameter id Signalement: Id du signalement sélectionné
    /// - Parameter onCompletion: Flux JSON retourné par le service
    
    func getIncidentEquipementById(idSignalement: String, onCompletion: @escaping (AnomalieEquipement) -> Void) {
        let route = Constants.Services.apiBaseUrlEquipement
        
        let guid = User.shared.uid ?? ""
        
        let bodyString = "jsonStream=[{\"id\":\"\(idSignalement)\",\"request\":\"getIncidentById\", \"guid\":\"\(guid)\"}]"
        
        let headerList = [
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        
        makeHTTPPostRequest(isJson: false, path: route, body: bodyString, header: headerList, onCompletion: { json, err in
            
            if let jsonArray = json.array {
                for item in jsonArray {
                    if let jsonDict = item.dictionary {
                        if let answer = jsonDict["answer"]?.dictionary {
                            if let marker = answer["incident"]?.dictionary {
                                
                                // Creation d'une anomalie
                                var photoCloseUrl = ""
                                var photoFarUrl = ""
                                var photoDoneUrl = ""
                                if let pictures = marker["pictures"]?.dictionary {
                                    if let close = pictures["close"]?.arrayValue {
                                        if !close.isEmpty {
                                            photoCloseUrl = (close.first?.stringValue)!
                                            
                                        }
                                    }
                                    
                                    if let far = pictures["far"]?.arrayValue {
                                        if !far.isEmpty {
                                            photoFarUrl = (far.first?.stringValue)!
                                            
                                        }
                                    }
                                    
                                    if let done = pictures["done"]?.arrayValue {
                                        if !done.isEmpty {
                                            photoDoneUrl = (done.first?.stringValue)!
                                            
                                        }
                                    }
                                }
                                let state = marker["state"]?.stringValue ?? "O"
                                let status = AnomalieStatus(rawValue: state) ?? .Ouvert
                                // On affiche l'anomalie sélectionée dans la liste
                                let selectedAnomaly = AnomalieEquipement(id: marker["id"]?.stringValue, address: (marker["address"]?.stringValue)!, latitude: Double((marker["lat"]?.floatValue)!), longitude: Double((marker["lng"]?.floatValue)!), categorieId: marker["categoryId"]?.stringValue, descriptive: marker["descriptive"]?.stringValue, priorityId: marker["priorityId"]?.stringValue, anomalieStatus: status, photoCloseUrl: photoCloseUrl, photoFarUrl: photoFarUrl, photoDoneUrl: photoDoneUrl, number: "")
                                
                                selectedAnomaly.source = .dmr
                                
                                selectedAnomaly.alias = marker["alias"]?.stringValue ?? ""
                                
                                selectedAnomaly.followers = marker["followers"]?.intValue ?? 0
                                selectedAnomaly.reporterGuid = marker["reporterGuid"]?.stringValue ?? ""
                                selectedAnomaly.congratulations = marker["congratulations"]?.intValue ?? 0
                                
                                selectedAnomaly.confirms = marker["confirms"]?.intValue ?? 0
                                selectedAnomaly.date = (marker["date"]?.stringValue)!
                                selectedAnomaly.hour = (marker["hour"]?.stringValue)!
                                selectedAnomaly.invalidations = marker["invalidations"]?.intValue ?? 0
                                
                                selectedAnomaly.isIncidentFollowedByUser = marker["isIncidentFollowedByUser"]?.boolValue ?? false
                                
                                selectedAnomaly.equipementId = (marker["equipementId"]?.stringValue)!

                                if let resolvedAuthorization = answer["resolved_authorization"]!.bool {
                                    selectedAnomaly.resolvedAuthorization = resolvedAuthorization
                                }
                                
                                onCompletion(selectedAnomaly)
                                
                            }
                        }
                    }
                }
            }
        })
    }
    
    
    /// Méthode permettant de récupérer la liste des catégories d'anomalie.
    ///
    /// - Parameter onCompletion: Flux JSON retourné par le service
    func getCategories(onCompletion: @escaping (Bool) -> Void) {
        let route = Constants.Services.apiBaseUrl + Constants.Services.apiUrl
        let version = (ReferalManager.shared.fileExists(filename: ReferalManager.FileName.CATEGORIE)) ?UserDefaults.standard.double(forKey: Constants.Key.categorieVersion) : 0
        let currentAppVersion: String = Bundle.main.version
        
        let bodyNoJson = "jsonStream=[{\"request\":\"getCategories\",\"curVersion\":\"\(version)\",\"curVersionMobileProd\":\"\(currentAppVersion)\"}]"
        
        let headerList = [
            "Content-Type": "application/x-www-form-urlencoded",
            ]
        
        
        makeHTTPPostRequest(isJson: false, path: route, body: bodyNoJson, header: headerList, onCompletion: { json, err in
            
            print("Retrieve all categories")
            var result = false
            
            if let jsonArray = json.array {
                for item in jsonArray {
                    if let jsonDict = item.dictionary {
                        if let answer = jsonDict["answer"]?.dictionary {
                            if let version = answer["version"]?.doubleValue {
                                print("version categories anomalies ..... \(version)")
                                result = true
                                
                                // Chargement de la liste en cache
                                if let categories = answer["categories"]?.dictionary {
                                    ReferalManager.shared.saveToJsonFile(json: JSON(categories), intoFilename: ReferalManager.FileName.CATEGORIE)
                                    // Sauvegarde de la version
                                    UserDefaults.standard.set(version, forKey: Constants.Key.categorieVersion)                                    
                                }
                                
                            }
                            
                        }
                    }
                }
            }
            
            onCompletion(result)
        })
        
    }

    /// Méthode permettant d'enregistrer une anomalie.
    ///
    /// - Parameters:
    ///   - anomalie: instance de l'anomalie à enregistrer
    ///   - onCompletion: Identifiant de l'anomalie nouvellement créée
    func saveIncident(anomalie: Anomalie, onCompletion: @escaping (Bool) -> Void) {
        var route = Constants.Services.apiBaseUrl + Constants.Services.apiUrl
        
        let uuid = UIDevice.current.identifierForVendor?.uuidString ?? "-1"
        let guid = User.shared.uid ?? ""
        let userToken = UserDefaults.standard.string(forKey: Constants.Key.deviceToken) ?? "-1"
        
        var bodyNoJson = "jsonStream=[{\"request\":\"saveIncident\",\"email\":\"\(anomalie.mailUser)\",\"incident\":{\"categoryId\":\(anomalie.categorieId),\"address\":\"\(anomalie.address)\",\"descriptive\":\"\(anomalie.descriptive.toHttpBody())\",\"priorityId\":\(anomalie.priorityId), \"origin\": \"A\"}, \"position\":{\"latitude\":\(anomalie.latitude),\"longitude\":\(anomalie.longitude)}, \"udid\":\"\(uuid)\", \"guid\":\"\(guid)\", \"userToken\":\"\(userToken)\"}]"
        
        
        if let anoEquipement = anomalie as? AnomalieEquipement {
            route = Constants.Services.apiBaseUrlEquipement
            bodyNoJson = "jsonStream=[{\"request\":\"saveIncident\",\"email\":\"\(anoEquipement.mailUser)\",\"incident\":{\"categoryId\":\(anoEquipement.categorieId),\"equipementId\":\(anoEquipement.equipementId),\"address\":\"\(anoEquipement.address)\",\"descriptive\":\"\(anoEquipement.descriptive.toHttpBody())\",\"priorityId\":\(anoEquipement.priorityId), \"origin\": \"A\"}, \"position\":{\"latitude\":\(anoEquipement.latitude),\"longitude\":\(anoEquipement.longitude)}, \"udid\":\"\(uuid)\", \"guid\":\"\(guid)\", \"userToken\":\"\(userToken)\"}]"
        }
        
        
        print("saveIncident with params : \(bodyNoJson)")

        let headerList = [
            "Content-Type": "application/x-www-form-urlencoded",
        ]
        
        makeHTTPPostRequest(isJson: false, path: route, body: bodyNoJson, header: headerList, onCompletion: { json, err in
            
            if let jsonArray = json.array {
                for item in jsonArray {
                    if let jsonDict = item.dictionary {
                        if let answer = jsonDict["answer"]?.dictionary {
                            if let incidentId = answer["incidentId"]?.stringValue {
                                print("Creation de l'incident \(incidentId)")
                                // Suppression de l'anomalie dans la liste des brouillons
                                AnomalieBrouillon.shared.removeWithoutPhotos(anomalie: anomalie)
                                anomalie.anomalieStatus = AnomalieStatus.Ouvert
                                let idInit = anomalie.id
                                anomalie.id = incidentId
                                
                                // Upload photo 1 - close
                                if let photo = anomalie.photo1 {
                                    self.uploadPhoto(baseUrl: route, incidentId: anomalie.id, type: "close", photo: photo) { (result: Bool) in
                                        if result {
                                            print("Upload de la photo 1 effectué ...")
                                            //suppression photo 1
                                            let docDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                                            let image1URL = docDir.appendingPathComponent("\(idInit)/\(Constants.Image.draftPhoto1)")
                                            if FileManager.default.fileExists(atPath: image1URL.path) {
                                                try! FileManager.default.removeItem(at: image1URL)
                                            }
                                            
                                            // Upload photo 2 - far
                                            if let photo = anomalie.photo2 {
                                                self.uploadPhoto(baseUrl: route, incidentId: anomalie.id, type: "far", photo: photo) { (result: Bool) in
                                                    if result {
                                                        print("Upload de la photo 2 effectué ...")
                                                        //suppression photo 2
                                                        let docDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                                                        let image2URL = docDir.appendingPathComponent("\(idInit)/\(Constants.Image.draftPhoto2)")
                                                        if FileManager.default.fileExists(atPath: image2URL.path) {
                                                            try! FileManager.default.removeItem(at: image2URL)
                                                        }
                                                        self.appelWorkflow(baseUrl: route, incidentId: anomalie.id, onCompletion: { (result: Bool) in
                                                            print("Workflow lancé...")
                                                            onCompletion(result)
                                                        })
                                                    } else {
                                                        print("Erreur lors de l'upload de la photo 2")
                                                        onCompletion(false)
                                                    }
                                                }
                                            } else {
                                                self.appelWorkflow(baseUrl: route, incidentId: anomalie.id, onCompletion: { (result: Bool) in
                                                    print("Workflow lancé...")
                                                    onCompletion(result)
                                                    
                                                })
                                            }
                                        } else {
                                            print("Erreur lors de l'upload de la photo 1")
                                            onCompletion(false)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else if let jsonErr = json.dictionary {
                print("Erreur lors de la création de l'anomalie : \(String(describing: jsonErr["error_message"]?.stringValue))")
                anomalie.anomalieStatus = AnomalieStatus.APublier
                AnomalieBrouillon.shared.append(anomalie: anomalie)
                onCompletion(false)
            }
            
            
        })
        
    }
    
    func uploadPhoto(baseUrl: String, incidentId: String, type: String, photo: UIImage, onCompletion: @escaping (Bool) -> Void) {
        let route = "\(baseUrl)/photo/"
        let uuid = UIDevice.current.identifierForVendor?.uuidString ?? "-1"

        let data = photo.jpegData(compressionQuality: Constants.Image.compressionQuality)
        
        let headerList = [
            "Content-Type": "image/jpeg",
            "type": type,
            "incident_id": incidentId,
            "udid": uuid,
            "img_comment": "no_comment"
            ]
    
        makeHTTPPostRequest(isJson: false, path: route, body: data!, header: headerList, onCompletion: { json, err in
            
            var status = false
            
            if let jsonDict = json.dictionary {
                if let answer = jsonDict["answer"]?.dictionary {
                    if let statusValue = answer["status"]?.intValue {
                        print("uploadPhoto return ..... \(statusValue)")
                        
                        status = statusValue == 0 ? true : false
                    }
                }
            }
            
            onCompletion(status)
            
            
        })
        
    }
    
    /// Méthode permettant de lancer le workflow
    ///
    /// - Parameters:
    ///   - anomalie: instance de l'anomalie à enregistrer
    ///   - onCompletion: Le status de la réponse
    func appelWorkflow(baseUrl: String, incidentId: String, onCompletion: @escaping (Bool) -> Void) {
        let bodyNoJson = "jsonStream=[{\"request\":\"processWorkflow\",\"id\":\"\(incidentId)\"}]"
        
        let headerList = [
            "Content-Type": "application/x-www-form-urlencoded",
            ]

        makeHTTPPostRequest(isJson: false, path: baseUrl, body: bodyNoJson, header: headerList, onCompletion: { json, err in
            
            var status = false
            
            if let jsonArray = json.array {
                for item in jsonArray {
                    if let jsonDict = item.dictionary {
                        if let answer = jsonDict["answer"]?.dictionary {
                            if let statusValue = answer["status"]?.intValue {
                                print("appelWorkflow return ..... \(statusValue)")
                                
                                status = statusValue == 0 ? true : false
                            }
                        }
                    }
                }
            }
            
            onCompletion(status)
        })
        
    }
    
 
    /// Methode permettant de féliciter une anomalie.
    ///
    /// - Parameters:
    ///   - anomalie: Instance de l'anomalie à féliciter
    ///   - onCompletion: True si status = 0, false sinon
    func congratulateAnomalie(anomalie: Anomalie, onCompletion: @escaping (Bool) -> Void) {
        var route = Constants.Services.apiBaseUrl  + Constants.Services.apiUrl
        
        if anomalie as? AnomalieEquipement != nil {
            route = Constants.Services.apiBaseUrlEquipement
        }
        
        let bodyNoJson = "jsonStream=[{\"request\":\"congratulateAnomalie\",\"incidentId\":\"\(anomalie.id)\"}]"
        
        let headerList = [
            "Content-Type": "application/x-www-form-urlencoded",
            ]
        
        makeHTTPPostRequest(isJson: false, path: route, body: bodyNoJson, header: headerList, onCompletion: { json, err in
            
            var status = false
            
            if let jsonArray = json.array {
                for item in jsonArray {
                    if let jsonDict = item.dictionary {
                        if let answer = jsonDict["answer"]?.dictionary {
                            if let statusValue = answer["status"]?.intValue {
                                print("congratulateAnomalie return ..... \(statusValue)")
                                
                                status = statusValue == 0 ? true : false
                            }
                        }
                    }
                }
            }
            
            onCompletion(status)
        })
        
    }
    
    /// Méthode permettant de déclarer une anomalie comme résolu.
    /// Ce webservice n'est utilisable que si l'usager = déclarant de l'anomalie.
    ///
    /// - Parameters:
    ///   - anomalie: Instance de l'anomalie à déclarer comme service fait
    ///   - onCompletion: True si status = 0, false sinon
    func incidentResolved(anomalie: Anomalie, onCompletion: @escaping (Bool) -> Void) {
        var route = Constants.Services.apiBaseUrl + Constants.Services.apiUrl
        
        if anomalie as? AnomalieEquipement != nil {
            route = Constants.Services.apiBaseUrlEquipement
        }
        
        let guid = User.shared.uid ?? ""
        let udid = UIDevice.current.identifierForVendor?.uuidString ?? "-1"
        
        let bodyNoJson = "jsonStream=[{\"request\":\"incidentResolved\", \"incidentId\":\"\(anomalie.id)\", \"guid\":\"\(guid)\", \"udid\":\"\(udid)\"}]"
        
        let headerList = [
            "Content-Type": "application/x-www-form-urlencoded",
            ]
        
        makeHTTPPostRequest(isJson: false, path: route, body: bodyNoJson, header: headerList, onCompletion: { json, err in
            
            var status = false
            
            if let jsonArray = json.array {
                for item in jsonArray {
                    if let jsonDict = item.dictionary {
                        if let answer = jsonDict["answer"]?.dictionary {
                            if let statusValue = answer["status"]?.intValue {
                                print("incidentResolved return ..... \(statusValue)")
                                
                                status = statusValue == 0 ? true : false
                            }
                        }
                    }
                }
            }
            
            onCompletion(status)
        })
        
    }
    
    /// Methode permettant de suivre une anomalie.
    ///
    /// - Parameters:
    ///   - anomalie: Instance de l'anomalie à suivre
    ///   - onCompletion: True si status = 0, false sinon
    func follow(anomalie: Anomalie, onCompletion: @escaping (Bool) -> Void) {
        var route = Constants.Services.apiBaseUrl + Constants.Services.apiUrl
        
        if anomalie as? AnomalieEquipement != nil {
            // Anomalie Equipement, changement de l'url
            route = Constants.Services.apiBaseUrlEquipement
        }
        
        let guid = User.shared.uid ?? ""
        let udid = UIDevice.current.identifierForVendor?.uuidString ?? "-1"
        let email = User.shared.email!
        
        let userToken = UserDefaults.standard.string(forKey: Constants.Key.deviceToken) ?? "-1"
        
        let bodyNoJson = "jsonStream=[{\"request\":\"follow\", \"incidentId\":\"\(anomalie.id)\", \"guid\":\"\(guid)\", \"udid\":\"\(udid)\", \"email\":\"\(email)\", \"userToken\":\"\(userToken)\", \"device\":\"A\"}]"
        
        let headerList = [
            "Content-Type": "application/x-www-form-urlencoded",
            ]
        
        makeHTTPPostRequest(isJson: false, path: route, body: bodyNoJson, header: headerList, onCompletion: { json, err in
            
            var status = false
            
            if let jsonArray = json.array {
                for item in jsonArray {
                    if let jsonDict = item.dictionary {
                        if let answer = jsonDict["answer"]?.dictionary {
                            if let statusValue = answer["status"]?.intValue {
                                print("follow return ..... \(statusValue)")
                                
                                status = statusValue == 0 ? true : false
                                
                            }
                        }
                    }
                }
            }
            
            onCompletion(status)
        })
        
    }
    
    /// Methode permettant de ne plus suivre une anomalie.
    ///
    /// - Parameters:
    ///   - anomalie: Instance de l'anomalie à ne plus suivre
    ///   - onCompletion: True si status = 0, false sinon
    func unfollow(anomalie: Anomalie, onCompletion: @escaping (Bool) -> Void) {
        var route = Constants.Services.apiBaseUrl + Constants.Services.apiUrl
        
        if anomalie as? AnomalieEquipement != nil {
            // Anomalie Equipement, changement de l'url
            route = Constants.Services.apiBaseUrlEquipement
        }
        
        let guid = User.shared.uid ?? ""
        let udid = UIDevice.current.identifierForVendor?.uuidString ?? "-1"
        
        let bodyNoJson = "jsonStream=[{\"request\":\"unfollow\", \"incidentId\":\"\(anomalie.id)\", \"guid\":\"\(guid)\", \"udid\":\"\(udid)\"}]"
        
        let headerList = [
            "Content-Type": "application/x-www-form-urlencoded",
            ]
        
        makeHTTPPostRequest(isJson: false, path: route, body: bodyNoJson, header: headerList, onCompletion: { json, err in
            
            var status = false
            
            if let jsonArray = json.array {
                for item in jsonArray {
                    if let jsonDict = item.dictionary {
                        if let answer = jsonDict["answer"]?.dictionary {
                            if let statusValue = answer["status"]?.intValue {
                                print("unfollow return ..... \(statusValue)")
                                
                                status = statusValue == 0 ? true : false
                                
                            }
                        }
                    }
                }
            }
            
            onCompletion(status)
        })
        
    }
    
    
    /// Methode permettant de retourner la liste des anomalies suivies.
    ///
    /// - Parameters:
    ///   - guid: Identifiant du compte parisien
    ///   - onCompletion: Liste des anomalies suivies
    func getIncidentsByUser(guid: String, isIncidentSolved: Bool, onCompletion: @escaping ([Anomalie]) -> Void) {
        let route = Constants.Services.apiBaseUrl + Constants.Services.apiUrl
        
        // R retourne uniquement anomalies Résolus
        // O retourne anomalies ouvertes
        let paramFilterIncidentStatus = isIncidentSolved ? "R" : "O"
        
        let bodyNoJson = "jsonStream=[{\"request\":\"getIncidentsByUser\", \"guid\":\"\(guid)\", \"filterIncidentStatus\":\"\(paramFilterIncidentStatus)\"}]"
        
        let headerList = [
            "Content-Type": "application/x-www-form-urlencoded",
            ]
        
        makeHTTPPostRequest(isJson: false, path: route, body: bodyNoJson, header: headerList, onCompletion: { json, err in
            var anomalies = [Anomalie]()
            
            if let jsonArray = json.array {
                for item in jsonArray {
                    if let jsonDict = item.dictionary {
                        if let answer = jsonDict["answer"]?.dictionary {
                            if let incidents = answer["incidents"]?.arrayValue {
                                
                                for incident in incidents {
                                    // Create anomalie
                                    var photoCloseUrl = ""
                                    if let pictures = incident["pictures"].dictionary {
                                        if let close = pictures["close"]?.arrayValue {
                                            if !close.isEmpty {
                                                photoCloseUrl = (close.first?.stringValue)!
                                                
                                            }
                                        }
                                    }
                                    let state = incident["state"].stringValue
                                    let status = AnomalieStatus(rawValue: state) ?? .Ouvert
                                    let categorieId = incident["categoryId"].stringValue
                                    let number = incident["numero"].stringValue
                                    
                                    // On affiche dans la liste que les anos en cours
                                    
                                    let anomalie = Anomalie(id: incident["id"].stringValue, address: incident["address"].stringValue, latitude: Double(incident["lat"].floatValue), longitude: Double(incident["lng"].floatValue), categorieId: categorieId, descriptive: incident["descriptive"].stringValue, priorityId: incident["priorityId"].stringValue, anomalieStatus: status, photoCloseUrl: photoCloseUrl, photoFarUrl: nil, photoDoneUrl: nil, number: number)
                                    
                                    anomalie.alias = incident["alias"].stringValue
                                    anomalie.followers = incident["followers"].intValue
                                    anomalie.reporterGuid = incident["reporterGuid"].stringValue
                                    anomalie.congratulations = incident["congratulations"].intValue
                                    anomalie.confirms = incident["confirms"].intValue
                                    anomalie.date = incident["date"].stringValue
                                    anomalie.hour = incident["hour"].stringValue
                                    anomalie.invalidations = incident["invalidations"].intValue
                                    
                                    let source = AnomalieSource(rawValue: incident["source"].stringValue) ?? .dmr
                                    anomalie.source = source
                                    
                                    anomalies.append(anomalie)
                                }
                                
                            }
                        }
                    }
                }
            }
            onCompletion(anomalies)
        })
        
    }
    
    /// Methode permettant de retourner la liste des anomalies équipements suivies.
    ///
    /// - Parameters:
    ///   - guid: Identifiant du compte parisien
    ///   - onCompletion: Liste des anomalies suivies
    func getIncidentsEquipementByUser(guid: String, onCompletion: @escaping ([AnomalieEquipement]) -> Void) {
        let route = Constants.Services.apiBaseUrlEquipement
        
        let bodyNoJson = "jsonStream=[{\"request\":\"getIncidentsByUser\", \"guid\":\"\(guid)\"}]"
        
        let headerList = [
            "Content-Type": "application/x-www-form-urlencoded",
            ]
        
        makeHTTPPostRequest(isJson: false, path: route, body: bodyNoJson, header: headerList, onCompletion: { json, err in
            var anomalies = [AnomalieEquipement]()
            
            if let jsonArray = json.array {
                for item in jsonArray {
                    if let jsonDict = item.dictionary {
                        if let answer = jsonDict["answer"]?.dictionary {
                            if let incidents = answer["incidents"]?.arrayValue {
                                for incident in incidents {
                                    // Create anomalie
                                    var photoCloseUrl = ""
                                    if let pictures = incident["pictures"].dictionary {
                                        if let close = pictures["close"]?.arrayValue {
                                            if !close.isEmpty {
                                                photoCloseUrl = (close.first?.stringValue)!
                                                
                                            }
                                        }
                                    }
                                    let state = incident["state"].stringValue
                                    let status = AnomalieStatus(rawValue: state) ?? .Ouvert
                                    let categorieId = incident["categoryId"].stringValue
                                    
                                    // On affiche dans la liste que les anos en cours
                                    
                                    let anomalie = AnomalieEquipement(id: incident["id"].stringValue, address: incident["address"].stringValue, latitude: Double(incident["lat"].floatValue), longitude: Double(incident["lng"].floatValue), categorieId: categorieId, descriptive: incident["descriptive"].stringValue, priorityId: incident["priorityId"].stringValue, anomalieStatus: status, photoCloseUrl: photoCloseUrl, photoFarUrl: nil, photoDoneUrl: nil, number : "")
                                    
                                    anomalie.alias = incident["alias"].stringValue
                                    anomalie.followers = incident["followers"].intValue
                                    anomalie.reporterGuid = incident["reporterGuid"].stringValue
                                    anomalie.congratulations = incident["congratulations"].intValue
                                    anomalie.confirms = incident["confirms"].intValue
                                    anomalie.date = incident["date"].stringValue
                                    anomalie.hour = incident["hour"].stringValue
                                    anomalie.invalidations = incident["invalidations"].intValue
                                    anomalie.equipementId = incident["equipementId"].stringValue

                                    anomalie.source = .dmr
                                    
                                    anomalies.append(anomalie)
                                }
                                
                                
                            }
                        }
                    }
                }
            }
            onCompletion(anomalies)
        })
        
    }
    
    
    /// Méthode permettant de gérer l'authentification de l'utilisateur
    ///
    /// - Parameters:
    ///   - email: email de l'utilisateur
    ///   - password: mot de passe de l'utilisateur
    ///   - onCompletion: True si l'authentification est succès, false sinon
    func authenticate(email: String, password: String, onCompletion: @escaping (Bool) -> Void) {
        print("Authentification : Récupération du token")
        
        self.getAuthenticateToken(email: email, password: password) {
            (json:JSON) in
            
            
            if let jsonDict = json.dictionary {
                if let tokenId = jsonDict["tokenId"]?.stringValue {
                    User.shared.tokenId = tokenId
                    
                    self.validateAuthentification(email: email, tokenId: tokenId) {
                        (json: JSON) in
                        
                        if let jsonDict = json.dictionary {
                            
                            if let uidArray = jsonDict["uid"]?.array {
                                if let uid = uidArray.first {
                                    User.shared.uid = uid.stringValue
                                }
                            }
                            
                            var status = false
                            if let validatedAccount = jsonDict["validatedAccount"]?.array {
                                if let first = validatedAccount.first {
                                    status = first.boolValue
                                }
                            }
                            
                            if status {
                                User.shared.email = email
                                User.shared.isLogged = true
                                UserDefaults.standard.set(email, forKey: Constants.Key.email)
                                UserDefaults.standard.set(password, forKey: Constants.Key.password)
                                
                                
                                // Récupération des données du profil de l'utilisateur
                                self.getIdentityStore(guid: User.shared.uid!) {
                                    (result: Bool) in
                                    // nothing
                                }
                            }
                            onCompletion(status)
                            
                        }
                    }
                } else {
                    if let message = jsonDict["message"]?.stringValue {
                        print("Authentification message : \(message)")
                    }
                    onCompletion(false)
                }
            }
            
        }
        
    }

    
    /// Méthode permettant de récupérer le token pour gérer l'authentification
    ///
    /// - Parameters:
    ///   - email: email de l'utilisateur
    ///   - password: mot de passe de l'utilisateur
    ///   - onCompletion: JSON contenant les données du token
    private func getAuthenticateToken(email: String, password: String, onCompletion: @escaping (JSON) -> Void) {
        let route = "\(Constants.Services.authBaseUrl)/authenticate"
        
        let headerList = [
            "Content-Type": "application/json",
            "X-OpenAM-Username": email,
            "X-OpenAM-Password": password,
            ]
        
        makeHTTPPostRequest(isJson: false, path: route, body: "", header: headerList, onCompletion: {
            json, err in
            
            onCompletion(json as JSON)
        })
    }
    
    private func validateAuthentification(email: String, tokenId: String, onCompletion: @escaping (JSON) -> Void) {
        print("Authentification : Récupération de uid a partir du token \(tokenId)")
        
        let routeAuth = "\(Constants.Services.authBaseUrl)/users/\(email)?_fields=uid,firstname,mail,inetUserStatus,validatedAccount,lastname,name"
    
        
        let headerListAuth = [
            "mcpAuth": User.shared.tokenId
        ]
        
        self.makeHTTPGetRequest(path: routeAuth, header: headerListAuth as! [String : String], onCompletion: {
            json, err in
          
            onCompletion(json as JSON)
        })
    }
    
    /// Methode permettant de retourner les informations du profil de l'utilisateur
    ///
    /// - Parameters:
    ///   - guid: identifiant de l'utilisateur
    ///   - onCompletion: True si status = 0, false sinon
    func getIdentityStore(guid: String, onCompletion: @escaping (Bool) -> Void) {
        
        print("Authentification : Récupération du profil de l'utilisateur \(guid)")
        
        let route = Constants.Services.apiBaseUrl + "signalement/identitystore"
        
        let bodyNoJson = "jsonStream={\"guid\":\"\(guid)\"}"
        
        let headerList = [
            "Content-Type": "application/x-www-form-urlencoded"
            ]

        makeHTTPPostRequest(isJson: false, path: route, body: bodyNoJson, header: headerList, onCompletion: {
            json, err in
            
            var status = false
            
            if let jsonDict = json.dictionary {
                if let answer = jsonDict["answer"]?.dictionary {
                    if let statusValue = answer["status"]?.intValue {
                        print("identitystore return ..... \(statusValue)")
                        
                        status = statusValue == 0 ? true : false
                        
                    }
                    if let user = answer["user"]?.dictionary {
                        User.shared.lastName = user["name"]?.stringValue
                        User.shared.firstName = user["firstname"]?.stringValue
                        User.shared.email = user["mail"]?.stringValue
                        User.shared.isAgent = user["isAgent"]?.boolValue
                    }
                }
            }
            
            
            onCompletion(status)
        })
    }
    
    /// Methode permettant de retourner les informations du profil de l'utilisateur
    ///
    /// - Parameters:
    ///   - onCompletion: True si status = 0, false sinon
    func checkVersion( onCompletion: @escaping (String) -> Void) {
        let route = Constants.Services.apiBaseUrl + Constants.Services.apiUrl
        let bodyNoJson = "jsonStream=[{\"request\":\"checkVersion\"}]"
        let headerList = [
            "Content-Type": "application/x-www-form-urlencoded",
            ]
        
        makeHTTPPostRequest(isJson: false, path: route, body: bodyNoJson, header: headerList, onCompletion: { json, err in
            
            print("Récupération de la dernière version obligatoire")
            var lastVersionObligatoire = ""
            
            if let jsonArray = json.array {
                for item in jsonArray {
                    if let jsonDict = item.dictionary {
                        if let answer = jsonDict["answer"]?.dictionary {
                            if let resultLastVersionObligatoire = answer["iosDerniereVersionObligatoire"]?.stringValue {
                                print("lastVersionObligatoire ..... \(resultLastVersionObligatoire)")
                                lastVersionObligatoire = resultLastVersionObligatoire
                            }
                        }
                    }
                }
            }            
            onCompletion(lastVersionObligatoire)
        })
    }
    
    /// Methode permettant de récuperer le message provenant du BO
    ///
    /// - Parameters:
    ///   - onCompletion: True si status = 0, false sinon
    func getOpeningMessage( onCompletion: @escaping (String) -> Void ) {
        print("Appel du BO pour récupération du message d'ouverture")
            
        let route = Constants.Services.apiBaseUrl + "signalement/isDmrOnline"
        var messageBO = ""
            
        self.makeHTTPGetRequest(path: route, header: ["":""] , onCompletion: {json, err in
            if let jsonDict = json.dictionary {
                if let message_information = jsonDict["message_information"]?.stringValue {
                    messageBO = message_information
                }
            }
            onCompletion(messageBO)
        })
    }
    
    /// Methode permettant de recuperer la liste des Types equipements et Equipement
    ///
    /// - Parameter onCompletion: Bool - true si recuperation ok, false sinon
    func getEquipements(onCompletion: @escaping (Bool) -> Void) {
        let route = Constants.Services.apiBaseUrlEquipement
        let version = (ReferalManager.shared.fileExists(filename: ReferalManager.FileName.EQUIPEMENT)) ? UserDefaults.standard.double(forKey: Constants.Key.equipementVersion) : 0

        let bodyNoJson = "jsonStream=[{\"request\":\"getEquipements\",\"curVersion\":\"\(version)\"}]"
        
        let headerList = [ "Content-Type": "application/x-www-form-urlencoded" ]
        
        makeHTTPPostRequest(isJson: false, path: route, body: bodyNoJson, header: headerList, onCompletion: {
            json, err in
            
            print("Retrieve all types equipements / equipements")
            var result = false
            
            if let jsonArray = json.array {
                for item in jsonArray {
                    if let jsonDict = item.dictionary {
                        if let answer = jsonDict["answer"]?.dictionary {
                            if let version = answer["version"]?.doubleValue {
                                print("version equipements ..... \(version)")
                                result = true
                                
                                // Chargement de la liste en cache
                                if let items = answer["equipements"]?.dictionary {
                                    
                                    ReferalManager.shared.saveToJsonFile(json: JSON(items), intoFilename: ReferalManager.FileName.EQUIPEMENT)
                                    
                                    // Sauvegarde de la version
                                    UserDefaults.standard.set(version, forKey: Constants.Key.equipementVersion)

                                    
                                    /*
                                    var typeEquipements = [Data]()
                                    var equipements = [Data]()

                                    for item in items {
                                        if (item.key == "0") {
                                            var childrens = [String]()
                                            for children in (item.value[TypeEquipement.PropertyKey.childrensId].arrayValue) {
                                                childrens.append(children.stringValue)
                                            }
                                            
                                            if let name = item.value["name"].string {
                                                TypeContributionEquipement.shared.name = name
                                            }
                                            if let icon = item.value["icon"].string {
                                                TypeContributionEquipement.shared.icon = icon.base64ToImage()?.resizeWithWidth(width: 36)
                                            }
                                            
                                            UserDefaults.standard.set(childrens, forKey: Constants.Key.equipementList)
                                        } else {
                                            let value = item.value
                                            
                                            let parentId = value[TypeEquipement.PropertyKey.parentId].stringValue
                                            
                                            if parentId == "0" {
                                                let type = TypeEquipement()
                                                type.typeEquipementId = item.key
                                                type.name = value[TypeEquipement.PropertyKey.name].stringValue
                                                type.msgAlertNoEquipement = value[TypeEquipement.PropertyKey.msgAlertNoEquipement].stringValue
                                                type.msgPhoto = value[TypeEquipement.PropertyKey.msgPhoto].stringValue
                                                type.placeholder = value[TypeEquipement.PropertyKey.placeholder].stringValue
                                                type.parentId = parentId
                                                type.iconBase64  = value[TypeEquipement.PropertyKey.icon].stringValue
                                                type.icon = type.iconBase64.base64ToImage()
                                                
                                                var childrens = [String]()
                                                for children in (value[TypeEquipement.PropertyKey.childrensId].arrayValue) {
                                                    childrens.append(children.stringValue)
                                                }
                                                
                                                typeEquipements.append(type.archive())
                                            } else {
                                                let equipement = Equipement()
                                                equipement.equipementId = item.key
                                                equipement.name = value[Equipement.PropertyKey.name].stringValue
                                                equipement.adresse = value[Equipement.PropertyKey.adresse].stringValue
                                                equipement.longitude = value[Equipement.PropertyKey.longitude].doubleValue
                                                equipement.latitude = value[Equipement.PropertyKey.latitude].doubleValue
                                                equipement.parentId = parentId
                                                
                                                equipements.append(equipement.archive())
                                            }
                                            
                                        }
                                    }
                                    
                                    // Sauvegarde de la version
                                    UserDefaults.standard.set(version, forKey: Constants.Key.equipementVersion)
                                    UserDefaults.standard.set(typeEquipements, forKey: Constants.Key.typeEquipementItems)
                                    UserDefaults.standard.set(equipements, forKey: Constants.Key.equipementItems)
 
                                    */
                                }
                                
                            }
                            
                        }
                    }
                }
            }
            
            onCompletion(result)
        })
    }
    
    /// Méthode permettant de récupérer la liste des catégories d'anomalie par equipement.
    ///
    /// - Parameter onCompletion: Flux JSON retourné par le service
    func getCategoriesEquipements(onCompletion: @escaping (Bool) -> Void) {
        let route = Constants.Services.apiBaseUrlEquipement
        let version = (ReferalManager.shared.fileExists(filename: ReferalManager.FileName.CATEGORIE_EQUIPEMENT)) ?UserDefaults.standard.double(forKey: Constants.Key.categorieEquipementVersion) : 0
    
        let bodyNoJson = "jsonStream=[{\"request\":\"getCategories\",\"curVersion\":\"\(version)\"}]"
        
        let headerList = [ "Content-Type": "application/x-www-form-urlencoded" ]
        
        makeHTTPPostRequest(isJson: false, path: route, body: bodyNoJson, header: headerList, onCompletion: {
            json, err in
            
            print("Retrieve all categories equipements")
            var result = false
            
            if let jsonArray = json.array {
                for item in jsonArray {
                    if let jsonDict = item.dictionary {
                        if let answer = jsonDict["answer"]?.dictionary {
                            if let version = answer["version"]?.doubleValue {
                                print("version categories anomalies par equipements ..... \(version)")
                                result = true
                                
                                // Chargement de la liste en cache
                                if let types = answer["categories"]?.dictionary {
                                    
                                    ReferalManager.shared.saveToJsonFile(json: JSON(types), intoFilename: ReferalManager.FileName.CATEGORIE_EQUIPEMENT)
                                    
                                    // Sauvegarde de la version
                                    UserDefaults.standard.set(version, forKey: Constants.Key.categorieEquipementVersion)

                                }
                                
                            }
                            
                        }
                    }
                }
            }
            
            onCompletion(result)
        })
        
    }
    
    
    
    /// Méthode permettant de rechercher tous les équipements municipaux à proximiter des coordonnées spécifiées.
    ///
    /// - Parameters:
    ///   - coordinates: Coordonnées de l'utilisateur
    ///   - onCompletion: Flux JSON retourné par le service
    func getEquipementByPosition(coordinates: CLLocationCoordinate2D, onCompletion: @escaping ([Equipement]) -> Void) {
        let route = Constants.Services.apiBaseUrlEquipement
        if let typeEquipement = ContextManager.shared.typeEquipementSelected {
            
            let bodyString = "jsonStream=[{\"position\":{\"latitude\":\(coordinates.latitude),\"longitude\":\(coordinates.longitude)},\"request\":\"getEquipementsByPosition\",\"typeEquipementId\":\"\(typeEquipement.typeEquipementId)\"}]"
            
            let headerList = [ "Content-Type": "application/x-www-form-urlencoded" ]
            
            makeHTTPPostRequest(isJson: false, path: route, body: bodyString, header: headerList, onCompletion: {
                json, err in
                
                if let jsonArray = json.array {
                    for item in jsonArray {
                        if let jsonDict = item.dictionary {
                            if let answer = jsonDict["answer"]?.dictionary {
                                if let dictEquipements = answer["equipements"]?.dictionary {
                                    
                                    var equipements = [Equipement]()
                                    
                                    for itemEquipement in dictEquipements {
                                        if let equipement = ReferalManager.shared.getEquipement(forId: itemEquipement.key) {
                                            
                                            equipements.append(equipement)
                                        }
                                    }
                                    onCompletion(equipements)
                                }
                            }
                        }
                    }
                }
                
            })
        }
        
    }
    
    
    /// Méthode permettant de rechercher toutes les anomalies pour un équipement municipal à proximiter des coordonnées spécifiées.
    ///
    /// - Parameters:
    ///   - equipementId: Identifiant de l'équipement
    ///   - onCompletion: Flux JSON retourné par le service
    func getIncidentsByEquipement(equipementId: String, onCompletion: @escaping (Equipement) -> Void) {
        let route = Constants.Services.apiBaseUrlEquipement
        
        let bodyString = "jsonStream=[{\"request\":\"getIncidentsByEquipement\",\"equipementId\":\"\(equipementId)\"}]"
        
        let headerList = [ "Content-Type": "application/x-www-form-urlencoded" ]
        
        makeHTTPPostRequest(isJson: false, path: route, body: bodyString, header: headerList, onCompletion: {
            json, err in
            
            if let jsonArray = json.array {
                for item in jsonArray {
                    if let jsonDict = item.dictionary {
                        if let answer = jsonDict["answer"]?.dictionary {
                            
                            if let equipement = ReferalManager.shared.getEquipement(forId: equipementId) {
                                var anomalies = [AnomalieEquipement]()
                                
                                for incident in (answer["closest_incidents"]?.arrayValue)! {
                                    // Create anomalie
                                    var photoCloseUrl = ""
                                    var photoFarUrl = ""
                                    var photoDoneUrl = ""
                                    if let pictures = incident["pictures"].dictionary {
                                        if let close = pictures["close"]?.arrayValue {
                                            if !close.isEmpty {
                                                photoCloseUrl = (close.first?.stringValue)!
                                            }
                                        }
                                        
                                        if let far = pictures["far"]?.arrayValue {
                                            if !far.isEmpty {
                                                photoFarUrl = (far.first?.stringValue)!
                                            }
                                        }
                                        
                                        if let done = pictures["done"]?.arrayValue {
                                            if !done.isEmpty {
                                                photoDoneUrl = (done.first?.stringValue)!
                                                
                                            }
                                        }

                                    }
                                    let state = incident["state"].stringValue
                                    let status = AnomalieStatus(rawValue: state) ?? .Ouvert
                                    let categorieId = incident["categoryId"].stringValue
                                    
                                    // On affiche dans la liste que les anos en cours
                                    let anomalie = AnomalieEquipement(id: incident["id"].stringValue, address: equipement.adresse, latitude: equipement.latitude, longitude: equipement.longitude, categorieId: categorieId, descriptive: incident["descriptive"].stringValue, priorityId: incident["priorityId"].stringValue, anomalieStatus: status, photoCloseUrl: photoCloseUrl, photoFarUrl: photoFarUrl, photoDoneUrl: photoDoneUrl, number: "")
                                    
                                    anomalie.isIncidentFollowedByUser = incident["isIncidentFollowedByUser"].boolValue
                                    anomalie.alias = incident["alias"].stringValue
                                    
                                    anomalie.source = AnomalieSource(rawValue: incident["source"].stringValue) ?? .dmr
                                    
                                    anomalie.equipementId = equipement.equipementId
                                    
                                    anomalies.append(anomalie)
                                    
                                }
                                equipement.anomalies = anomalies
                                
                                onCompletion(equipement)
                            }
                        }
                    }
                }
            }
            
        })
        
        
    }
    
    
    /// Méthode permettant de tester si le BO est accessible
    func isDMROnline(onCompletion: @escaping (Bool) -> Void) {
        let route = Constants.Services.apiBaseUrl + "signalement/isDmrOnline"
        
        self.makeHTTPGetRequest(path: route, header: ["":""], onCompletion: {
            json, err in
            var isOnline = false
            if let jsonDict = json.dictionary {
                isOnline = ((jsonDict["online"]) != nil)
            }
            onCompletion(isOnline as Bool)
        })
    }
    
    
    // MARK: Perform a HEAD Request
    private func makeHTTPHeadRequest(path: String, header: [String: String], onCompletion: @escaping (_ result: Int)->()){
        let request = NSMutableURLRequest(url: NSURL(string: path)! as URL)
        for header in header {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        request.httpMethod = "HEAD"
        let session = URLSession.shared
        if Reach().connectionStatus() {
            let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
                let response = response as! HTTPURLResponse
                onCompletion(response.statusCode)
            })
            task.resume()
        } else {
            onCompletion(500)
        }
    }
    
    // MARK: Perform a GET Request
    private func makeHTTPGetRequest(path: String, header: [String: String], onCompletion: @escaping ServiceResponse) {
        let request = NSMutableURLRequest(url: NSURL(string: path)! as URL)
        for header in header {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        if Reach().connectionStatus() {
            let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
                if let jsonData = data {
                    let json:JSON = JSON(jsonData)
                    onCompletion(json, error as NSError?)
                } else {
                    onCompletion(JSON.null, error as NSError?)
                }
            })
            task.resume()
        } else {
            onCompletion(JSON.null, nil)
        }
    }
    
    // MARK: Perform a POST Request
    private func makeHTTPPostRequest(isJson: Bool, path: String, body: Any, header: [String: String], onCompletion: @escaping ServiceResponse) {
        var request = URLRequest(url: NSURL(string: path)! as URL)
        for header in header {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        // Set the method to POST
        request.httpMethod = "POST"
        
        do {
            // Set the POST body for the request
            if isJson {
                let jsonBody = try JSONSerialization.data(withJSONObject: body as! [String: Any])
                request.httpBody = jsonBody
            } else {
                if body is String {
                    request.httpBody = (body as! String).data(using: String.Encoding.utf8)
                } else {
                    request.httpBody = body as? Data
                }
                
            }
            
            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
            if Reach().connectionStatus() {
                    let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
                    if let jsonData = data {
                        let json:JSON = JSON(jsonData)
                        onCompletion(json, nil)
                    } else {
                        onCompletion(JSON.null, error as NSError?)
                    }
                })
                task.resume()
                
            } else {
                onCompletion(JSON.null, nil)
                
                DispatchQueue.main.async {
                    let snackbar = TTGSnackbar.init(message: "Vous n'avez aucune connexion", duration: .middle)
                    snackbar.messageTextFont = UIFont(name: "Montserrat", size: 15.0)!
                    snackbar.messageTextAlign = NSTextAlignment.center
                    snackbar.show()
                }
            }
        } catch {
            // Create your personal error
            onCompletion(JSON.null, nil)
        }
    }
    
    // MARK: Perform a PUT Request
    private func makeHTTPPutRequest(isJson: Bool, path: String, body: Any, header: [String: String], onCompletion: @escaping ServiceResponse) {
        let request = NSMutableURLRequest(url: NSURL(string: path)! as URL)
        for header in header {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        // Set the method to POST
        request.httpMethod = "PUT"
        
        do {
            // Set the POST body for the request
            if isJson {
                let jsonBody = try JSONSerialization.data(withJSONObject: body as! [String: Any])
                request.httpBody = jsonBody
            } else {
                request.httpBody = (body as! String).data(using: String.Encoding.utf8)
            }
            
            let session = URLSession.shared
            
            if Reach().connectionStatus() {
                let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
                    if let jsonData = data {
                        let json:JSON = JSON(jsonData)
                        onCompletion(json, nil)
                    } else {
                        onCompletion(JSON.null, error as NSError?)
                    }
                })
                task.resume()
            } else {
                onCompletion(JSON.null, nil)
            }
            
        } catch {
            // Create your personal error
            onCompletion(JSON.null, nil)
        }
    }
    // MARK: Perform a Delete Request
    private func makeHTTPDeleteRequest(path: String,header: [String: String], onCompletion: @escaping (_ result: Int)->()){
        let request = NSMutableURLRequest(url: NSURL(string: path)! as URL)
        for header in header {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        // Set the method to POST
        request.httpMethod = "DELETE"
        
        do {
            let session = URLSession.shared
            
            if Reach().connectionStatus() {
                let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
                    let response = response as! HTTPURLResponse
                    onCompletion(response.statusCode)
                })
                task.resume()
            } else {
                onCompletion(500)
            }
            
        }
    }
    
    //MARK: Perform local request
    private func makeLocalRequest(fileName: String, onCompletion: @escaping ServiceResponse) {
        
        if let path = Bundle.main.path(forResource: fileName, ofType: "json") {
            let data = try? String(contentsOfFile: path, encoding: String.Encoding.utf8)
            // let json = JSON(parseJSON: jsonString!)
            
            if let jsonData = data {
                let json:JSON = JSON(parseJSON: jsonData)
                onCompletion(json, nil)
            } else {
                onCompletion(JSON.null, nil)
            }
        } else {
            onCompletion(JSON.null, nil)
        }
    }
    
}

extension RestApiManager: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}

