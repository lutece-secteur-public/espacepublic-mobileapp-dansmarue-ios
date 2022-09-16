//
//  ReferalManager.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 02/02/2018.
//  Copyright © 2018 VilleDeParis. All rights reserved.
//

import SwiftyJSON

final class ReferalManager {
    
    static let shared = ReferalManager()
    
    struct FileName {
        static let CATEGORIE = "categories.json"
        static let CATEGORIE_EQUIPEMENT = "categories_equipement.json"
        static let EQUIPEMENT = "equipements.json"
        static let ACTUALITE = "actualites.json"
        static let AIDE = "aide.json"
    }
    
    var typeAnomalies = [String: TypeAnomalie]()
    var typeAnomaliesEquipement = [String: [String: TypeAnomalie]]()
    var typeEquipements = [String: TypeEquipement]()
    var equipements = [String: Equipement]()
    var equipementsByTypeEquipement = [String: [Equipement]]()
    var actualites = [Actualite]()
    var aides = [Aide]()

    /// Chargement de la liste des types de categorie d'anomalie pour l'espace public
    func loadTypeAnomalie() {
        let json = retrieveFromJsonFile(withName: FileName.CATEGORIE)
        
        for categorie in json.dictionaryValue {
            if (categorie.key == "0") {
                var childrens = [String]()
                for children in (categorie.value[TypeAnomalie.PropertyKey.childrensId].arrayValue) {
                    childrens.append(children.stringValue)
                }
                UserDefaults.standard.set(childrens, forKey: Constants.Key.categorieList)
            } else {
                let value = categorie.value
                
                let type = TypeAnomalie()
                type.categorieId = categorie.key
                type.name = value[TypeAnomalie.PropertyKey.name].stringValue
                type.alias = value[TypeAnomalie.PropertyKey.alias].string ?? type.name
                type.parentId = value[TypeAnomalie.PropertyKey.parentId].stringValue
                type.isAgent = value[TypeAnomalie.PropertyKey.isAgent].boolValue
                
                if value[TypeAnomalie.PropertyKey.horsDMR].boolValue {
                    type.messageBO = value[TypeAnomalie.PropertyKey.messageHorsDMR].stringValue
                }
                
                var childrens = [String]()
                for children in (value[TypeAnomalie.PropertyKey.childrensId].arrayValue) {
                    childrens.append(children.stringValue)
                }
                
                type.childrensId = childrens
                
                typeAnomalies[type.categorieId] = type
                
            }
        }
    }
    
    /// Recherche d'un type d'anomalie,
    func getAnomalieThatContainsText(type: String) -> [TypeAnomalie]? {
        var typeThatContainsText : [TypeAnomalie] = []
        let isAgent = User.shared.isAgent
        
        for typeAnomalie in typeAnomalies {
            if (typeAnomalie.value.name.uppercased().folding(options: .diacriticInsensitive, locale: .current).range(of: type.uppercased().folding(options: .diacriticInsensitive, locale: .current)) != nil) {
                if ( !typeAnomalie.value.isAgent || (typeAnomalie.value.isAgent && (isAgent != nil && isAgent!) ) )
                {
                    var fullName = typeAnomalie.value.name
                    var typeAnoTemp:TypeAnomalie = typeAnomalie.value.copy() as! TypeAnomalie
                   
                    //Récupération du nom complet des niveaux précédents
                    while !typeAnoTemp.isRootCategorie {
                        fullName = typeAnomalies[typeAnoTemp.parentId]!.name + " > " + fullName
                        typeAnoTemp = typeAnomalies[typeAnoTemp.parentId]!.copy() as! TypeAnomalie
                    }
                    
                    if ( !typeAnoTemp.isAgent || (typeAnoTemp.isAgent && (isAgent != nil && isAgent!) ) ) {
                        //Reset typeAnoTemp au niveau de la recherche
                        typeAnoTemp = typeAnomalie.value.copy() as! TypeAnomalie
                        typeAnoTemp.name = fullName
                        
                        if typeAnomalie.value.childrensId.count > 0 {
                            //Récupération des enfants
                            var typeAnoTempChild:TypeAnomalie
                            for typeAnomalieChildId in typeAnomalie.value.childrensId
                            {
                                if typeAnomalies[typeAnomalieChildId] != nil
                                {
                                    typeAnoTempChild = typeAnomalies[typeAnomalieChildId]!.copy() as! TypeAnomalie
                                    
                                    // Enfant niveau 2
                                    if typeAnoTempChild.childrensId.count > 0
                                    {
                                        for typeAnomalieChildLastLevelId in typeAnoTempChild.childrensId
                                        {
                                            if typeAnomalies[typeAnomalieChildLastLevelId] != nil
                                            {
                                                let typeAnomalieChildLastLevel:TypeAnomalie = typeAnomalies[typeAnomalieChildLastLevelId]!.copy() as! TypeAnomalie
                                                typeAnomalieChildLastLevel.name = typeAnoTemp.name + " > " +  typeAnoTempChild.name + " > " + typeAnomalieChildLastLevel.name
                                                if !typeThatContainsText.contains(typeAnomalieChildLastLevel) && !typeAnomalieChildLastLevel.isAgent || (typeAnomalieChildLastLevel.isAgent && (isAgent != nil && isAgent!) ) {                               typeThatContainsText.append(typeAnomalieChildLastLevel)
                                                }
                                            }
                                        }
                                    }
                                    // Enfant niveau 1
                                    else {
                                        typeAnoTempChild.name = typeAnoTemp.name + " > " + typeAnoTempChild.name
                                        if !typeThatContainsText.contains(typeAnoTempChild) && !typeAnoTempChild.isAgent || (typeAnoTempChild.isAgent && (isAgent != nil && isAgent!))  {
                                            typeThatContainsText.append(typeAnoTempChild)
                                        }
                                    }
                                }
                            }
                        }
                        else if !typeThatContainsText.contains(typeAnoTemp) {
                            typeThatContainsText.append(typeAnoTemp)
                        }
                    }
                }
            }
        }
        
        return typeThatContainsText
    }
    
    /// Chargement de la liste des types de categorie d'anomalie pour les equipements.
    func loadTypeAnomalieByEquipement() {
        let json = retrieveFromJsonFile(withName: FileName.CATEGORIE_EQUIPEMENT)
        
        for typeEquip in json.dictionaryValue {
            // Prise en compte de la liste des categories d'anomalie pour un type equipement
            if let typeEquipement = getTypeEquipement(forId: typeEquip.key) {
                
                // Iteration des Categories d'anomalies pour le Type Equipement
                var typeAnomalies = [String: TypeAnomalie]()
                for categorie in typeEquip.value.dictionaryValue {
                    let categKey = categorie.key
                    let value = categorie.value
                    
                    if categKey == "0" {
                        // Récupération de la liste des catégories parentes
                        var childrens = [String]()
                        for children in (value[TypeAnomalie.PropertyKey.childrensId].arrayValue) {
                            childrens.append(children.stringValue)
                        }
                        
                        typeEquipement.categoriesAnomaliesId = childrens
                    } else {
                        // Ajout des TypeAnomalie pour un TypeEquipement
                        let type = TypeAnomalie()
                        type.categorieId = categKey
                        type.name = value[TypeAnomalie.PropertyKey.name].stringValue
                        type.alias = value[TypeAnomalie.PropertyKey.alias].string ?? type.name
                        type.parentId = value[TypeAnomalie.PropertyKey.parentId].stringValue
                        
                        if let imageAno = value[TypeAnomalie.PropertyKey.image_mobile].stringValue.base64ToImage(){
                            type.imageFromWS = imageAno
                        }
                        
                        var childrens = [String]()
                        for children in (value[TypeAnomalie.PropertyKey.childrensId].arrayValue) {
                            childrens.append(children.stringValue)
                        }
                        
                        type.childrensId = childrens
                        
                        typeAnomalies[categKey] = (type)
                    }
                    
                }
                
                typeAnomaliesEquipement[typeEquip.key] = typeAnomalies
                
            }
        }
    }
    
    /// Retourne le TypeAnomalie par rapport a son identifiant.
    ///  - Parameter withId: identifiant du TypeAnomalie
    func getTypeAnomalie(withId: String) -> TypeAnomalie? {
        return typeAnomalies[withId]
    }
    
    /// Retourne le TypeAnomalie d'un équipement par rapport a son identifiant.
    ///  - Parameter forTypeEquipementId: identifiant du Type equipement
    ///  - Parameter catagorieId: identifiant du TypeAnomalie
    func getTypeAnomalie(forTypeEquipementId typeEquipementId: String, catagorieId: String) -> TypeAnomalie? {
        guard let typeAnoByEquipement = typeAnomaliesEquipement[typeEquipementId] else { return nil}
        
        return typeAnoByEquipement[catagorieId]
    }
    
    /// Retourne le TypeAnomalie parent de premier niveau
    ///  - Parameter fromCategorieId: identifiant du TypeAnomalie
    func getRootCategorieId(fromCategorieId: String) -> String {
        if let categ = getTypeAnomalie(withId: fromCategorieId) {
            if categ.parentId == "0" || categ.parentId.isEmpty {
                return categ.categorieId
            } else {
                return getRootCategorieId(fromCategorieId: categ.parentId)
            }
        }
        
        return fromCategorieId
    }
    
    
    
    /// Chargement de la liste des types equipement et equipements.
    func loadTypeEquipementAndEquipements() {
        let json = retrieveFromJsonFile(withName: FileName.EQUIPEMENT)
        
        var typeEquipementIds = [String]()
        if let typeEquipId = json.dictionaryValue["0"] {
            for children in (typeEquipId[TypeEquipement.PropertyKey.childrensId].arrayValue) {
                typeEquipementIds.append(children.stringValue)
            }
            
            if let name = typeEquipId[TypeEquipement.PropertyKey.name].string {
                TypeContributionEquipement.shared.name = name
            }
            if let icon = typeEquipId[TypeEquipement.PropertyKey.icon].string {
                TypeContributionEquipement.shared.icon = icon.base64ToImage()?.resizeWithWidth(width: 36)
            }
            
            UserDefaults.standard.set(typeEquipementIds, forKey: Constants.Key.typeEquipementList)
        }
        
        for typeEquipementId in typeEquipementIds {
            if let typeEquipValue = json.dictionaryValue[typeEquipementId] {
                let type = TypeEquipement()
                type.typeEquipementId = typeEquipementId
                type.name = typeEquipValue[TypeEquipement.PropertyKey.name].stringValue
                type.msgAlertNoEquipement = typeEquipValue[TypeEquipement.PropertyKey.msgAlertNoEquipement].stringValue
                type.msgPhoto = typeEquipValue[TypeEquipement.PropertyKey.msgPhoto].stringValue
                type.placeholder = typeEquipValue[TypeEquipement.PropertyKey.placeholder].stringValue
                type.iconBase64  = typeEquipValue[TypeEquipement.PropertyKey.icon].stringValue
                type.imageBase64  = typeEquipValue[TypeEquipement.PropertyKey.image].stringValue
                type.icon = type.iconBase64.base64ToImage()
                type.image = type.imageBase64.base64ToImage()

                var childrens = [String]()
                for children in (typeEquipValue[TypeEquipement.PropertyKey.childrensId].arrayValue) {
                    childrens.append(children.stringValue)
                }
                
                typeEquipements[typeEquipementId] = type
            }
        }
        
        for item in json.dictionaryValue {
            if (item.key != "0") {
                let value = item.value
                let parentId = value[TypeEquipement.PropertyKey.parentId].stringValue
                if parentId != "0" {
                    let equipement = Equipement()
                    equipement.equipementId = item.key
                    equipement.name = value[Equipement.PropertyKey.name].stringValue
                    equipement.adresse = value[Equipement.PropertyKey.adresse].stringValue
                    equipement.longitude = value[Equipement.PropertyKey.longitude].doubleValue
                    equipement.latitude = value[Equipement.PropertyKey.latitude].doubleValue
                    equipement.parentId = parentId
                    
                    equipements[item.key] = equipement
                    
                    var liste = equipementsByTypeEquipement[parentId] ?? []
                    liste.append(equipement)
                    equipementsByTypeEquipement[parentId] = liste
                    
                }
            }
        }
    }
    
    /// Retourne le TypeEquipement par rapport a son identifiant.
    ///  - Parameter forId: identifiant du TypeEquipement
    func getTypeEquipement(forId: String) -> TypeEquipement? {
        return typeEquipements[forId]
    }
    
    /// Retourne l'Equipement par rapport a son identifiant.
    ///  - Parameter forId: identifiant de l'Equipement
    func getEquipement(forId: String) -> Equipement? {
        return equipements[forId]
    }
    
    /// Retourne la liste des Equipement par rapport a un TypeEquipement.
    ///  - Parameter forTypeEquipementId: identifiant du TypeEquipement
    func getEquipements(forTypeEquipementId: String) -> [Equipement]? {
        return equipementsByTypeEquipement[forTypeEquipementId]
    }
    
    /// Chargement de la liste des actualites.
    func loadActualite() {
        let json = retrieveFromJsonFile(withName: FileName.ACTUALITE)
        
        for actualiteJson in json {
            let actualite = Actualite()
            let values = actualiteJson.1.dictionaryValue
            actualite.actualiteId = values[Actualite.PropertyKey.actualiteId]!.stringValue
            actualite.libelle = values[Actualite.PropertyKey.libelle]!.stringValue
            actualite.texte = values[Actualite.PropertyKey.texte]!.stringValue
            actualite.imageUrl = values[Actualite.PropertyKey.imageUrl]!.stringValue
            actualite.actif = values[Actualite.PropertyKey.actif]!.boolValue
            
            actualites.append(actualite)
        }
    }
    
    /// Retourne les actualites
    func getActualites() -> [Actualite]? {
        return actualites
    }
    
    /// Chargement de la liste des aides.
    func loadAides() {
        let json = retrieveFromJsonFile(withName: FileName.AIDE)
        
        for aideJson in json {
            let aide = Aide()
            let values = aideJson.1.dictionaryValue
            aide.libelle = values[Aide.PropertyKey.libelle]!.stringValue
            aide.hypertexteUrl = values[Aide.PropertyKey.hypertexteUrl]!.stringValue
            aide.imageUrl = values[Aide.PropertyKey.imageUrl]!.stringValue
            
            aides.append(aide)
        }
    }
    
    /// Retourne les aides
    func getAides() -> [Aide]? {
        return aides
    }

    
    /// Permet d'enregistrer un flux json dans un fichier.
    ///  - Parameter json: flux json
    ///  - Parameter intoFilename: nom du fichier
    func saveToJsonFile(json: JSON, intoFilename filename: String) {
        // Get the url of Persons.json in document directory
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileUrl = documentDirectoryUrl.appendingPathComponent(filename)
        
        
        // Transform array into data and save it into file
        do {
            let data = try json.rawData()
            try data.write(to: fileUrl, options: [])
        } catch {
            print(error)
        }
    }
    
    /// Permet de lire le contenu json d'un fichier.
    ///  - Parameter withName: nom du fichier
    func retrieveFromJsonFile(withName filename: String) -> JSON {
        // Get the url of Persons.json in document directory
        guard let documentsDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return JSON.null}
        let fileUrl = documentsDirectoryUrl.appendingPathComponent(filename)
        
        var jsonResult = JSON.null
        // Read data from .json file and transform data into an array
        do {
            let data = try Data(contentsOf: fileUrl, options: [])
            //guard let dataArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: [String: String]]] else { return JSON.null}
            
            jsonResult = JSON(data)
        } catch {
            print(error)
        }
        
        return jsonResult
    }
    
    /// Vérifie l'existence d'un fichier
    ///  - Parameter filename: nom du fichier
    func fileExists(filename: String) -> Bool {
        // Get the url of Persons.json in document directory
        guard let documentsDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return false}
        let fileUrl = documentsDirectoryUrl.appendingPathComponent(filename)
        
        return FileManager.default.fileExists(atPath: fileUrl.path)
    }
}
