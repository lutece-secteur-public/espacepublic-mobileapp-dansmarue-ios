    //
//  AddAnomalyViewController.swift
//  DansMaRue
//
//  Created by NTDC-Showroom on 22/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import SwiftyJSON


class AddAnomalyViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    // MARK: - Constantes
    struct RowId {
        static let map = 0
        static let typeAnomalie = 2
        static let photos = 3
        static let description = 6
        static let priorite = 7
        static let btnPublier = 8
    }
    
    //MARK: - Properties
    var adressModified = ""
    
    var currentAnomalie: Anomalie?
    var typeContribution: TypeContribution = .outdoor
    var selectedEquipement: Equipement?
    
    var choixComplementTexte: [String] = ["", "bis", "ter", "quarter"]
    var choixComplement: [String] = ["", "b", "t", "q"]
    var complement = ""
    var complementTexte = ""
    var numAdresse = ""
    
    var vSpinner : UIView?
    
    //MARK: - IBoutlets
    @IBOutlet var tableViewAddAnomaly: UITableView!
    
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableViewAddAnomaly.delegate = self
        tableViewAddAnomaly.dataSource = self
        
        if let location = MapsUtils.userLocation() {
            if currentAnomalie == nil {
                if self.typeContribution == .outdoor {
                    currentAnomalie = Anomalie(address: MapsUtils.fullAddress(), latitude: location.latitude, longitude: location.longitude, categorieId: nil, descriptive: nil, priorityId: Priority.genant.rawValue, photo1: nil, photo2: nil, anomalieStatus: .Nouveau, mailUser: "", number: "" )
                    if let myAddress = currentAnomalie?.address {
                        currentAnomalie?.streetName = MapsUtils.addressLabel
                        currentAnomalie?.postalCode = MapsUtils.getPostalCode(address: myAddress)
                    }
                } else if let equipement = ContextManager.shared.equipementSelected {
                    showAlertMessagePhoto(equipement: equipement)
                    self.selectedEquipement = equipement
                    
                    currentAnomalie = AnomalieEquipement(address: equipement.adresse, latitude: equipement.latitude, longitude: equipement.longitude, categorieId: nil, descriptive: nil, priorityId: Priority.genant.rawValue, photo1: nil, photo2: nil, anomalieStatus: .Nouveau, mailUser: "", number: "" )
                    
                    currentAnomalie?.postalCode = MapsUtils.getPostalCode(address: equipement.adresse)
                    
                    if let anoEquipement = currentAnomalie as? AnomalieEquipement {
                        anoEquipement.equipementId = equipement.equipementId
                    }
                }
            } else {
                // Vérifie si l'anomalie contient une adresse valide
                if self.typeContribution == .outdoor && (currentAnomalie?.postalCode.isEmpty)! {
                    // Essaye de convertir l'adresse à partir des coordonnees
                    if Reach().connectionStatus() {
                        let location = CLLocationCoordinate2D(latitude: CLLocationDegrees((currentAnomalie?.latitude)!), longitude: CLLocationDegrees((currentAnomalie?.longitude)!))
                        // Device en mode Connecté
                        let geocoder = GMSGeocoder()
                        geocoder.reverseGeocodeCoordinate(location) { (response: GMSReverseGeocodeResponse?, error: Error?) in
                            if let error = error {
                                print("Nothing found: \(error.localizedDescription)")
                                return
                            }
                            if let addressFound = response {
                                self.changeAddress(newAddress: addressFound.firstResult()!)

                            }
                        }
                    }
                }
            }
        }
        
    }
    
    //MARK: - IBActions
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        if currentAnomalie?.anomalieStatus == .Brouillon {
            // Message d'avertissement
            let alertController = UIAlertController(title: Constants.AlertBoxTitle.attention, message: Constants.AlertBoxMessage.attention, preferredStyle: .alert)
            // Create Non button
            let NonAction = UIAlertAction(title: Constants.AlertBoxTitle.non, style: .default) { (action:UIAlertAction!) in
                AnomalieBrouillon.shared.remove(anomalie: self.currentAnomalie!)
                self.close()
            }
            alertController.addAction(NonAction)
            // Create Oui button
            let OuiAction = UIAlertAction(title: Constants.AlertBoxTitle.oui, style: .default) { (action:UIAlertAction!) in
                self.currentAnomalie?.saveToDraft()
                self.close()
            }
            alertController.addAction(OuiAction)
            // Present Dialog message
            self.present(alertController, animated: true, completion:nil)
            
        } else {
            self.close()
        }
        
    }
    
    func close() {
        _ = self.navigationController?.popViewController(animated: true)
        UserDefaults.standard.removeObject(forKey: "descriptiveAno")
        UserDefaults.standard.removeObject(forKey: "counter")
    }
    
    @IBAction func editAddress(_ sender: UIButton_EditAddress) {
        
        let modifyAddress = UIStoryboard(name: Constants.StoryBoard.addAnomaly, bundle: nil).instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.modifyAddress) as! ModifyAddressViewController
        modifyAddress.delegate = self
        self.navigationController?.pushViewController(modifyAddress, animated: true)
        self.navigationController?.navigationBar.backgroundColor = UIColor.pinkDmr()

    }
    
    @IBAction func publier(_ sender: UIButton_PublierAnomalie) {
        
        //On vérifie que l'adresse est bien dans paris avant la publication
        if(!(currentAnomalie?.postalCode.hasPrefix(Constants.prefix75))!){
            
            //message alerte
            let alertController = UIAlertController(title: Constants.AlertBoxTitle.adresseInvalide, message: Constants.AlertBoxMessage.adresseInvalide, preferredStyle: .alert)
            // Create OK button
            let OKAction = UIAlertAction(title: Constants.AlertBoxTitle.ok, style: .default) { (action:UIAlertAction!) in
                
            }
            alertController.addAction(OKAction)
            // Present Dialog message
            self.present(alertController, animated: true, completion:nil)
        }
        else {
            //Vérification du n° obligatoire ou non de l'adresse
            //Récupération du 1er caractere de la rue pour vérifier si c'est un n°
            let trimmedAddress = self.currentAnomalie?.address.trimmingCharacters(in: .whitespaces)
            let first = trimmedAddress![trimmedAddress!.startIndex]
            let str = String(first)
            
            //Si l'adresse ne commence pas par un n°, affichage de la popup d'ajout de n°
            if Int(str) == nil && !(trimmedAddress?.lowercased().starts(with: "pont"))! {
                showAlertNumber()
            } else {
                //Sinon publication de l'ano
                publicationAnomalie()
            }
        }
    }
    
    //Affichage de la popup de numéro obligatoire
    func showAlertNumber() {
         //Affichage de la popup pour le n° de rue obligatoire
         //message alerte
         let alertController = UIAlertController(title: Constants.AlertBoxTitle.adresseInvalide, message: Constants.AlertBoxMessage.numRueObligatoire, preferredStyle: .alert)
         
        
         //Textfield pour la saisie du numéro
         alertController.addTextField { [weak self] (textField) in
            textField.keyboardType = .numberPad
            textField.text = self?.numAdresse
            textField.delegate = self
         }
         
        
        // Boutton complément d'adresse
        var titreAlertComplement = Constants.AlertBoxTitle.complementAdresseFacultatif
        if complement != "" {
            titreAlertComplement = Constants.AlertBoxTitle.complementAdresse + " : " + complementTexte
        }
        
         let ajoutComplementAction = UIAlertAction.init(title: titreAlertComplement, style: .default, handler: { (action: UIAlertAction!) in
             //Affichage alert selection complément
            let alert = UIAlertController(title: "Complément d'adresse", message: "\n\n\n\n\n\n\n\n\n", preferredStyle: UIAlertController.Style.alert);
            alert.isModalInPopover = true;
            let pickerFrame: CGRect = CGRect(x: 5, y: 70, width: 250, height: 140);
            let picker: UIPickerView = UIPickerView(frame: pickerFrame);
            picker.delegate = self;
            picker.dataSource = self;
            alert.view.addSubview(picker);
             
            let OKAction = UIAlertAction.init(title: Constants.AlertBoxTitle.ok, style: .default, handler: { (action: UIAlertAction!) in
               print("ok")
               self.showAlertNumber()
            })
            alert.addAction(OKAction)
             
            self.present(alert, animated: true, completion: nil);
         })
         alertController.addAction(ajoutComplementAction)
         
        
         // Boutton publier
         let OKAction = UIAlertAction.init(title: Constants.AlertBoxTitle.publier, style: .default, handler: { (action: UIAlertAction!) in
             let textField = alertController.textFields![0] as UITextField
             
            //On ajoute le numéro si il est inférieur à 4 chiffres
            if textField.text != "" && textField.text!.count < 4 && textField.text != "000" {
                if self.complement != "" {
                    //Si un complément d'adresse est renseigné
                    self.currentAnomalie?.address = textField.text! + self.complement + " " + (self.currentAnomalie?.address)!
                } else {
                    self.currentAnomalie?.address = textField.text! + " " + (self.currentAnomalie?.address)!
                }
                
                //Affichage du spinner de chargement
                self.showSpinner(onView: self.view)
                
                //MAJ des coordonnées via la nouvelle adresse
                MapsUtils.getCoordinateFromAddress(adresse: textField.text! + self.currentAnomalie!.streetName + " " + self.currentAnomalie!.postalCode) { (coordinate: CLLocationCoordinate2D) in
                    self.currentAnomalie?.latitude = coordinate.latitude
                    self.currentAnomalie?.longitude = coordinate.longitude
                    
                    //Utilisation des nouvelles coordonnées pour récupérer le code postal (DMR-1785)
                    //Suite à l'ajout d'un n°, si une adresse est à cheval sur 2 arrondissements, le nouveau numéro necessite une vérification du CP
                    MapsUtils.getAddressFromCoordinate(lat: self.currentAnomalie!.latitude, long: self.currentAnomalie!.longitude) {
                        (address: GMSAddress) in
                        //MAJ du CP dans l'adresse
                        self.currentAnomalie?.address = (self.currentAnomalie?.address.replacingOccurrences(of: self.currentAnomalie!.postalCode, with: address.postalCode!))!
                        //MAJ du CP
                        self.currentAnomalie?.postalCode = address.postalCode ?? ""
                        
                        //Fin du chargement
                        self.removeSpinner()
                        
                        self.publicationAnomalie()
                    }
                }
             } else {
                //Fin du chargement
                self.removeSpinner()
                self.present(alertController, animated: true, completion:nil)
             }
         })
         alertController.addAction(OKAction)
         
        
         // Boutton annuler
         let cancelAction = UIAlertAction.init(title: Constants.AlertBoxTitle.annuler, style: UIAlertAction.Style.cancel, handler:{ (action: UIAlertAction!) in
            self.numAdresse = ""
            self.complement = ""
         })
         alertController.addAction(cancelAction)
        
         // Present Dialog message
         self.present(alertController, animated: true, completion:nil)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int)-> Int {
        return choixComplement.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return choixComplementTexte[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print(row)
        complement = choixComplement[row]
        complementTexte = choixComplementTexte[row]
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
        replacementString string: String) -> Bool {
        
        let isNumOk = textField.text!.count <= 2 || (textField.text!.count == 3 && string == "")
        
        if isNumOk {
            //Enregistrement du n°
            numAdresse = textField.text! + string
        }
        
        //Limitation des adresse à 3 chiffres - Prise en compte de la suppression de texte (DMR-1728)
        return isNumOk
    }
    
    func publicationAnomalie() {
        let mailAnomalyStoryboard = UIStoryboard(name: Constants.StoryBoard.thanks, bundle: nil)
        let mailAnomalyVC = mailAnomalyStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.mail) as! ThanksAnomalyViewController
        mailAnomalyVC.modalPresentationStyle = .overFullScreen
        mailAnomalyVC.currentAnomaly = self.currentAnomalie
        
        if User.shared.isLogged {
            // Enregistrement de l'anomalies et des photos.
            self.currentAnomalie?.mailUser = User.shared.email!
            mailAnomalyVC.status = .saveIncident
        } else {
            mailAnomalyVC.status = .showMail
        }
        mailAnomalyVC.typeContribution = self.typeContribution
        mailAnomalyVC.closeDelegate = self
        self.present(mailAnomalyVC, animated: true, completion: nil)
    }
    
    /// Methode permettant de récuperer le n° d'une adresse
    ///
    /// - Parameter street: l'adresse complete
    func getStreetNumber(adresse : String) -> String {
        var number = ""
        var hasValue = false
        
        // Loops thorugh the street
        for char in adresse {
            let str = String(char)
            // Checks if the char is a number
            if (Int(str) != nil){
                // If it is it appends it to number
                number+=str
                // Here we set the hasValue to true, beacause the street number will come in one order
                hasValue = true
            }
            else{
                if(hasValue){
                    break
                }
            }
        }
        return number
    }
    
    func showSpinner(onView : UIView) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        vSpinner = spinnerView
    }
    
    func removeSpinner() {
        DispatchQueue.main.async {
            self.vSpinner?.removeFromSuperview()
            self.vSpinner = nil
        }
    }
    
    //MARK: - Other functions
    func changeTypeAnomalie(newType:TypeAnomalie) {
        currentAnomalie?.categorieId = newType.categorieId
        currentAnomalie?.alias = newType.alias
        currentAnomalie?.anomalieStatus = .Brouillon
        self.currentAnomalie?.saveToDraft()
        
        tableViewAddAnomaly.reloadRows(at: [IndexPath(row: RowId.typeAnomalie, section: 0)], with: .none)
        tableViewAddAnomaly.reloadRows(at: [IndexPath(row: RowId.btnPublier, section: 0)], with: .none)

    }
    
    func changeDescriptive (descriptive: String) {
        currentAnomalie?.descriptive = descriptive
        currentAnomalie?.anomalieStatus = .Brouillon
        self.currentAnomalie?.saveToDraft()

        
        tableViewAddAnomaly.reloadRows(at: [IndexPath(row: RowId.description, section: 0)], with: .none)
        
    }
    
    func changePhoto(newPhoto: UIImage, isFirstPhoto: Bool) {
        if isFirstPhoto {
            currentAnomalie?.photo1 = newPhoto
        } else {
            currentAnomalie?.photo2 = newPhoto
        }
        currentAnomalie?.anomalieStatus = .Brouillon
        self.currentAnomalie?.saveToDraft()
        
        tableViewAddAnomaly.reloadRows(at: [IndexPath(row: RowId.photos, section: 0)], with: .none)
        tableViewAddAnomaly.reloadRows(at: [IndexPath(row: RowId.btnPublier, section: 0)], with: .none)

    }
    
    func changePriority(newPriority: Priority){
        currentAnomalie?.priorityId = newPriority.rawValue
        currentAnomalie?.anomalieStatus = .Brouillon
        self.currentAnomalie?.saveToDraft()

        
        self.tableViewAddAnomaly.reloadData()
    }
    
    @objc func takePhoto(_ sender: UITapGestureRecognizer) {
        let popupPhoto = UIStoryboard(name: Constants.StoryBoard.popupPhoto, bundle: nil).instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.popupPhoto) as! PopupPhotoViewController
        
        self.addChild(popupPhoto)
        self.view.addSubview(popupPhoto.view)
        popupPhoto.delegate = self
        popupPhoto.isFirstPhoto = true
        popupPhoto.didMove(toParent: self)
    }
    
    @objc func takePhoto2(_ sender: UITapGestureRecognizer) {
        let popupPhoto = UIStoryboard(name: Constants.StoryBoard.popupPhoto, bundle: nil).instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.popupPhoto) as! PopupPhotoViewController
        
        self.addChild(popupPhoto)

        self.view.addSubview(popupPhoto.view)
        popupPhoto.delegate = self
        popupPhoto.isFirstPhoto = false
        popupPhoto.didMove(toParent: self)
    }
    
    
    func changeAddress(newAddress: GMSAddress)  {
        currentAnomalie?.address = MapsUtils.fullAddress(gmsAddress: newAddress)
        currentAnomalie?.latitude = newAddress.coordinate.latitude
        currentAnomalie?.longitude = newAddress.coordinate.longitude
        currentAnomalie?.streetName = newAddress.thoroughfare ?? ""
        currentAnomalie?.postalCode = newAddress.postalCode ?? ""
        currentAnomalie?.locality = newAddress.locality ?? ""
        currentAnomalie?.anomalieStatus = .Brouillon
        self.currentAnomalie?.saveToDraft()

        
        tableViewAddAnomaly.reloadRows(at: [IndexPath(row: RowId.map, section: 0)], with: .none)
    }
    
    func changeEquipement(newEquipement: Equipement) {
        if let anomalieEquipement = currentAnomalie as? AnomalieEquipement {
            self.selectedEquipement = newEquipement
            anomalieEquipement.equipementId = newEquipement.equipementId
            anomalieEquipement.address = newEquipement.adresse
            anomalieEquipement.postalCode = MapsUtils.getPostalCode(address: newEquipement.adresse)
            anomalieEquipement.latitude = newEquipement.latitude
            anomalieEquipement.longitude = newEquipement.longitude
            anomalieEquipement.anomalieStatus = .Brouillon
            anomalieEquipement.saveToDraft()
            
            tableViewAddAnomaly.reloadRows(at: [IndexPath(row: RowId.map, section: 0)], with: .none)
        }
    }

    func isValidAnomalie() -> Bool {
        if let anomalie = currentAnomalie as? AnomalieEquipement {
            return !anomalie.categorieId.isEmpty && anomalie.photo1 != nil && !anomalie.address.isEmpty
                && !anomalie.equipementId.isEmpty && Reach().connectionStatus()
        } else if let anomalie = currentAnomalie {
            return !anomalie.categorieId.isEmpty && anomalie.photo1 != nil && !anomalie.address.isEmpty
                && !anomalie.postalCode.isEmpty && Reach().connectionStatus()
        }
        return false
    }

    @objc func btnDeletePhoto(sender:UIButton!)
    {
        if sender.tag == 100 {
            // Suppression de l'image 1
            currentAnomalie?.photo1 = currentAnomalie?.photo2
            currentAnomalie?.photo2 = nil
        } else {
            // Suppression de l'image 2
            currentAnomalie?.photo2 = nil
        }
        currentAnomalie?.anomalieStatus = .Brouillon
        
        tableViewAddAnomaly.reloadRows(at: [IndexPath(row: RowId.photos, section: 0)], with: .none)
        tableViewAddAnomaly.reloadRows(at: [IndexPath(row: RowId.btnPublier, section: 0)], with: .none)

    }
    
    /// Affichage d'un message d'alerte en fonction du message paramétré pour le TypeEquipement.
    /// Si pas de message de paramétré, pas de message d'alerte
    ///
    func showAlertMessagePhoto(equipement: Equipement) {
        if let typeEquipement = ReferalManager.shared.getTypeEquipement(forId: equipement.parentId) {
            if !typeEquipement.msgPhoto.isEmpty {
                let alertController = UIAlertController(title: Constants.AlertBoxTitle.attention, message: typeEquipement.msgPhoto, preferredStyle: .alert)
                // Create OK button
                let OKAction = UIAlertAction(title: Constants.AlertBoxTitle.ok, style: .default) { (action:UIAlertAction!) in
                    
                }
                alertController.addAction(OKAction)
                // Present Dialog message
                self.present(alertController, animated: true, completion:nil)
            }
        }
    }
}

// MARK: - Extension UITableViewDataSource
extension AddAnomalyViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 9
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.section, indexPath.row) == (0,RowId.map) {
            return 210
        } else if (indexPath.section, indexPath.row) == (0,1) {
            return 0
        } else if (indexPath.section, indexPath.row) == (0,RowId.photos) {
            return 160
        } else if (indexPath.section, indexPath.row) == (0,4) {
            return 0
        } else if (indexPath.section, indexPath.row) == (0,5) {
            return 40
        } else if (indexPath.section, indexPath.row) == (0,8) {
            return 95
        } else {
            //return UITableViewAutomaticDimension
            return 65
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.section, indexPath.row) == (0,RowId.map) {
            return 210
        } else if (indexPath.section, indexPath.row) == (0,1) {
            return 0
        } else if (indexPath.section, indexPath.row) == (0,RowId.photos) {
            return 160
        } else if (indexPath.section, indexPath.row) == (0,4) {
            return 0
        } else if (indexPath.section, indexPath.row) == (0,5) {
            return 40
        } else if (indexPath.section, indexPath.row) == (0,8) {
            return 95
        } else {
            //return UITableViewAutomaticDimension
            return 56
        }
    }

    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 0 : Map + Adresse
        // 1 : Separator
        // 2 : Type
        // 3 : Photo
        // 4 : Separator
        // 5 : Optionnel
        // 6 : Description
        // 7 : Priorite
        // 8 : Btn Publier
        
        var cell:UITableViewCell
        
        switch (indexPath.section, indexPath.row) {
        case (0,RowId.map):
            cell = self.tableViewAddAnomaly.dequeueReusableCell(withIdentifier: "mapCell")! as UITableViewCell
            
            var addressLabel = cell.viewWithTag(2) as! UILabel
            var boroughLabel = cell.viewWithTag(3) as! UILabel
            
            if self.typeContribution == .outdoor {
                //affichage des coordonnées GPS dans l'encart modification de l'adresse quand on est offline
                if ((currentAnomalie?.streetName.isEmpty)! && (currentAnomalie?.postalCode.isEmpty)!){
                    
                    if let latitude = currentAnomalie?.latitude, let longitude = currentAnomalie?.longitude {
                        MapsUtils.addressLabel = "lat : \(latitude), lgt : \(longitude)"
                        addressLabel.text = "lat : \(latitude)"
                        boroughLabel.text = "lgt : \(longitude)"
                        
                        MapsUtils.getAddressFromCoordinate(lat: latitude, long: longitude) {
                            (address: GMSAddress) in
                            
                            self.currentAnomalie?.address = MapsUtils.fullAddress(gmsAddress: address)
                            self.currentAnomalie?.postalCode = address.postalCode ?? ""
                            self.currentAnomalie?.streetName = address.thoroughfare ?? ""
                            self.currentAnomalie?.locality = address.locality ?? ""
                        }
                        
                    }
                } else {
                    let streetName = currentAnomalie?.streetName
                    let postalCode = currentAnomalie?.postalCode
                    addressLabel.text = streetName
                    boroughLabel.text = MapsUtils.boroughLabel(postalCode: postalCode!)

                }
            } else if self.typeContribution == .indoor {
                addressLabel.text = self.selectedEquipement?.name
                boroughLabel.text = self.selectedEquipement?.adresse
            }
            
            var mapView = cell.viewWithTag(1) as! GMSMapView;()
        
            // MARK: - Private functions
            func loadMapContainer(location: CLLocationCoordinate2D) {
                
                let camera = GMSCameraPosition.camera(withLatitude: location.latitude, longitude: location.longitude, zoom: Float(Constants.Maps.zoomLevel_50m))
                mapView.camera = camera
                
                // Utilisation d'une carte simplifiée
                mapView.mapType = GMSMapViewType.terrain
                
                // Permet de décaler les donnees Google (Logo, icone, ...)
                let mapInsets = UIEdgeInsets.init(top: 0.0, left: 0.0, bottom: 30.0, right: 0.0)
                mapView.padding = mapInsets
                
                mapView.isMyLocationEnabled = true
                mapView.settings.myLocationButton = false
                mapView.settings.scrollGestures = false
                mapView.settings.zoomGestures = false
                
                MapsUtils.addMarker(withName: adressModified, coordinate: location, inMap: mapView)
            }
            
            loadMapContainer(location: CLLocationCoordinate2D(latitude: (currentAnomalie?.latitude)!, longitude: (currentAnomalie?.longitude)!))
            
        
        case (0,RowId.typeAnomalie):
            cell = self.tableViewAddAnomaly.dequeueReusableCell(withIdentifier: "cell_type")! as UITableViewCell
            
            let typeLabel = cell.viewWithTag(2) as! UILabel
            typeLabel.text = Constants.LabelMessage.type
            let typeSubtitleLabel = cell.viewWithTag(3) as! UILabel
            
            let iconCheckType = cell.viewWithTag(1) as! UIImageView
            if let selectTypeAnomalie = getSelectedTypeAnomalie() {
                typeSubtitleLabel.text = selectTypeAnomalie.alias
                typeSubtitleLabel.textColor = UIColor.pinkDmr()
                
                let imageCheckType : UIImage = UIImage(named: Constants.Image.iconCheckPink)!
                iconCheckType.image = imageCheckType

            } else {
                typeSubtitleLabel.text = Constants.LabelMessage.select
                typeSubtitleLabel.textColor = UIColor.greyDmr()
                
                let imageCheckType : UIImage = UIImage(named: Constants.Image.iconCheckGrey)!
                iconCheckType.image = imageCheckType
            }

            cell.accessoryType = .disclosureIndicator

            
        case (0,RowId.photos):
            cell = self.tableViewAddAnomaly.dequeueReusableCell(withIdentifier: "cell_photo")! as UITableViewCell
            
            let photoLabel = cell.viewWithTag(1) as! UILabel
            photoLabel.text = Constants.LabelMessage.photo
            let photoSubtitleLabel = cell.viewWithTag(2) as! UILabel
            photoSubtitleLabel.text = Constants.LabelMessage.ajouter
            let iconCheckPhoto = cell.viewWithTag(3) as! UIImageView
            
            let addPhoto = cell.viewWithTag(4) as! UIImageView
            
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(takePhoto(_:)))
            addPhoto.addGestureRecognizer(gestureRecognizer)
            
            if let deleteBtn1 = cell.viewWithTag(100) as? UIButton {
                deleteBtn1.removeFromSuperview()
            }
            if let deleteBtn2 = cell.viewWithTag(200) as? UIButton {
                deleteBtn2.removeFromSuperview()
            }
            

            if let imageAno = currentAnomalie?.photo1 {
                addPhoto.image = imageAno
                
                let imageCheckPhoto : UIImage = UIImage(named: Constants.Image.iconCheckPink)!
                iconCheckPhoto.image = imageCheckPhoto
                
                if cell.viewWithTag(100) == nil {
                    // Ajout du bouton de suppression de la photo
                    cell.addSubview(addDeleteBtn(x: addPhoto.frame.origin.x, y: addPhoto.frame.origin.y, tag: 100))
                }
            } else {
                let imageCamera : UIImage = UIImage(named: Constants.Image.iconCamera)!
                addPhoto.image = imageCamera
                
                let imageCheckPhoto : UIImage = UIImage(named: Constants.Image.iconCheckGrey)!
                iconCheckPhoto.image = imageCheckPhoto
            }
            
            let addPhoto2 = cell.viewWithTag(5) as! UIImageView
            
            if currentAnomalie?.photo1 == nil {
                addPhoto2.isHidden = true
            } else {
                addPhoto2.isHidden = false
                
                let gestureRecognizer2 = UITapGestureRecognizer(target: self, action: #selector(takePhoto2(_:)))
                addPhoto2.addGestureRecognizer(gestureRecognizer2)
                
                if let imageAno = currentAnomalie?.photo2 {
                    addPhoto2.image = imageAno
                    
                    if cell.viewWithTag(200) == nil {
                        // Ajout du bouton de suppression de la photo
                        cell.addSubview(addDeleteBtn(x: addPhoto2.frame.origin.x, y: addPhoto2.frame.origin.y, tag: 200))
                    }
                } else {
                    let imageCamera : UIImage = UIImage(named: Constants.Image.iconCamera)!
                    addPhoto2.image = imageCamera
                }
                
            }
        
        case (0,5):
            cell = self.tableViewAddAnomaly.dequeueReusableCell(withIdentifier: "cell_optionnels")! as UITableViewCell
            
        case (0,RowId.description):
            cell = self.tableViewAddAnomaly.dequeueReusableCell(withIdentifier: "cell_description")! as UITableViewCell
            cell.accessoryType = .disclosureIndicator
            
            let descritpiveLabel = cell.viewWithTag(2) as! UILabel
            descritpiveLabel.text = Constants.LabelMessage.description
            let descriptiveSubtitleLabel = cell.viewWithTag(3) as! UILabel

            let iconCheckType = cell.viewWithTag(1) as! UIImageView
            if (currentAnomalie?.descriptive ?? "").isEmpty{
                descriptiveSubtitleLabel.text = Constants.LabelMessage.saisirDetail
                descriptiveSubtitleLabel.textColor = UIColor.greyDmr()
                let imageCheckType : UIImage = UIImage(named: Constants.Image.iconCheckGrey)!
                iconCheckType.image = imageCheckType
            } else {
                let imageCheckType : UIImage = UIImage(named: Constants.Image.iconCheckPink)!
                iconCheckType.image = imageCheckType
                descriptiveSubtitleLabel.text = currentAnomalie?.descriptive
                descriptiveSubtitleLabel.textColor = UIColor.greyDmr()
            }
            
        case (0,RowId.priorite):
            cell = self.tableViewAddAnomaly.dequeueReusableCell(withIdentifier: "cell_priorite")! as UITableViewCell
            cell.accessoryType = .disclosureIndicator
            
            let labelPriority = cell.viewWithTag(2) as! UILabel
            labelPriority.text = Constants.LabelMessage.priority
            let typeSubtitleLabel = cell.viewWithTag(3) as! UILabel
            
            let iconCheckType = cell.viewWithTag(1) as! UIImageView
            typeSubtitleLabel.text = Priority(rawValue: (currentAnomalie?.priorityId)!)?.description
            typeSubtitleLabel.textColor = UIColor.pinkDmr()
            
            let imageCheckType : UIImage = UIImage(named: Constants.Image.iconCheckPink)!
            iconCheckType.image = imageCheckType
            
        case (0,RowId.btnPublier):
            cell = self.tableViewAddAnomaly.dequeueReusableCell(withIdentifier: "cell_btn_publier")! as UITableViewCell
        
            let btnPublier = cell.viewWithTag(1) as! UIButton
            if isValidAnomalie() {
                btnPublier.isEnabled = true
                btnPublier.backgroundColor = UIColor.pinkButtonDmr()
            } else {
                btnPublier.isEnabled = false
                btnPublier.backgroundColor = UIColor.lightGreyDmr()
            }
        default:
            cell = self.tableViewAddAnomaly.dequeueReusableCell(withIdentifier: "cell_separator\(indexPath.row)")! as UITableViewCell
        }
        
        return cell
    }

    func addDeleteBtn(x: CGFloat, y: CGFloat, tag: Int) -> UIButton {
        let deleteImg = UIImage(named: Constants.Image.iconExit)
        
        let deleteBtn = UIButton(frame: CGRect(x:x - 5, y:y - 5, width:20, height:20))
        deleteBtn.backgroundColor = .black
        deleteBtn.layer.cornerRadius = 0.5 * deleteBtn.bounds.size.width
        deleteBtn.layer.borderWidth = 0
        deleteBtn.setImage(deleteImg, for: .normal)
        deleteBtn.tintColor = .white
        deleteBtn.tag = tag
        deleteBtn.addTarget(self, action: #selector(self.btnDeletePhoto(sender:)), for: .touchUpInside)
        deleteBtn.accessibilityLabel = Constants.LabelMessage.deletePhoto
        
        return deleteBtn
    }
    
    func getSelectedTypeAnomalie() -> TypeAnomalie? {
        var selectTypeAnomalie: TypeAnomalie?
        if let categId = currentAnomalie?.categorieId {
            if self.typeContribution == .indoor {
                guard let typeEquipementId = ContextManager.shared.typeEquipementSelected?.typeEquipementId else { return nil}
                selectTypeAnomalie = ReferalManager.shared.getTypeAnomalie(forTypeEquipementId: typeEquipementId, catagorieId: categId)
            } else {
                selectTypeAnomalie = ReferalManager.shared.getTypeAnomalie(withId: categId)
            }
        }
        return selectTypeAnomalie
    }
}

//MARK: - UITableView Delegate
extension AddAnomalyViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        if indexPath.row == RowId.priorite {
            let priorityListVC = UIStoryboard(name: Constants.StoryBoard.priority, bundle: nil).instantiateInitialViewController() as! PriorityViewController
            priorityListVC.delegate = self
            self.navigationController?.pushViewController(priorityListVC, animated: true)
        }
        if indexPath.row == RowId.typeAnomalie {
            let typeVC = UIStoryboard(name: Constants.StoryBoard.typeAnomalie, bundle: nil).instantiateInitialViewController() as! TypeAnomalieViewController
            typeVC.delegate = self
            self.navigationController?.pushViewController(typeVC, animated: true)
        }
        if indexPath.row == RowId.description {
            let descriptiveVC = UIStoryboard(name: Constants.StoryBoard.description, bundle: nil).instantiateInitialViewController() as! DescriptiveAnomalyViewController
            descriptiveVC.delegate = self
            descriptiveVC.defaultDescriptive = currentAnomalie?.descriptive
            self.navigationController?.pushViewController(descriptiveVC, animated: true)
        }

    }
}

extension AddAnomalyViewController: CloseDelegate {
        
    func displayMap() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    func displayThanks() {
        let thanksAnomalyStoryboard = UIStoryboard(name: Constants.StoryBoard.thanks, bundle: nil)
        let thanksAnomalyVC = thanksAnomalyStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.thanks) as! ThanksAnomalyViewController
        thanksAnomalyVC.modalPresentationStyle = .overFullScreen
        thanksAnomalyVC.currentAnomaly = self.currentAnomalie
        thanksAnomalyVC.status = .showThanks
        
        self.present(thanksAnomalyVC, animated: true, completion: nil)
        thanksAnomalyVC.closeDelegate = self
    }
        
}



