//
//  AddAnomalyViewController.swift
//  DansMaRue
//
//  Created by NTDC-Showroom on 22/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import AppAuth
import AVFoundation
import GoogleMaps
import GooglePlaces
import SwiftyJSON
import UIKit

class AddAnomalyViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, OIDAuthStateChangeDelegate {
    func didChange(_ state: OIDAuthState) {
        setAuthState(state)
    }
    
    // MARK: - Constantes

    enum RowId {
        static let map = 0
        static let typeAnomalie = 2
        static let photos = 3
        static let description = 5
        static let priorite = 6
        static let btnPublier = 7
    }
    
    // MARK: - Properties

    var adressModified = ""
    
    var currentAnomalie: Anomalie?
    var typeContribution: TypeContribution = .outdoor
    var selectedEquipement: Equipement?
    
    var choixComplementTexte: [String] = ["", "bis", "ter", "quarter"]
    var choixComplement: [String] = ["", "b", "t", "q"]
    var complement = ""
    var complementTexte = ""
    var numAdresse = ""
    private var authState: OIDAuthState?
    typealias PostRegistrationCallback = (_ configuration: OIDServiceConfiguration?, _ registrationResponse: OIDRegistrationResponse?) -> Void
    let redirectURI: String = Constants.Authentification.RedirectURI
    let authStateKey: String = "authState"
    
    var vSpinner: UIView?
    var isPublicationSoumise = false
    var isFirstPicture: Bool = true
    
    // MARK: - IBoutlets

    @IBOutlet var tableViewAddAnomaly: UITableView!
    
    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        isPublicationSoumise = false
        navigationItem.titleView?.isAccessibilityElement = true
        navigationItem.leftBarButtonItem?.accessibilityLabel = Constants.TitleButton.close
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.pinkButtonDmr()
            appearance.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.white])!
            self.navigationController?.navigationBar.standardAppearance = appearance
            self.navigationController?.navigationBar.scrollEdgeAppearance = self.navigationController?.navigationBar.standardAppearance
        }
        
        tableViewAddAnomaly.delegate = self
        tableViewAddAnomaly.dataSource = self
        tableViewAddAnomaly.estimatedRowHeight = 116
        tableViewAddAnomaly.rowHeight = UITableView.automaticDimension
        if let location = MapsUtils.userLocation() {
            if currentAnomalie == nil {
                if typeContribution == .outdoor {
                    currentAnomalie = Anomalie(address: MapsUtils.fullAddress(), latitude: location.latitude, longitude: location.longitude, categorieId: nil, descriptive: nil, priorityId: Priority.genant.rawValue, photo1: nil, photo2: nil, anomalieStatus: .Nouveau, mailUser: "", number: "", messagesSFGeneric: [(id: String, message: String)](),messagesSFTypologie:[(id: String, message: String)]())
                    if let myAddress = currentAnomalie?.address {
                        currentAnomalie?.streetName = MapsUtils.addressLabel
                        currentAnomalie?.postalCode = MapsUtils.getPostalCode(address: myAddress)
                    }
                } else if let equipement = ContextManager.shared.equipementSelected {
                    showAlertMessagePhoto(equipement: equipement)
                    selectedEquipement = equipement
                    
                    currentAnomalie = AnomalieEquipement(address: equipement.adresse, latitude: equipement.latitude, longitude: equipement.longitude, categorieId: nil, descriptive: nil, priorityId: Priority.genant.rawValue, photo1: nil, photo2: nil, anomalieStatus: .Nouveau, mailUser: "", number: "", messagesSFGeneric: [(id: String, message: String)](),messagesSFTypologie:[(id: String, message: String)]())
                    
                    currentAnomalie?.postalCode = MapsUtils.getPostalCode(address: equipement.adresse)
                    
                    if let anoEquipement = currentAnomalie as? AnomalieEquipement {
                        anoEquipement.equipementId = equipement.equipementId
                    }
                }
            } else {
                // Vérifie si l'anomalie contient une adresse valide
                if typeContribution == .outdoor && (currentAnomalie?.postalCode.isEmpty)! {
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

    // MARK: - IBActions

    @IBAction func cancel(_ sender: UIBarButtonItem) {
        if currentAnomalie?.anomalieStatus == .Brouillon {
            // Message d'avertissement
            let alertController = UIAlertController(title: Constants.AlertBoxTitle.attention, message: Constants.AlertBoxMessage.attention, preferredStyle: .alert)
            // Create Non button
            let NonAction = UIAlertAction(title: Constants.AlertBoxTitle.non, style: .default) { (_: UIAlertAction!) in
                AnomalieBrouillon.shared.remove(anomalie: self.currentAnomalie!)
                self.close()
            }
            alertController.addAction(NonAction)
            // Create Oui button
            let OuiAction = UIAlertAction(title: Constants.AlertBoxTitle.oui, style: .default) { (_: UIAlertAction!) in
                self.currentAnomalie?.saveToDraft()
                self.close()
            }
            alertController.addAction(OuiAction)
            // Present Dialog message
            present(alertController, animated: true, completion: nil)
            
        } else {
            close()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: navigationItem.titleView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: navigationItem.titleView)
        tableViewAddAnomaly.layoutIfNeeded()
        tableViewAddAnomaly.reloadData()
        if isPublicationSoumise && User.shared.isLogged {
            checkAddreseAndPublish()
        }
    }
        
    func close() {
        _ = navigationController?.popViewController(animated: true)
        UserDefaults.standard.removeObject(forKey: "descriptiveAno")
        UserDefaults.standard.removeObject(forKey: "counter")
    }
    
    @IBAction func editAddress(_ sender: UIButton_EditAddress) {
        let modifyAddress = UIStoryboard(name: Constants.StoryBoard.addAnomaly, bundle: nil).instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.modifyAddress) as! ModifyAddressViewController
        modifyAddress.delegate = self
        navigationController?.pushViewController(modifyAddress, animated: true)
        navigationController?.navigationBar.backgroundColor = UIColor.pinkDmr()
    }
    
    @IBAction func publier(_ sender: UIButton_PublierAnomalie) {
        isPublicationSoumise = true
        if !User.shared.isLogged {
            connectToMonParis()
        } else {
            checkAddreseAndPublish()
        }
    }
    
    func connectToMonParis() {
        let authorizationEndpoint = Constants.Authentification.authorizationEndpoint
        let tokenEndpoint = Constants.Authentification.tokenEndpoint
        let configuration = OIDServiceConfiguration(authorizationEndpoint: authorizationEndpoint,
                                                    tokenEndpoint: tokenEndpoint)
        
        doAuthWithAutoCodeExchange(configuration: configuration,
                                   clientID: Constants.Authentification.clientID,
                                   clientSecret: nil)
    }
    
    func doAuthWithAutoCodeExchange(configuration: OIDServiceConfiguration, clientID: String, clientSecret: String?) {
        guard let redirectURI = URL(string: redirectURI) else {
            print("Error creating URL for : \(redirectURI)")
            return
        }

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Error accessing AppDelegate")
            return
        }

        // builds authentication request
        let request = OIDAuthorizationRequest(configuration: configuration,
                                              clientId: clientID,
                                              clientSecret: clientSecret,
                                              scopes: [OIDScopeOpenID, OIDScopeProfile],
                                              redirectURL: redirectURI,
                                              responseType: OIDResponseTypeCode,
                                              additionalParameters: nil)

        // performs authentication request
        print("Initiating authorization request with scope: \(request.scope ?? "DEFAULT_SCOPE")")

        appDelegate.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: self) { authState, error in

            if let authState = authState {
                self.setAuthState(authState)
                print("Got authorization tokens. Access token: \(authState.lastTokenResponse?.accessToken ?? "DEFAULT_TOKEN")")
                self.userInfo()
            } else {
                print("Authorization error: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
                self.setAuthState(nil)
            }
        }
    }
    
    func userInfo() {
        let userInfoEndpoint = Constants.Authentification.userInfoEndpoint
        print("Performing userinfo request")
        let currentAccessToken: String? = authState?.lastTokenResponse?.accessToken

        authState?.performAction { accessToken, _, error in
            if error != nil {
                print("Error fetching fresh tokens: \(error?.localizedDescription ?? "ERROR")")
                return
            }

            guard let accessToken = accessToken else {
                print("Error getting accessToken")
                return
            }

            if currentAccessToken != accessToken {
                print("Access token was refreshed automatically (\(currentAccessToken ?? "CURRENT_ACCESS_TOKEN") to \(accessToken))")
            } else {
                print("Access token was fresh and not updated \(accessToken)")
            }

            var urlRequest = URLRequest(url: userInfoEndpoint)
            urlRequest.allHTTPHeaderFields = ["Authorization": "Bearer \(accessToken)"]

            let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                DispatchQueue.main.async {
                    guard error == nil else {
                        print("HTTP request failed \(error?.localizedDescription ?? "ERROR")")
                        return
                    }

                    guard let response = response as? HTTPURLResponse else {
                        print("Non-HTTP response")
                        return
                    }

                    guard let data = data else {
                        print("HTTP response data is empty")
                        return
                    }

                    var json: [AnyHashable: Any]?

                    do {
                        json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    } catch {
                        print("JSON Serialization Error")
                    }

                    if response.statusCode != 200 {
                        // server replied with an error
                        let responseText: String? = String(data: data, encoding: String.Encoding.utf8)

                        if response.statusCode == 401 {
                            // "401 Unauthorized" generally indicates there is an issue with the authorization
                            // grant. Puts OIDAuthState into an error state.
                            let oauthError = OIDErrorUtilities.resourceServerAuthorizationError(withCode: 0,
                                                                                                errorResponse: json,
                                                                                                underlyingError: error)
                            self.authState?.update(withAuthorizationError: oauthError)
                            print("Authorization Error (\(oauthError)). Response: \(responseText ?? "RESPONSE_TEXT")")
                        } else {
                            print("HTTP: \(response.statusCode), Response: \(responseText ?? "RESPONSE_TEXT")")
                        }

                        return
                    }

                    if let json = json as? [String: Any], let uid = json["uid"] as? String, let validatedAccount = json["validatedAccount"] as? String {
                        print("Success: \(json)")
                        
                        if validatedAccount != "true" {
                            let alertController = UIAlertController(title: Constants.AlertBoxTitle.erreur, message: Constants.AlertBoxMessage.erreur, preferredStyle: UIAlertController.Style.alert)
                            
                            let okAction = UIAlertAction(title: Constants.AlertBoxTitle.ok, style: UIAlertAction.Style.default) { _ in
                                // nothing
                            }
                            
                            alertController.addAction(okAction)
                            
                            self.present(alertController, animated: true, completion: nil)
                        } else {
                            User.shared.uid = uid
                            UserDefaults.standard.set(uid, forKey: Constants.Key.uid)
                            RestApiManager.sharedInstance.getIdentityStore(guid: User.shared.uid!) {
                                (_: Bool) in
                                if User.shared.isLogged {
                                    self.currentAnomalie?.mailUser = User.shared.email!
                                }
                            }
                        }
                    }
                }
            }

            task.resume()
        }
    }
    
    func setAuthState(_ authState: OIDAuthState?) {
        if self.authState == authState {
            return
        }
        self.authState = authState
        self.authState?.stateChangeDelegate = self
        var data: Data? = nil

        if let authState = self.authState {
            data = NSKeyedArchiver.archivedData(withRootObject: authState)
        }
        
        if let userDefaults = UserDefaults(suiteName: Constants.Authentification.userDefault) {
            userDefaults.set(data, forKey: authStateKey)
            userDefaults.synchronize()
        }
    }
    
    func checkAddreseAndPublish() {
        // On vérifie que l'adresse est bien dans paris avant la publication
        if !(currentAnomalie?.postalCode.hasPrefix(Constants.prefix75))! {
            // message alerte
            let alertController = UIAlertController(title: Constants.AlertBoxTitle.adresseInvalide, message: Constants.AlertBoxMessage.adresseInvalide, preferredStyle: .alert)
            // Create OK button
            let OKAction = UIAlertAction(title: Constants.AlertBoxTitle.ok, style: .default) { (_: UIAlertAction!) in
            }
            alertController.addAction(OKAction)
            // Present Dialog message
            present(alertController, animated: true, completion: nil)
        } else {
            // Vérification du n° obligatoire ou non de l'adresse
            // Récupération du 1er caractere de la rue pour vérifier si c'est un n°
            let trimmedAddress = currentAnomalie?.address.trimmingCharacters(in: .whitespaces)
            let first = trimmedAddress![trimmedAddress!.startIndex]
            let str = String(first)
            
            // Si l'adresse ne commence pas par un n°, affichage de la popup d'ajout de n°
            if Int(str) == nil && !(trimmedAddress?.lowercased().starts(with: "pont"))! {
                showAlertNumber()
            } else {
                // Sinon publication de l'ano
                publicationAnomalie()
            }
        }
    }
    
    // Affichage de la popup de numéro obligatoire
    func showAlertNumber() {
        // Affichage de la popup pour le n° de rue obligatoire
        // message alerte
        let alertController = UIAlertController(title: Constants.AlertBoxTitle.adresseInvalide, message: Constants.AlertBoxMessage.numRueObligatoire, preferredStyle: .alert)
         
        // Textfield pour la saisie du numéro
        alertController.addTextField { [weak self] textField in
            textField.keyboardType = .numberPad
            textField.text = self?.numAdresse
            textField.delegate = self
        }
         
        // Boutton complément d'adresse
        var titreAlertComplement = Constants.AlertBoxTitle.complementAdresseFacultatif
        if complement != "" {
            titreAlertComplement = Constants.AlertBoxTitle.complementAdresse + " : " + complementTexte
        }
        
        let ajoutComplementAction = UIAlertAction(title: titreAlertComplement, style: .default, handler: { (_: UIAlertAction!) in
            // Affichage alert selection complément
            let alert = UIAlertController(title: "Complément d'adresse", message: "\n\n\n\n\n\n\n\n\n", preferredStyle: UIAlertController.Style.alert)
            alert.isModalInPopover = true
            let pickerFrame: CGRect = .init(x: 5, y: 70, width: 250, height: 140)
            let picker: UIPickerView = .init(frame: pickerFrame)
            picker.delegate = self
            picker.dataSource = self
            alert.view.addSubview(picker)
             
            let OKAction = UIAlertAction(title: Constants.AlertBoxTitle.ok, style: .default, handler: { (_: UIAlertAction!) in
                print("ok")
                self.showAlertNumber()
            })
            alert.addAction(OKAction)
             
            self.present(alert, animated: true, completion: nil)
        })
        alertController.addAction(ajoutComplementAction)
         
        // Boutton publier
        let OKAction = UIAlertAction(title: Constants.AlertBoxTitle.publier, style: .default, handler: { (_: UIAlertAction!) in
            let textField = alertController.textFields![0] as UITextField
             
            // On ajoute le numéro si il est inférieur à 4 chiffres
            if textField.text != "", textField.text!.count < 4, textField.text != "0", textField.text != "00", textField.text != "000" {
                if self.complement != "" {
                    // Si un complément d'adresse est renseigné
                    self.currentAnomalie?.address = textField.text! + self.complement + " " + (self.currentAnomalie?.address)!
                } else {
                    self.currentAnomalie?.address = textField.text! + " " + (self.currentAnomalie?.address)!
                }
                
                // Affichage du spinner de chargement
                self.showSpinner(onView: self.view)
                
                // MAJ des coordonnées via la nouvelle adresse
                MapsUtils.getCoordinateFromAddress(adresse: textField.text! + self.currentAnomalie!.streetName + " " + self.currentAnomalie!.postalCode) { (coordinate: CLLocationCoordinate2D) in
                    self.currentAnomalie?.latitude = coordinate.latitude
                    self.currentAnomalie?.longitude = coordinate.longitude
                    
                    // Utilisation des nouvelles coordonnées pour récupérer le code postal (DMR-1785)
                    // Suite à l'ajout d'un n°, si une adresse est à cheval sur 2 arrondissements, le nouveau numéro necessite une vérification du CP
                    MapsUtils.getAddressFromCoordinate(lat: self.currentAnomalie!.latitude, long: self.currentAnomalie!.longitude) {
                        (address: GMSAddress) in
                        // MAJ du CP dans l'adresse
                        self.currentAnomalie?.address = (self.currentAnomalie?.address.replacingOccurrences(of: self.currentAnomalie!.postalCode, with: address.postalCode!))!
                        // MAJ du CP
                        self.currentAnomalie?.postalCode = address.postalCode ?? ""
                        
                        // Fin du chargement
                        self.removeSpinner()
                        
                        self.publicationAnomalie()
                    }
                }
            } else {
                // Fin du chargement
                self.removeSpinner()
                self.present(alertController, animated: true, completion: nil)
            }
        })
        alertController.addAction(OKAction)
         
        // Boutton annuler
        let cancelAction = UIAlertAction(title: Constants.AlertBoxTitle.annuler, style: UIAlertAction.Style.cancel, handler: { (_: UIAlertAction!) in
            self.numAdresse = ""
            self.complement = ""
        })
        alertController.addAction(cancelAction)
        
        // Present Dialog message
        present(alertController, animated: true, completion: nil)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
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
                   replacementString string: String) -> Bool
    {
        let isNumOk = textField.text!.count <= 2 || (textField.text!.count == 3 && string == "")
        
        if isNumOk {
            // Enregistrement du n°
            numAdresse = textField.text! + string
        }
        
        // Limitation des adresse à 3 chiffres - Prise en compte de la suppression de texte (DMR-1728)
        return isNumOk
    }
    
    func publicationAnomalie() {
        let mailAnomalyStoryboard = UIStoryboard(name: Constants.StoryBoard.thanks, bundle: nil)
        let mailAnomalyVC = mailAnomalyStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.mail) as! ThanksAnomalyViewController
        mailAnomalyVC.modalPresentationStyle = .overFullScreen
        mailAnomalyVC.currentAnomaly = currentAnomalie
        
        if User.shared.isLogged {
            // Enregistrement de l'anomalies et des photos.
            currentAnomalie?.mailUser = User.shared.email!
            mailAnomalyVC.status = .saveIncident
        } else {
            mailAnomalyVC.status = .showMail
        }
        mailAnomalyVC.typeContribution = typeContribution
        mailAnomalyVC.closeDelegate = self
        present(mailAnomalyVC, animated: true, completion: nil)
    }
    
    /// Methode permettant de récuperer le n° d'une adresse
    ///
    /// - Parameter street: l'adresse complete
    func getStreetNumber(adresse: String) -> String {
        var number = ""
        var hasValue = false
        
        // Loops thorugh the street
        for char in adresse {
            let str = String(char)
            // Checks if the char is a number
            if Int(str) != nil {
                // If it is it appends it to number
                number += str
                // Here we set the hasValue to true, beacause the street number will come in one order
                hasValue = true
            } else {
                if hasValue {
                    break
                }
            }
        }
        return number
    }
    
    func showSpinner(onView: UIView) {
        let spinnerView = UIView(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView(style: .whiteLarge)
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
    
    // MARK: - Other functions

    func changeTypeAnomalie(newType: TypeAnomalie) {
        currentAnomalie?.categorieId = newType.categorieId
        currentAnomalie?.alias = newType.alias
        currentAnomalie?.anomalieStatus = .Brouillon
        currentAnomalie?.saveToDraft()
        
        tableViewAddAnomaly.reloadRows(at: [IndexPath(row: RowId.typeAnomalie, section: 0)], with: .none)
        tableViewAddAnomaly.reloadRows(at: [IndexPath(row: RowId.btnPublier, section: 0)], with: .none)
    }
    
    func changeDescriptive(descriptive: String) {
        currentAnomalie?.descriptive = descriptive
        currentAnomalie?.anomalieStatus = .Brouillon
        currentAnomalie?.saveToDraft()

        tableViewAddAnomaly.reloadRows(at: [IndexPath(row: RowId.description, section: 0)], with: .none)
    }
    
    func changePhoto(newPhoto: UIImage, isFirstPhoto: Bool) {
        if isFirstPhoto {
            currentAnomalie?.photo1 = newPhoto
        } else {
            currentAnomalie?.photo2 = newPhoto
        }
        currentAnomalie?.anomalieStatus = .Brouillon
        currentAnomalie?.saveToDraft()
        
        tableViewAddAnomaly.reloadData()
    }
    
    func changePriority(newPriority: Priority) {
        currentAnomalie?.priorityId = newPriority.rawValue
        currentAnomalie?.anomalieStatus = .Brouillon
        currentAnomalie?.saveToDraft()

        tableViewAddAnomaly.reloadData()
    }
    
    @objc func takePhoto(_ sender: UITapGestureRecognizer) {
        isFirstPicture = true
        showPhotoPicker()
    }
    
    @objc func takePhoto2(_ sender: UITapGestureRecognizer) {
        isFirstPicture = false
        showPhotoPicker()
    }
    
    func changeAddress(newAddress: GMSAddress) {
        currentAnomalie?.address = MapsUtils.fullAddress(gmsAddress: newAddress)
        currentAnomalie?.latitude = newAddress.coordinate.latitude
        currentAnomalie?.longitude = newAddress.coordinate.longitude
        currentAnomalie?.streetName = newAddress.thoroughfare ?? ""
        currentAnomalie?.postalCode = newAddress.postalCode ?? ""
        currentAnomalie?.locality = (newAddress.locality == "Paris" ? newAddress.locality?.uppercased() : newAddress.locality) ?? ""
        currentAnomalie?.anomalieStatus = .Brouillon
        currentAnomalie?.saveToDraft()

        tableViewAddAnomaly.reloadRows(at: [IndexPath(row: RowId.map, section: 0)], with: .none)
    }
    
    func changeEquipement(newEquipement: Equipement) {
        if let anomalieEquipement = currentAnomalie as? AnomalieEquipement {
            selectedEquipement = newEquipement
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
                && !anomalie.equipementId.isEmpty
        } else if let anomalie = currentAnomalie {
            return !anomalie.categorieId.isEmpty && anomalie.photo1 != nil && !anomalie.address.isEmpty
                && !anomalie.postalCode.isEmpty
        }
        return false
    }

    @objc func btnDeletePhoto(sender: UIButton!) {
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
                let OKAction = UIAlertAction(title: Constants.AlertBoxTitle.ok, style: .default) { (_: UIAlertAction!) in
                }
                alertController.addAction(OKAction)
                // Present Dialog message
                present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    private func showPhotoPicker() {
        let alert = UIAlertController(title: "Ajouter une image",
                                      message: "",
                                      preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Prendre une photo",
                                      style: .default,
                                      handler: { _ in self.useCamera() }))
        alert.addAction(UIAlertAction(title: "Choisir dans l'album",
                                      style: .default,
                                      handler: { _ in self.searchPhoto() }))
        alert.addAction(UIAlertAction(title: "Annuler",
                                      style: .cancel,
                                      handler: { _ in alert.dismiss(animated: true) }))
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - Extension UITableViewDataSource

extension AddAnomalyViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
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
        
        var cell: UITableViewCell
        
        switch (indexPath.section, indexPath.row) {
        case (0, RowId.map):
            cell = tableViewAddAnomaly.dequeueReusableCell(withIdentifier: "mapCell")! as UITableViewCell
            cell.isAccessibilityElement = false
            let mapView = cell.viewWithTag(1) as! GMSMapView
            mapView.isAccessibilityElement = false
            let addressLabel = cell.viewWithTag(2) as! UILabel
            let boroughLabel = cell.viewWithTag(3) as! UILabel
            let editAddressButton = cell.viewWithTag(4) as! UIButton
            editAddressButton.isAccessibilityElement = true
            editAddressButton.accessibilityTraits = .button
            editAddressButton.accessibilityLabel = Constants.AccessibilityLabel.editAddress
            applyDynamicType(label: addressLabel, fontName: "Montserrat-Regular", size: 14.0)
            applyDynamicType(label: boroughLabel, fontName: "Montserrat-Regular", size: 14.0)
            addressLabel.isAccessibilityElement = true
            addressLabel.accessibilityTraits = .staticText
            boroughLabel.isAccessibilityElement = true
            boroughLabel.accessibilityTraits = .staticText
            
            if typeContribution == .outdoor {
                // affichage des coordonnées GPS dans l'encart modification de l'adresse quand on est offline
                if (currentAnomalie?.streetName.isEmpty)! && (currentAnomalie?.postalCode.isEmpty)! {
                    if let latitude = currentAnomalie?.latitude, let longitude = currentAnomalie?.longitude {
                        MapsUtils.addressLabel = "lat : \(latitude), lgt : \(longitude)"
                        addressLabel.text = "lat : \(latitude)"
                        addressLabel.accessibilityLabel = "latitude : \(latitude)"
                        boroughLabel.text = "lgt : \(longitude)"
                        boroughLabel.accessibilityLabel = "longitude : \(longitude)"
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
                    addressLabel.accessibilityLabel = streetName
                    boroughLabel.text = MapsUtils.boroughLabel(postalCode: postalCode!)
                    boroughLabel.accessibilityLabel = MapsUtils.boroughLabel(postalCode: postalCode!)
                }
            } else if typeContribution == .indoor {
                addressLabel.text = selectedEquipement?.name
                addressLabel.accessibilityLabel = selectedEquipement?.name
                boroughLabel.text = selectedEquipement?.adresse
                boroughLabel.accessibilityLabel = selectedEquipement?.adresse
            }
            
            // MARK: - Private functions

            func loadMapContainer(location: CLLocationCoordinate2D) {
                let camera = GMSCameraPosition.camera(withLatitude: location.latitude, longitude: location.longitude, zoom: Float(Constants.Maps.zoomLevel_50m))
                mapView.camera = camera
                
                // Utilisation d'une carte simplifiée
                mapView.mapType = GMSMapViewType.terrain
                
                // Permet de décaler les donnees Google (Logo, icone, ...)
                let mapInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 30.0, right: 0.0)
                mapView.padding = mapInsets
                
                mapView.isMyLocationEnabled = true
                mapView.settings.myLocationButton = false
                mapView.settings.scrollGestures = false
                mapView.settings.zoomGestures = false
                
                MapsUtils.addMarker(withName: adressModified, coordinate: location, inMap: mapView)
            }
            
            loadMapContainer(location: CLLocationCoordinate2D(latitude: (currentAnomalie?.latitude)!, longitude: (currentAnomalie?.longitude)!))
        case (0, 1):
            cell = tableViewAddAnomaly.dequeueReusableCell(withIdentifier: "cell_obligatoires")! as UITableViewCell
            let titleLabel = cell.viewWithTag(1) as! UILabel
            titleLabel.text = Constants.LabelMessage.requiredDetailsTitle

            titleLabel.isAccessibilityElement = true
            titleLabel.accessibilityTraits = .header
            titleLabel.textColor = UIColor.greyDmr()
            applyDynamicType(label: titleLabel, fontName: "Montserrat-Regular", size: 16.0)
        case (0, RowId.typeAnomalie):
            cell = tableViewAddAnomaly.dequeueReusableCell(withIdentifier: "cell_type")! as UITableViewCell
            cell.isAccessibilityElement = false
            let typeLabel = cell.viewWithTag(2) as! UILabel
            typeLabel.text = Constants.LabelMessage.type
            typeLabel.isAccessibilityElement = true
            typeLabel.accessibilityTraits = .staticText
            typeLabel.accessibilityLabel = Constants.LabelMessage.type
            
            let typeSubtitleLabel = cell.viewWithTag(3) as! UILabel
            typeSubtitleLabel.isAccessibilityElement = true
            typeSubtitleLabel.accessibilityTraits = .staticText
            applyDynamicType(label: typeSubtitleLabel, fontName: "Montserrat-Regular", size: 12.0)
            applyDynamicType(label: typeLabel, fontName: "Montserrat-Regular", size: 16.0)
            let iconCheckType = cell.viewWithTag(1) as! UIImageView
            iconCheckType.isAccessibilityElement = true
            if let selectTypeAnomalie = getSelectedTypeAnomalie() {
                typeSubtitleLabel.text = selectTypeAnomalie.alias
                typeSubtitleLabel.accessibilityLabel = selectTypeAnomalie.alias
                typeSubtitleLabel.textColor = UIColor.pinkDmr()
                let imageCheckType = UIImage(named: Constants.Image.iconCheckPink)!
                iconCheckType.image = imageCheckType
                iconCheckType.accessibilityLabel = "Type d'anomalie Renseigné"
            } else {
                typeSubtitleLabel.text = Constants.LabelMessage.select
                typeSubtitleLabel.textColor = UIColor.greyDmr()
                let imageCheckType = UIImage(named: Constants.Image.iconCheckGrey)!
                iconCheckType.image = imageCheckType
                iconCheckType.accessibilityLabel = "Type d'anomalie Non renseigné"
            }

            cell.accessoryType = .disclosureIndicator

        case (0, RowId.photos):
            cell = tableViewAddAnomaly.dequeueReusableCell(withIdentifier: "cell_photo")! as UITableViewCell
            cell.isAccessibilityElement = false
            let photoLabel = cell.viewWithTag(1) as! UILabel
            photoLabel.text = Constants.LabelMessage.photo
            photoLabel.isAccessibilityElement = true
            photoLabel.accessibilityTraits = .staticText
            let photoSubtitleLabel = cell.viewWithTag(2) as! UILabel
            photoSubtitleLabel.text = Constants.LabelMessage.ajouter
            photoSubtitleLabel.isAccessibilityElement = true
            photoSubtitleLabel.accessibilityTraits = .staticText
            photoSubtitleLabel.textColor = UIColor.greyDmr()
            applyDynamicType(label: photoSubtitleLabel, fontName: "Montserrat-Regular", size: 12.0)
            applyDynamicType(label: photoLabel, fontName: "Montserrat-Regular", size: 16.0)
            let iconCheckPhoto = cell.viewWithTag(3) as! UIImageView
            iconCheckPhoto.isAccessibilityElement = true

            let addPhoto = cell.viewWithTag(4) as! UIImageView
            addPhoto.isAccessibilityElement = true
            addPhoto.accessibilityTraits = .button
            addPhoto.accessibilityLabel = "Ajouter une photo"
            
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
                
                let imageCheckPhoto = UIImage(named: Constants.Image.iconCheckPink)!
                iconCheckPhoto.image = imageCheckPhoto
                iconCheckPhoto.accessibilityLabel = "renseigné"
                
                if cell.viewWithTag(100) == nil {
                    // Ajout du bouton de suppression de la photo
                    let deleteIcon = addDeleteBtn(x: addPhoto.frame.origin.x, y: addPhoto.frame.origin.y, tag: 100)
                    cell.addSubview(deleteIcon)
                    deleteIcon.topAnchor.constraint(equalTo: addPhoto.topAnchor, constant: -5).isActive = true
                    deleteIcon.leadingAnchor.constraint(equalTo: addPhoto.leadingAnchor, constant: -5).isActive = true
                    deleteIcon.heightAnchor.constraint(equalToConstant: 20).isActive = true
                    deleteIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
                }
            } else {
                let imageCamera = UIImage(named: Constants.Image.iconCamera)!
                addPhoto.image = imageCamera
                
                let imageCheckPhoto = UIImage(named: Constants.Image.iconCheckGrey)!
                iconCheckPhoto.image = imageCheckPhoto
                iconCheckPhoto.accessibilityLabel = "Non renseigné"
            }
            
            let addPhoto2 = cell.viewWithTag(5) as! UIImageView
            addPhoto2.isAccessibilityElement = true
            addPhoto2.accessibilityTraits = .button
            addPhoto2.accessibilityLabel = "Ajouter une deuxieme photo"
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
                        let deleteIcon = addDeleteBtn(x: addPhoto2.frame.origin.x, y: addPhoto2.frame.origin.y, tag: 200)
                        cell.addSubview(deleteIcon)
                        deleteIcon.topAnchor.constraint(equalTo: addPhoto2.topAnchor, constant: -5).isActive = true
                        deleteIcon.leadingAnchor.constraint(equalTo: addPhoto2.leadingAnchor, constant: -5).isActive = true
                        deleteIcon.heightAnchor.constraint(equalToConstant: 20).isActive = true
                        deleteIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
                    }
                } else {
                    let imageCamera = UIImage(named: Constants.Image.iconCamera)!
                    addPhoto2.image = imageCamera
                }
            }
        
        case (0, 4):
            cell = tableViewAddAnomaly.dequeueReusableCell(withIdentifier: "cell_optionnels")! as UITableViewCell
            let titleLabel = cell.viewWithTag(1) as! UILabel
            titleLabel.text = Constants.LabelMessage.optionnelDetailsTitle

            titleLabel.isAccessibilityElement = true
            titleLabel.accessibilityTraits = .header
            titleLabel.textColor = UIColor.greyDmr()
            applyDynamicType(label: titleLabel, fontName: "Montserrat-Regular", size: 16.0)
        case (0, RowId.description):
            cell = tableViewAddAnomaly.dequeueReusableCell(withIdentifier: "cell_description")! as UITableViewCell
            cell.isAccessibilityElement = false
            cell.accessoryType = .disclosureIndicator
            
            let descritpiveLabel = cell.viewWithTag(2) as! UILabel
            descritpiveLabel.isAccessibilityElement = true
            descritpiveLabel.accessibilityTraits = .staticText
            descritpiveLabel.text = Constants.LabelMessage.description
            let descriptiveSubtitleLabel = cell.viewWithTag(3) as! UILabel
            descriptiveSubtitleLabel.isAccessibilityElement = true
            descriptiveSubtitleLabel.accessibilityTraits = .staticText
            applyDynamicType(label: descritpiveLabel, fontName: "Montserrat-Regular", size: 16.0)
            applyDynamicType(label: descriptiveSubtitleLabel, fontName: "Montserrat-Regular", size: 12.0)
            
            let iconCheckType = cell.viewWithTag(1) as! UIImageView
            iconCheckType.isAccessibilityElement = true
            descriptiveSubtitleLabel.isAccessibilityElement = true
            if (currentAnomalie?.descriptive ?? "").isEmpty {
                descriptiveSubtitleLabel.text = Constants.LabelMessage.saisirDetail
                descriptiveSubtitleLabel.accessibilityLabel = Constants.LabelMessage.saisirDetail
                descriptiveSubtitleLabel.textColor = UIColor.greyDmr()
                let imageCheckType = UIImage(named: Constants.Image.iconCheckGrey)!
                iconCheckType.image = imageCheckType
                iconCheckType.accessibilityLabel = "non renseigné"
            } else {
                let imageCheckType = UIImage(named: Constants.Image.iconCheckPink)!
                iconCheckType.image = imageCheckType
                descriptiveSubtitleLabel.text = currentAnomalie?.descriptive
                descriptiveSubtitleLabel.accessibilityLabel = currentAnomalie?.descriptive
                descriptiveSubtitleLabel.textColor = UIColor.greyDmr()
                iconCheckType.accessibilityLabel = "renseigné"
            }
            
        case (0, RowId.priorite):
            cell = tableViewAddAnomaly.dequeueReusableCell(withIdentifier: "cell_priorite")! as UITableViewCell
            cell.isAccessibilityElement = false
            cell.accessoryType = .disclosureIndicator
            
            let labelPriority = cell.viewWithTag(2) as! UILabel
            labelPriority.isAccessibilityElement = true
            labelPriority.accessibilityTraits = .staticText
            labelPriority.text = Constants.LabelMessage.priority
            let typeSubtitleLabel = cell.viewWithTag(3) as! UILabel
            typeSubtitleLabel.isAccessibilityElement = true
            typeSubtitleLabel.accessibilityTraits = .staticText
            applyDynamicType(label: labelPriority, fontName: "Montserrat-Regular", size: 16.0)
            applyDynamicType(label: typeSubtitleLabel, fontName: "Montserrat-Regular", size: 12.0)
            let iconCheckType = cell.viewWithTag(1) as! UIImageView
            typeSubtitleLabel.text = Priority(rawValue: (currentAnomalie?.priorityId)!)?.description
            typeSubtitleLabel.textColor = UIColor.pinkDmr()
            
            let imageCheckType = UIImage(named: Constants.Image.iconCheckPink)!
            iconCheckType.image = imageCheckType
            iconCheckType.isAccessibilityElement = true
            iconCheckType.accessibilityLabel = "renseigné"
            
        case (0, RowId.btnPublier):
            cell = tableViewAddAnomaly.dequeueReusableCell(withIdentifier: "cell_btn_publier")! as UITableViewCell
            cell.isAccessibilityElement = false
            let btnPublier = cell.viewWithTag(1) as! UIButton
            btnPublier.isAccessibilityElement = true
            btnPublier.accessibilityTraits = .button
            applyDynamicType(label: btnPublier.titleLabel!, fontName: "Montserrat-Regular", size: 22.0)
            if isValidAnomalie() {
                btnPublier.isEnabled = true
                btnPublier.backgroundColor = UIColor.pinkButtonDmr()
            } else {
                btnPublier.isEnabled = false
                btnPublier.backgroundColor = UIColor.lightGreyDmr()
            }
        default:
            cell = UITableViewCell()
        }
        
        return cell
    }

    func addDeleteBtn(x: CGFloat, y: CGFloat, tag: Int) -> UIButton {
        let deleteImg = UIImage(named: Constants.Image.iconExit)
        
        let deleteBtn = UIButton(frame: CGRect(x: x - 5, y: y - 5, width: 20, height: 20))
        deleteBtn.backgroundColor = .black
        deleteBtn.layer.cornerRadius = 0.5 * deleteBtn.bounds.size.width
        deleteBtn.layer.borderWidth = 0
        deleteBtn.setImage(deleteImg, for: .normal)
        deleteBtn.tintColor = .white
        deleteBtn.tag = tag
        deleteBtn.addTarget(self, action: #selector(btnDeletePhoto(sender:)), for: .touchUpInside)
        deleteBtn.accessibilityLabel = Constants.LabelMessage.deletePhoto
        
        return deleteBtn
    }

    func getSelectedTypeAnomalie() -> TypeAnomalie? {
        var selectTypeAnomalie: TypeAnomalie?
        if let categId = currentAnomalie?.categorieId {
            if typeContribution == .indoor {
                guard let typeEquipementId = ContextManager.shared.typeEquipementSelected?.typeEquipementId else { return nil }
                selectTypeAnomalie = ReferalManager.shared.getTypeAnomalie(forTypeEquipementId: typeEquipementId, catagorieId: categId)
            } else {
                selectTypeAnomalie = ReferalManager.shared.getTypeAnomalie(withId: categId)
            }
        }
        return selectTypeAnomalie
    }
    
    private func applyDynamicType(label: UILabel, fontName: String, size: Float) {
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.scaledFont(name: fontName, textSize: CGFloat(size))
    }
}

// MARK: - UITableView Delegate

extension AddAnomalyViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == RowId.priorite {
            let priorityListVC = UIStoryboard(name: Constants.StoryBoard.priority, bundle: nil).instantiateInitialViewController() as! PriorityViewController
            priorityListVC.delegate = self
            navigationController?.pushViewController(priorityListVC, animated: true)
        }
        if indexPath.row == RowId.typeAnomalie {
            let typeVC = UIStoryboard(name: Constants.StoryBoard.typeAnomalie, bundle: nil).instantiateInitialViewController() as! TypeAnomalieViewController
            typeVC.delegate = self
            navigationController?.pushViewController(typeVC, animated: true)
        }
        if indexPath.row == RowId.description {
            let descriptiveVC = UIStoryboard(name: Constants.StoryBoard.description, bundle: nil).instantiateInitialViewController() as! DescriptiveAnomalyViewController
            descriptiveVC.delegate = self
            descriptiveVC.defaultDescriptive = currentAnomalie?.descriptive
            navigationController?.pushViewController(descriptiveVC, animated: true)
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
        thanksAnomalyVC.currentAnomaly = currentAnomalie
        thanksAnomalyVC.status = .showThanks
        
        present(thanksAnomalyVC, animated: true, completion: nil)
        thanksAnomalyVC.closeDelegate = self
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}

extension AddAnomalyViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func useCamera() {
        print(" prise de photo ...")
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            checkCameraStatus()
        } else {
            let alertController = UIAlertController(title: Constants.AlertBoxTitle.erreur, message: "Device has no camera", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: Constants.AlertBoxTitle.ok, style: .default, handler: { _ in
                print("Device has no camera")
            })
            alertController.addAction(defaultAction)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func searchPhoto() {
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()
        
        // Only allow photos to be picked, not taken.
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.allowsEditing = false
        
        // Make sure ViewController is notified when the user picks an image.
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    /// Methode permettant de verifier les authorisations sur l'utilisation de la caméra
    ///
    func checkCameraStatus() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType(rawValue: convertFromAVMediaType(AVMediaType.video)))
        switch authStatus {
        case .authorized: showCameraPicker()
        case .denied: alertPromptToAllowCameraAccessViaSettings()
        case .notDetermined: permissionPrimeCameraAccess()
        default: permissionPrimeCameraAccess()
        }
    }
    
    /// Affiche une alerte pour demander la modification des authorisations pour l'utilisation de la caméra
    ///
    func alertPromptToAllowCameraAccessViaSettings() {
        let alert = UIAlertController(title: Constants.AlertBoxTitle.grantPhoto, message: Constants.AlertBoxMessage.grantPhoto, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Constants.AlertBoxTitle.parametres, style: .cancel) { _ in
            UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
        })
        let cancelAction = UIAlertAction(title: Constants.AlertBoxTitle.annuler, style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(cancelAction)

        present(alert, animated: true, completion: nil)
    }
    
    /// Permet de demander l'authorisation d'utiliser la camera pour la prise de photo
    ///
    func permissionPrimeCameraAccess() {
        if AVCaptureDevice.devices(for: AVMediaType(rawValue: convertFromAVMediaType(AVMediaType.video))).count > 0 {
            AVCaptureDevice.requestAccess(for: AVMediaType(rawValue: convertFromAVMediaType(AVMediaType.video)), completionHandler: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.checkCameraStatus() // try again
                }
            })
        }
    }
    
    /// Ouverture de l'appareil photo
    ///
    func showCameraPicker() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = UIImagePickerController.SourceType.camera
        imagePickerController.allowsEditing = false
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Dismiss the picker if the user canceled.
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        // The info dictionary may contain multiple representations of the image. You want to use the original.
        if let selectedImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage {
            // Dismiss the picker.
            dismiss(animated: true, completion: nil)
            // removeAnimate()
            
            // Compress and resize Image
            let imageResize = selectedImage.resizeWithWidth(width: Constants.Image.maxWith)
            let compressData = imageResize!.jpegData(compressionQuality: Constants.Image.compressionQuality)
            let compressedImage = UIImage(data: compressData!)
            
            changePhoto(newPhoto: compressedImage!, isFirstPhoto: isFirstPicture)
        } else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (key.rawValue, value) })
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromAVMediaType(_ input: AVMediaType) -> String {
    return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}
