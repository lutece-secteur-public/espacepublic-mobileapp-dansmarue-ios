//
//  MapViewController.swift
//  DansMaRue
//
//  Created by NTDC-Showroom on 16/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import SwiftyJSON
import Mapbox

class MapViewController: UIViewController {
    
    // MARK: Properties
    var locationManager = CLLocationManager()
    
    // Google SearchBar properties
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var placesClient: GMSPlacesClient?
    
    // Equipements SeachBar properties
    var customSearchController: UISearchController?
    var equipementSearchController: EquipementSearchTableViewController?
    
    let anomalieNotification = Notification.Name(rawValue:Constants.NoticationKey.anomaliesChanged)
    let addressNotification = Notification.Name(rawValue:Constants.NoticationKey.addressNotification)
    let uberPin = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    var uberPinVisible = false
    
    var bottomSheetVC: BottomSheetViewController?
    var switchButton: UIButton?
    
    // MARK: IBOutlet
    @IBOutlet weak var mapContainerView: GMSMapView!
    @IBOutlet weak var uberActionLabel: UILabel!

    
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self

        loadMapContainer()
        
        // Gestion des autorisations
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            print("CLLocationManager.authorizationStatus() == authorizedWhenInUse, retrieve current position")
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            mapContainerView.isMyLocationEnabled = true
            mapContainerView.settings.myLocationButton = true
            locationManager.startUpdatingLocation();
        } else if CLLocationManager.authorizationStatus() == .denied {
            // L'utilisateur refuse la location. Affichage d'une alert
            // Open the settings of your app
            self.requestAuthorization()
            positionToParis()
        } else {
            // Ask for Authorisation from the User.
            locationManager.requestWhenInUseAuthorization()
            positionToParis()
        }

        placesClient = GMSPlacesClient()
        initializeSearchBar()
        initializeCustomSearchBar()
        
        uberActionLabel.isHidden = true

        // Add button to switch anomaly if equipement is available
        DispatchQueue.global().async {
            RestApiManager.sharedInstance.getEquipements{(result: Bool) in
                if result {
                    self.addSwitchButton()
                }
            }
        }
        
        let url = URL(string: "mapbox://styles/mapbox/streets-v11")
        let mapView = MGLMapView(frame: CGRect(x: 0, y: 0, width: 0, height: 0), styleURL: url)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.setCenter(CLLocationCoordinate2D(latitude: 59.31, longitude: 18.06), zoomLevel: 9, animated: false)
        view.addSubview(mapView)
    }
    

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addBottomSheetView()
        
        // Raffraichissement de la liste des anomalies
        if ContextManager.shared.typeContribution == .outdoor && MapsUtils.addressLabel == "" {
            if let location = MapsUtils.userLocation() {
                retrieve(currentLocation: location, addMarker: true) { (result: Bool) in }
            }
        } else if ContextManager.shared.typeContribution == .indoor, let equipement = ContextManager.shared.equipementSelected {
            self.updateEquipementSelected(forId: equipement.equipementId)
        }
        
        uberActionLabel.layer.masksToBounds = true
        uberActionLabel.layer.cornerRadius = 10
        
    }
    
    
    //MARK: - View navigation
    /// Méthode permettant d'initialiser et de rajouter la bottomsheet sur la vue
    ///
    func addBottomSheetView() {
        let mapStoryboard = UIStoryboard(name: Constants.StoryBoard.map, bundle: nil)
        if bottomSheetVC == nil {
            bottomSheetVC = mapStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.bottomSheet) as?BottomSheetViewController
            
            // 2- Add bottomSheetVC as a child view and set its delegate
            bottomSheetVC?.uberDelegate = self
            bottomSheetVC?.delegate = self
        }
        bottomSheetVC?.partialView = self.mapContainerView.frame.origin.y + self.mapContainerView.frame.height
        self.addChild(bottomSheetVC!)
        self.view.addSubview((bottomSheetVC?.view)!)
        bottomSheetVC?.didMove(toParent: self)
        
        // 3- Adjust bottomSheet frame and initial position.
        bottomSheetVC?.view.frame = CGRect(x: 0, y: self.view.frame.maxY, width: view.frame.width, height: view.frame.height)
        
    }
    
    /// Méthode permettant d'initialiser la barre de recherche d'adresse pour l'espace public
    ///
    func initializeSearchBar()  {
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        
        // Put the search bar in the navigation bar.
        if let searchBar = searchController?.searchBar {
            
            searchBar.placeholder = Constants.PlaceHolder.saisirAdresse
            
            searchBar.tintColor = UIColor.white
            searchBar.isTranslucent = false
            if #available(iOS 13.0, *) {
                searchBar.searchTextField.backgroundColor=UIColor.white
                searchBar.searchTextField.tintColor=UIColor.black
            }
            
            searchBar.layer.cornerRadius = 10;
            self.setNavigationTitleView(withSearchBar: searchBar)
            
        }
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = UIColor.pinkButtonDmr()
        self.extendedLayoutIncludesOpaqueBars = true
        
        
        // When UISearchController presents the results view, present it in
        // this view controller, not one further up the chain.
        self.definesPresentationContext = true
        
        // Prevent the navigation bar from being hidden when searching.
        searchController?.hidesNavigationBarDuringPresentation = false
        
        // Active sur le filtre sur Paris uniquement
        MapsUtils.filterToParis(resultsViewController: self.resultsViewController!)
    }
    
    /// Méthode permettant d'initialiser la barre de recherche des équipements pour l'indoor.
    ///
    func initializeCustomSearchBar() {
        // Place the search bar view to the tableview headerview.
        if equipementSearchController == nil {
            let mapStoryboard = UIStoryboard(name: Constants.StoryBoard.map, bundle: nil)
            equipementSearchController = mapStoryboard.instantiateViewController(withIdentifier: "EquipementSearchTableViewController") as? EquipementSearchTableViewController
            
            equipementSearchController?.equipementDelegate = self
        }
        
        customSearchController = UISearchController(searchResultsController: equipementSearchController)
        customSearchController?.hidesNavigationBarDuringPresentation = false
        customSearchController?.searchBar.placeholder = Constants.PlaceHolder.saisirAdresse
        customSearchController?.searchBar.sizeToFit()
        
        equipementSearchController?.tableView.tableHeaderView = customSearchController?.searchBar
        customSearchController?.searchResultsUpdater = equipementSearchController
    }
    
    /// Permet de positionner la SearchBar spécifié sur la barre de navigation
    ///
    func setNavigationTitleView(withSearchBar searchBar: UISearchBar) {
        if #available(iOS 11.0, *) {
            // For iOS 11+, fix size to 32 for navigationbar
            //searchBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
            let searchBarContainer = SearchBarContainerView(customSearchBar: searchBar)
            searchBarContainer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 32)
            self.navigationItem.titleView = searchBarContainer
        } else {
            searchBar.sizeToFit()
            self.navigationItem.titleView = searchBar
        }
        
        let menuBtn = UIButton(type: .custom)
        menuBtn.frame = CGRect(x: 0.0, y: 0.0, width: 44, height: 44)
        menuBtn.setImage(UIImage(named:Constants.Image.favorite), for: .normal)
        menuBtn.addTarget(self, action: #selector(addTapped), for:.touchDown)
        let menuBarItem = UIBarButtonItem(customView: menuBtn)
        
        let currWidth = menuBarItem.customView?.widthAnchor.constraint(equalToConstant: 25)
        currWidth?.isActive = true
        let currHeight = menuBarItem.customView?.heightAnchor.constraint(equalToConstant: 25)
        currHeight?.isActive = true
        
        self.navigationItem.rightBarButtonItem = menuBarItem
    }
    
    @objc func addTapped() {
        let manageAddressVC = UIStoryboard(name: Constants.StoryBoard.manageAddress, bundle: nil).instantiateInitialViewController() as! ManageAddressViewController
        manageAddressVC.delegate = self
        self.navigationController?.pushViewController(manageAddressVC, animated: true)
    }

    /// Ajout d'un bouton sur la carte permettant de sélectionner le type de contribution
    func addSwitchButton() {
        
        //Si equipement est lancé, on ajoute le bouton de selection du type
        DispatchQueue.global().async {
            RestApiManager.sharedInstance.getEquipements{(result: Bool) in
                if result {                    
                    if UIDevice().userInterfaceIdiom == .phone {
                        switch UIScreen.main.nativeBounds.height {
                        case 2436:
                            //Iphone x - position du switchButton plus basse
                            self.switchButton = UIButton(frame: CGRect(x: 15, y: 100, width: self.view.frame.size.width - 30, height: 40))
                        default:
                            self.switchButton = UIButton(frame: CGRect(x: 15, y: 80, width: self.view.frame.size.width - 30, height: 40))
                        }
                    }
                    
                    self.switchButton?.layer.cornerRadius = 20
                    self.switchButton?.layer.borderWidth = 0
                    
                    self.switchButton?.setTitle(Constants.LabelMessage.defaultTypeContributionLabel, for: .normal)
                    
                    self.switchButton?.setTitleColor(UIColor.white, for: UIControl.State.normal)
                    
                    self.switchButton?.backgroundColor = UIColor.pinkButtonDmr()
                    self.switchButton?.alpha = 0.8
                    
                    self.switchButton?.addTarget(self, action: #selector(MapViewController.switchButtonAction(_: )), for: .touchUpInside)
                    
                    self.view.addSubview(self.switchButton!)
                }
            }
        }
    }

    // MARK: - Other Methods
    private func loadMapContainer() {
        mapContainerView.mapType = GMSMapViewType.terrain
        
        // Permet de décaler les donnees Google (Logo, icone, ...)
        let mapInsets = UIEdgeInsets.init(top: 0.0, left: 0.0, bottom: 30.0, right: 0.0)
        mapContainerView.padding = mapInsets
        mapContainerView.delegate = self
        
    }
    
    /// Action sur la bouton de type de contribution.
    /// Ouverture d'un nouvel écran permettant de sélectionner le type de contribution
    ///
    @objc func switchButtonAction(_:Any) {
        let typeContributionView = UIStoryboard(name: Constants.StoryBoard.typeContribution, bundle: nil).instantiateInitialViewController() as! TypeContributionViewController
        typeContributionView.delegate = self
        self.navigationController?.pushViewController(typeContributionView, animated: true)
    }
    
    /// Methode permettant de changer le type de contribution.
    /// Affecte les markers sur la carte avec les types d'anomalies ou équipement
    ///
    /// - Parameter withName: String - Libellé à appliquer sur le bouton
    func changeTypeContribution(withName buttonTitle: String) {
        self.switchButton?.setTitle(buttonTitle, for: .normal)
        
        // Changement de la searchbar en fonction du type de contribution
        if ContextManager.shared.typeContribution == .outdoor {
            // Changement du placeholder pour anomalie outdoor
            searchController?.searchBar.placeholder = Constants.PlaceHolder.saisirAdresse
            self.setNavigationTitleView(withSearchBar: (searchController?.searchBar)!)
        } else {
            // Changement du placeholder en fonction du Type Equipement
            customSearchController?.searchBar.placeholder = ContextManager.shared.typeEquipementSelected?.placeholder
            equipementSearchController?.equipements = ReferalManager.shared.getEquipements(forTypeEquipementId: (ContextManager.shared.typeEquipementSelected?.typeEquipementId)!)!
            equipementSearchController?.equipements.sort(by: { $0.name.caseInsensitiveCompare($1.name) == .orderedAscending })
            equipementSearchController?.tableView.reloadData()
            self.setNavigationTitleView(withSearchBar: (customSearchController?.searchBar)!)
                        
            // hide uber label
            self.shouldDisplayUberPin(yesWeCan: false)
            self.bottomSheetVC?.uberDisplayed = false
        }
        
        if let position = MapsUtils.userLocation() {
            retrieve(currentLocation: position, addMarker: true) { (result: Bool) in }
        }
        
    }
    
    /// Permet d'ajouter un GMSMarker et de positionner la caméra au centre de Paris.
    ///
    private func positionToParis() {
        let camera = GMSCameraPosition.camera(withLatitude: Constants.Maps.parisLatitude, longitude: Constants.Maps.parisLongitude, zoom: Float(Constants.Maps.zoomLevel))
        mapContainerView.camera = camera
        
        MapsUtils.addMarker(withName: "Paris", coordinate: CLLocationCoordinate2DMake(Constants.Maps.parisLatitude, Constants.Maps.parisLongitude), inMap: mapContainerView)
    }
    
    ///Demande à l'utilisateur l'accès au service de localisation
    ///
    private func requestAuthorization() {
        let alertController = UIAlertController (title: Constants.AlertBoxTitle.locationDisabled, message: Constants.AlertBoxMessage.locationDisabled, preferredStyle: UIAlertController.Style.alert)
        
        let okBtn = UIAlertAction(title:"OK" , style: .default, handler: {(_ action: UIAlertAction) -> Void in
        })
        
        alertController.addAction(okBtn)
        
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
        if let location = mapView.myLocation?.coordinate {
            
            let cameraUpdate = GMSCameraUpdate.setTarget(location, zoom: Constants.Maps.zoomLevel_50m)
            mapView.animate(with: cameraUpdate)
            
            retrieve(currentLocation: location, addMarker: true) { (result: Bool) in }
        }
        return true
    }
    
    /// Méthode permettant de rechercher les anomalies ou équipement à partir d'une position
    ///
    /// - Parameters:
    ///   - location: Coordonnées de la position de l'utilisateur
    ///   - addMarker: Flag indiquant si le marqueur de position doit etre rajouter
    ///   - onCompletion: true : si la recherche a aboutie, false sinon
    func retrieve(currentLocation location:CLLocationCoordinate2D, addMarker: Bool, address: String="", cp: String="", onCompletion: @escaping (Bool) -> Void) {
        self.mapContainerView.clear()
        
        if ContextManager.shared.typeContribution == .outdoor {
            MapsUtils.addMarker(withName: MapsUtils.fullAddress(), coordinate: location, inMap: self.mapContainerView)
        }
        
        if Reach().connectionStatus() {
            // Device en mode Connecté
            let geocoder = GMSGeocoder()
            geocoder.reverseGeocodeCoordinate(location) { (response: GMSReverseGeocodeResponse?, error: Error?) in
                if let error = error {
                    print("Nothing found: \(error.localizedDescription)")
                    return
                }
                guard let addressFound = response else {
                    return
                }
                
                if ContextManager.shared.typeContribution == .outdoor {
                    var anomaliesBottomSheet = [Anomalie]()
                    
                    // Cas du mode Espace public. On recherche les anomalies à proximite
                    DispatchQueue.global().async {
                        RestApiManager.sharedInstance.getIncidentsByPosition(coordinates: location) { (anomalies: [Anomalie]) in
                            if ContextManager.shared.typeContribution == .outdoor {
                                DispatchQueue.main.async {
                                    
                                    for anomalie in anomalies {
                                        // Ajout du GMSMarker sur la map
                                        self.addMarkerAnomalie(anomalie: anomalie)
                                        
                                        if anomalie.anomalieStatus != .Resolu && !anomaliesBottomSheet.contains(anomalie) {
                                            anomaliesBottomSheet.append(anomalie)
                                        }
                                    }
                                    
                                    NotificationCenter.default.post(name: self.anomalieNotification, object: anomaliesBottomSheet)
                                    onCompletion(true)
                                }
                            }
                        }
                    }
                    
                    // Cas du mode Espace public. On recherche les anomalies Ramen à proximite
                   DispatchQueue.global().async {
                        RestApiManager.sharedInstance.getDossierRamenByPosition(coordinates: location) { (anomalies: [Anomalie]) in
                            if ContextManager.shared.typeContribution == .outdoor {
                                DispatchQueue.main.async {
                                    for anomalie in anomalies {
                                        // Ajout du GMSMarker sur la map
                                        self.addMarkerAnomalie(anomalie: anomalie)
                                        
                                        
                                        if anomalie.anomalieStatus != .Resolu && !anomaliesBottomSheet.contains(anomalie) {
                                            anomaliesBottomSheet.append(anomalie)
                                        }
                                    }
                                    
                                    NotificationCenter.default.post(name: self.anomalieNotification, object: anomaliesBottomSheet)
                                    onCompletion(true)
                                }
                            }
                        }
                    }
                    
                } else if ContextManager.shared.typeContribution == .indoor {
                    // Cas de la sélection d'un TypeEquipement, on affiche les équipements autour de nous
                    DispatchQueue.global().async {
                        
                        RestApiManager.sharedInstance.getEquipementByPosition(coordinates: location) { (equipements: [Equipement]) in
                            
                            if ContextManager.shared.typeContribution == .indoor {
                                DispatchQueue.main.async {
                                    var anomaliesBottomSheet = [AnomalieEquipement]()
                                    
                                    for equipement in equipements {
                                        if addMarker {
                                            self.addMarkerEquipement(equipement: equipement)
                                        } else {
                                            for anomalie in equipement.anomalies {
                                                if anomalie.anomalieStatus != .Resolu {
                                                    anomaliesBottomSheet.append(anomalie)
                                                }
                                            }
                                        }
                                        
                                    }
                                    
                                    NotificationCenter.default.post(name: self.anomalieNotification, object: anomaliesBottomSheet)
                                    onCompletion(true)
                                }
                            }
                        }
                    }
                }
                
                print("MyLocation is \(location)")
                MapsUtils.set(userLocation: location)
                let nc = NotificationCenter.default
                
                if("" != address) {
                    addressFound.firstResult()?.setValue(address.components(separatedBy: ",")[0], forKey: "thoroughfare")
                }
                
                if("" != cp) {
                    addressFound.firstResult()?.setValue(cp, forKey: "postalCode")
                }
                
                nc.post(name: self.addressNotification, object: addressFound.firstResult(), userInfo: ["":""])
            }
        } else {
            // Device en mode déconnecté
            MapsUtils.set(userLocation: location)
            let nc = NotificationCenter.default
            
            //nc.post(name: self.addressNotification, object: location)
            self.mapContainerView.clear()
            NotificationCenter.default.post(name: self.anomalieNotification, object: [Anomalie]())
            
            onCompletion(false)
        }
        
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
    
    /// Methode permettant de vérifier si une adresse a un numero de rue
    ///
    /// - Parameter street: l'adresse complete
    func isAddressHasNumber(adresse: String) -> Bool {
        let str = String(adresse.prefix(1))
        return Int(str) != nil
    }
    
    /// Methode permettant de recherche les informations d'un équipement avec anomalies et mise à jour de la bottomsheet
    ///
    /// - Parameter equipementId: Identifiant de l'équipement
    func updateEquipementSelected(forId equipementId:String) {
        
        // Cas de la sélection d'un TypeEquipement, on affiche les équipements autour de nous
        DispatchQueue.global().async {
            
            RestApiManager.sharedInstance.getIncidentsByEquipement(equipementId: equipementId) { (equipement: Equipement) in
                
                DispatchQueue.main.async {
                    var anomaliesBottomSheet = [AnomalieEquipement]()
                    
                    for anomalie in equipement.anomalies {
                        // Ne pas afficher les anomalies Résolu dans la BottomSheet
                        if anomalie.anomalieStatus != .Resolu {
                            anomaliesBottomSheet.append(anomalie)
                        }
                    }
                    
                    NotificationCenter.default.post(name: self.anomalieNotification, object: anomaliesBottomSheet)
                    
                    self.bottomSheetVC?.animateBottomSheet(withDuration: 0, status: .none)
                    self.bottomSheetVC?.showEquipement(equipement: ReferalManager.shared.getEquipement(forId: equipementId)!)
                    
                }
            }
        }
    }
    
    /// Ajout d'un marker de type Anomalie sur la carte
    ///
    /// - Parameter anomalie: Anomalie - Instance de l'anomalie permettant la création du marker
    func addMarkerAnomalie(anomalie: Anomalie) {
        
        DispatchQueue.main.async {
            let position = CLLocationCoordinate2D(latitude: CLLocationDegrees(anomalie.latitude), longitude: CLLocationDegrees(anomalie.longitude))
            
            let categParentId = ReferalManager.shared.getRootCategorieId(fromCategorieId: anomalie.categorieId)
            
            let markerMap = GMSMarkerAnomalie(position: position)
            markerMap.appearAnimation = .pop
            markerMap.title = anomalie.address
            markerMap.map = self.mapContainerView
            
            markerMap.anomalie = anomalie
            
            if anomalie.anomalieStatus == .Resolu {
                var iconAnomalie = UIImage(named: Constants.Image.anoDoneOther)!
                var iconCateg = UIImage(named: "ano_done_other")
                if anomalie.source == .ramen
                {
                    iconCateg = UIImage(named: "ano_done_1000")
                
                } else {
                    if let anoCateg = UIImage(named: "ano_done_\(categParentId)") {
                        iconCateg = anoCateg
                    }
                }
                
                iconAnomalie = iconCateg!
                
                markerMap.icon = iconAnomalie
                
            } else {
                var iconAnomalie = UIImage(named: Constants.Image.anoOther)!
                var iconCateg = UIImage(named: "ano_other")
                if anomalie.source == .ramen {
                    iconCateg = UIImage(named: "ano_1000")
                    
                } else {
                    if let anoCateg = UIImage(named: "ano_\(categParentId)") {
                        iconCateg = anoCateg
                    }                }
                iconAnomalie = iconCateg!

                markerMap.icon = iconAnomalie
            }
        }
    }
    
    /// Ajout d'un marker de Equipement sur la carte
    ///
    /// - Parameter equipement: Equipement - Instance de l'equipement permettant la création du marker
    func addMarkerEquipement(equipement: Equipement) {
        // Ajout du GMSMarker sur la map
        let markerEquipement = GMSMarkerEquipement()
        markerEquipement.position = CLLocationCoordinate2D(latitude: equipement.latitude, longitude: equipement.longitude)
        markerEquipement.appearAnimation = .pop
        markerEquipement.title = equipement.name
        markerEquipement.map = self.mapContainerView
        markerEquipement.equipement = equipement
        
        let typeEquipement = ReferalManager.shared.getTypeEquipement(forId: equipement.parentId)
        if let iconTypeEquipement = typeEquipement?.icon {
            let iconView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: 50, height: 50)))
            iconView.image = iconTypeEquipement
            iconView.contentMode = .scaleAspectFit
            iconView.clipsToBounds = true
            markerEquipement.iconView = iconView
        } else {
            let iconOther = UIImage(named: Constants.Image.anoOther)!
            markerEquipement.icon = iconOther
        }
    }
}


// MARK: - GMSMapView Delegate
extension MapViewController: GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {

        if case let markerDmr as GMSMarkerAnomalie = marker {
            print("Select marker anomalie id \(markerDmr.anomalie?.id ?? "unkown")")
            self.bottomSheetVC?.showAnomalie(anomalie: markerDmr.anomalie!)
        } else if case let markerEquipement as GMSMarkerEquipement = marker {
            let idEquipement = markerEquipement.equipement?.equipementId
            print("Select marker equipement id \(idEquipement ?? "unkown")")
            self.updateEquipementSelected(forId: idEquipement!)
        }
        
        return true
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        self.bottomSheetVC?.selectAnomalie = nil
        // Par defaut, utilise les coordonnees de la position de la camera
        var latitude = position.target.latitude
        var longitude = position.target.longitude
        // Sinon si uberPin visible, utilise la position du uberPin
        if self.uberPinVisible {
            let uberPointCenter = CGPoint(x: uberPin.center.x, y: uberPin.frame.maxY)
            let uberPointCoordinates = self.mapContainerView.projection.coordinate(for: uberPointCenter)
            
            latitude = uberPointCoordinates.latitude
            longitude = uberPointCoordinates.longitude
        }
        
        if self.uberPinVisible {
            let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            retrieve(currentLocation: coordinates, addMarker: true) { (result: Bool) in }
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        // Function to remove selection in the bottomSheet when Tap into the map
        self.bottomSheetVC?.selectAnomalie = nil
        self.bottomSheetVC?.selectEquipement = nil
        self.bottomSheetVC?.animateBottomSheet(withDuration: 0, status: (self.bottomSheetVC?.currentStatus)!)
    }
    
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
       retrieve(currentLocation: coordinate, addMarker: true) { (result: Bool) in }        
    }
}

// MARK: - CLLocationManager Delegate
extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if (status == CLAuthorizationStatus.authorizedWhenInUse) {
            print("locationManager.didChangeAuthorization : authorizedWhenInUse")
            mapContainerView.isMyLocationEnabled = true
            mapContainerView.settings.myLocationButton = true
            locationManager.startUpdatingLocation();
        } else if (status == CLAuthorizationStatus.denied) {
            print("locationManager.didChangeAuthorization : denied")
            mapContainerView.isMyLocationEnabled = false
            mapContainerView.settings.myLocationButton = false
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if MapsUtils.userLocation() == nil {
            locationManager.stopMonitoringSignificantLocationChanges()
            let coordinates = (locations.last?.coordinate)!
            let cameraUpdate = GMSCameraUpdate.setTarget(coordinates, zoom: Constants.Maps.zoomLevel_50m)
            self.mapContainerView.animate(with: cameraUpdate)

            retrieve(currentLocation: coordinates, addMarker: true) { (result: Bool) in }
            
            locationManager.stopUpdatingLocation()
        }
        
    }
 
}

extension MapViewController: UberDelegate {
    
    func shouldDisplayUberPin(yesWeCan: Bool) {
        if yesWeCan {
            uberPin.image = UIImage(named: Constants.Image.pinNoir)
            uberPin.center = self.mapContainerView.center
            self.view.addSubview(uberPin)
            self.view.bringSubviewToFront(uberPin)
            self.uberPinVisible = true
            uberActionLabel.isHidden = false
        } else {
            uberPin.removeFromSuperview()
            self.uberPinVisible = false
            uberActionLabel.isHidden = true
        }
    }
}


// Handle the user's selection.
extension MapViewController: GMSAutocompleteResultsViewControllerDelegate {
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        searchController?.isActive = false
        
        // Cache le uberPin
        shouldDisplayUberPin(yesWeCan: false)
        
        if let mapView = mapContainerView {
            // Positionnement de la caméra au centre du marker
            let camera = GMSCameraPosition.camera(withLatitude: place.coordinate.latitude,
                                                  longitude: place.coordinate.longitude,
                                                  zoom: Constants.Maps.zoomLevel_50m)
            mapView.animate(to: camera)
        }
        // Recherche de l'adresse et des anomalies a proximite
        
        var numRue = ""
        var rue = ""
        var cp = ""
        
        for component in place.addressComponents! {
            if component.types[0] == "street_number" {
                numRue = component.name
            }
            if component.types[0] == "route" {
                rue = component.name
            }
            if component.types[0] == "postal_code" {
                cp = component.name
            }
        }
        let adresse = numRue + " " + rue + ", " + cp + " Paris, France"
        
        retrieve(currentLocation: place.coordinate, addMarker: true, address: adresse, cp: cp) { (result: Bool) in }
        
    }
    
    func centerCameraToPosition(currentLocation location:CLLocationCoordinate2D) {
        if let mapView = mapContainerView {
            // Positionnement de la caméra au centre du marker
            let camera = GMSCameraPosition.camera(withLatitude: location.latitude,
                                                  longitude: location.longitude,
                                                  zoom: Constants.Maps.zoomLevel_50m)
            mapView.animate(to: camera)
        }
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didFailAutocompleteWithError error: Error){
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    
}

extension MapViewController: EquipementDelegate {
    func didSelectEquipementAt(equipement: Equipement) {
        customSearchController?.isActive = false
        if let mapView = mapContainerView {
            
            // Positionnement de la caméra au centre du marker
            let camera = GMSCameraPosition.camera(withLatitude: equipement.latitude,
                                                  longitude: equipement.longitude,
                                                  zoom: Constants.Maps.zoomLevel_50m)
            mapView.animate(to: camera)
        }
        
        if Reach().connectionStatus() {
            self.updateEquipementSelected(forId: equipement.equipementId)
            // on affiche le marker de l'equipement
            self.addMarkerEquipement(equipement: equipement)
        } else {
            // Mode hors connexion, on affiche uniquement le marker de l'equipement
            self.addMarkerEquipement(equipement: equipement)
            // Affiche des informations de l'équipement sélectionné
            self.bottomSheetVC?.showEquipement(equipement: ReferalManager.shared.getEquipement(forId:  equipement.equipementId)!)
        }
    }
}

class SearchBarContainerView: UIView {
    
    let searchBar: UISearchBar
    
    init(customSearchBar: UISearchBar) {
        searchBar = customSearchBar
        super.init(frame: CGRect.zero)
        
        addSubview(searchBar)
    }
    
    override convenience init(frame: CGRect) {
        self.init(customSearchBar: UISearchBar())
        self.frame = frame
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        searchBar.frame = bounds
    }
}
