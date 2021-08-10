//
//  BottomSheetViewController.swift
//  DansMaRue
//
//  Created by Maxime Bureau on 13/04/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import SDWebImage
import TTGSnackbar

protocol UberDelegate: NSObjectProtocol {
    func shouldDisplayUberPin(yesWeCan: Bool)
}

class BottomSheetViewController: UIViewController, UITextFieldDelegate {

    //MARK: - IBOutlets
    @IBOutlet weak var bottomSheetTableView: UITableView!
    
    //MARK: - Properties
    let fullView: CGFloat = 0
    var partialView: CGFloat = 600
    weak var uberDelegate: UberDelegate?
    var uberDisplayed = false
    var mapsUtils : MapsUtils?
    var selectedAddress: GMSAddress?
    var selectedCoordinates : CLLocationCoordinate2D?
    
    var otherCellDisplay:Bool = false
    var buttomSheetFullView:Bool = false
    var selectAnomalie: Anomalie?
    var selectEquipement: Equipement? {
        didSet {
            ContextManager.shared.equipementSelected = selectEquipement
            if let equipement = selectEquipement {
                otherMalfunctionsArray = equipement.anomalies
            } else {
                otherMalfunctionsArray = [Anomalie]()
            }
        }
    }
    
    weak var delegate: MapViewController!
    let anomalieNotification = Notification.Name(rawValue:Constants.NoticationKey.anomaliesChanged)
    
    var hidemanageFavoriteBtns = false

    var addAnomalyBtn: UIButton?
    var searchAnomalyBtn: UIButton?
    var followAnomalyBtn: UIButton?
    var unfollowAnomalyBtn: UIButton?
    var congratulateAnomalyBtn: UIButton?
    var addFavoriteBtn: UIButton?
    var removeFavoriteBtn: UIButton?
    
    let imgAddAnomaly = UIImage(named: Constants.Image.createAnomalie)
    let imgAddAnomalySelected = UIImage(named: Constants.Image.createAnomalieSelected)
    let imgSearchAnomalie = UIImage(named: Constants.Image.searchAnomalie)
    let imgFollowAnomaly = UIImage(named:  Constants.Image.follow)
    let imgFollowAnomalySelected = UIImage(named:  Constants.Image.followSelected)
    let imgFollowAnomalyDisabled = UIImage(named:  Constants.Image.followDisabled)
    let imgUnfollowAnomaly = UIImage(named:  Constants.Image.unfollow)
    let imgUnfollowAnomalySelected = UIImage(named:  Constants.Image.unfollowSelected)
    let imgCongratulateAnomaly = UIImage(named:  Constants.Image.congratulate)
    let imgCongratulateAnomalySelected = UIImage(named:  Constants.Image.congratulateSelected)
    let imgCongratulateAnomalyDisabled = UIImage(named:  Constants.Image.congratulateDisabled)
    let imgAddAddressFavorite = UIImage(named: Constants.Image.favoritePlus)
    let imgRemoveddressFavorite = UIImage(named: Constants.Image.favoriteCheck)

    var otherMalfunctionsArray = [Anomalie]()
    var currentStatus: BottomSheetStatus = .none


    
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(BottomSheetViewController.panGesture))
        gesture.delegate = self
        view.addGestureRecognizer(gesture)
        
        let nc = NotificationCenter.default
        nc.addObserver(forName:NSNotification.Name(rawValue: Constants.NoticationKey.addressNotification), object:nil, queue:nil, using:changeAddress)
        nc.addObserver(forName:NSNotification.Name(rawValue: Constants.NoticationKey.anomaliesChanged), object:nil, queue:nil, using:reloadAnomalies)
        
        nc.addObserver(forName:Notification.Name(rawValue: Constants.NoticationKey.pushNotification), object:nil, queue:nil, using:notificationToDisplayAnomalie)
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if buttomSheetFullView {
            animateBottomSheet(withDuration: 0, status: .full)
        } else if otherCellDisplay {
            animateBottomSheet(withDuration: 0, status: .selected)
        } else {
            animateBottomSheet(withDuration: 0, status: .none)
        }
        
        if addAnomalyBtn == nil {
            addAnomalyBtn = self.initButton()
            addAnomalyBtn?.setImage(imgAddAnomaly, for: .normal)
            addAnomalyBtn?.addTarget(self, action: #selector(self.tapAddAnomaly(sender:)), for: .touchUpInside)
            addAnomalyBtn?.accessibilityLabel = Constants.LabelMessage.addAnomaly
            
            self.view.addSubview(addAnomalyBtn!)
        }
        
        if searchAnomalyBtn == nil {
            searchAnomalyBtn = self.initSearchButton()
            searchAnomalyBtn?.setImage(imgSearchAnomalie, for: .normal)
            searchAnomalyBtn?.addTarget(self, action: #selector(self.tapSearchAnomaly(sender:)), for: .touchUpInside)
            searchAnomalyBtn?.accessibilityLabel = Constants.LabelMessage.searchAnomaly
            
            self.view.addSubview(searchAnomalyBtn!)
        }
        
        if addFavoriteBtn == nil {
            addFavoriteBtn = initButtonManageFavorite(isAddFavorite: true)
            addFavoriteBtn?.setImage(imgAddAddressFavorite, for: .normal)
            addFavoriteBtn?.accessibilityLabel = Constants.LabelMessage.addAdresseFavorite
            
            let tapGestureRecognizer = MyTapGesture(target: self, action: #selector(self.addOrRemoveFavorite(recognizer:)))
            tapGestureRecognizer.addFavorite = true
            addFavoriteBtn?.addGestureRecognizer(tapGestureRecognizer)
            
            self.view.addSubview(addFavoriteBtn!)
        }
        
        if removeFavoriteBtn == nil {
            removeFavoriteBtn = initButtonManageFavorite(isAddFavorite: true)
            removeFavoriteBtn?.setImage(imgRemoveddressFavorite, for: .normal)
            removeFavoriteBtn?.accessibilityLabel = Constants.LabelMessage.removeAdresseFavorite
            
            let tapGestureRecognizer = MyTapGesture(target: self, action: #selector(self.addOrRemoveFavorite(recognizer:)))
            tapGestureRecognizer.addFavorite = false
            removeFavoriteBtn?.addGestureRecognizer(tapGestureRecognizer)
            
            self.view.addSubview(removeFavoriteBtn!)
        }
        
        if followAnomalyBtn == nil {
            followAnomalyBtn = self.initButton()
            followAnomalyBtn?.setImage(imgFollowAnomaly, for: .normal)
            followAnomalyBtn?.setImage(imgFollowAnomalyDisabled, for: .disabled)
            followAnomalyBtn?.addTarget(self, action: #selector(self.tapFollowAnomaly(sender:)), for: .touchUpInside)
            followAnomalyBtn?.isHidden = true
            followAnomalyBtn?.accessibilityLabel = Constants.LabelMessage.followAnomaly
            
            self.view.addSubview(followAnomalyBtn!)
        }
        
        if unfollowAnomalyBtn == nil {
            unfollowAnomalyBtn = self.initButton()
            unfollowAnomalyBtn?.setImage(imgUnfollowAnomaly, for: .normal)
            unfollowAnomalyBtn?.addTarget(self, action: #selector(self.tapUnfollowAnomaly(sender:)), for: .touchUpInside)
            unfollowAnomalyBtn?.isHidden = true
            unfollowAnomalyBtn?.accessibilityLabel = Constants.LabelMessage.unfollowAnomaly
            
            self.view.addSubview(unfollowAnomalyBtn!)
        }
        
        if congratulateAnomalyBtn == nil {
            congratulateAnomalyBtn = self.initButton()
            congratulateAnomalyBtn?.setImage(imgCongratulateAnomaly, for: .normal)
            congratulateAnomalyBtn?.setImage(imgCongratulateAnomalyDisabled, for: .disabled)
            congratulateAnomalyBtn?.addTarget(self, action: #selector(self.tapCongratulateAnomaly(sender:)), for: .touchUpInside)
            congratulateAnomalyBtn?.isHidden = true
            congratulateAnomalyBtn?.accessibilityLabel = Constants.LabelMessage.congratulateAnomaly
            
            self.view.addSubview(congratulateAnomalyBtn!)
        }
    }
   
    func initButton() -> UIButton {
        let button = UIButton(frame: CGRect(x:self.view.frame.width - 70, y:-30, width:65, height:65))
        button.backgroundColor = .black
        button.layer.borderWidth = 0
        button.tintColor = .white
        button.backgroundColor = .clear
        button.imageEdgeInsets = UIEdgeInsets.init(top: -10, left: -10, bottom: -10, right: -10)
        
        return button
    }
    
    func initSearchButton() -> UIButton {
        let button = UIButton(frame: CGRect(x:self.view.frame.width - 70, y:-170, width:65, height:65))
        button.isUserInteractionEnabled = true
        
        return button
    }
    
    //MARK: - Bottom sheet methods
    @objc func panGesture(_ recognizer: UIPanGestureRecognizer) {
        
        let translation = recognizer.translation(in: self.view)
        let velocity = recognizer.velocity(in: self.view)
        let y = self.view.frame.minY
        if ( y + translation.y >= fullView) && (y + translation.y <= partialView ) {
            self.view.frame = CGRect(x: 0, y: y + translation.y, width: view.frame.width, height: view.frame.height)
            recognizer.setTranslation(CGPoint.zero, in: self.view)
        }
        
        if recognizer.state == .ended {
            var duration =  velocity.y < 0 ? Double((y - fullView) / -velocity.y) : Double((partialView - y) / velocity.y )
            
            duration = duration > 1.3 ? 1 : duration
            
            UIView.animate(withDuration: duration, delay: 0.0, options: [.allowUserInteraction], animations: {
                if  velocity.y >= 0 {
                    self.animateBottomSheet(withDuration: duration, status: .none)
                } else {
                    self.animateBottomSheet(withDuration: duration, status: .full)
                }
                
                
            }, completion: nil)
        }
    }
    
    //MARK: - Update data
    func changeAddress(notification:Notification)  {
        if let address = notification.object as? GMSAddress {
            // Mode online, on recupere une GMSAddress
            selectedAddress = address
            selectedCoordinates = nil
        } else if let coordinates = notification.object as? CLLocationCoordinate2D {
            // Mode offline, on recupere des coordonnees
            selectedCoordinates = coordinates
            selectedAddress = nil
        }
        
        selectAnomalie = nil
        selectEquipement = nil
        animateBottomSheet(withDuration: 0, status: currentStatus)
        
        self.bottomSheetTableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
    }
    
    
    func reloadAnomalies(notification:Notification)  {
        otherMalfunctionsArray = (notification.object as? [Anomalie])!
        self.bottomSheetTableView.reloadData()
    }
    
    func showAnomalie(anomalie: Anomalie) {
        self.selectAnomalie = anomalie
        // Update first row
        self.bottomSheetTableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        if otherCellDisplay {
            self.bottomSheetTableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
        }
        
        addAnomalyBtn?.isHidden = true
        congratulateAnomalyBtn?.isEnabled = true
        hidemanageFavoriteBtns = true
        
        if selectAnomalie?.anomalieStatus == .Resolu {
            followAnomalyBtn?.isHidden = true
            unfollowAnomalyBtn?.isHidden = true
            congratulateAnomalyBtn?.isHidden = false
            
        } else {
            followAnomalyBtn?.isHidden = anomalie.isIncidentFollowedByUser
            unfollowAnomalyBtn?.isHidden = !anomalie.isIncidentFollowedByUser
            congratulateAnomalyBtn?.isHidden = true
            
            followAnomalyBtn?.isEnabled = anomalie.source == .dmr
            unfollowAnomalyBtn?.isEnabled = anomalie.source == .dmr
        }
    }
    
    func showEquipement(equipement: Equipement)  {
        self.selectEquipement = equipement
        // Update first row
        self.bottomSheetTableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        if otherCellDisplay {
            self.bottomSheetTableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
        }
        
        addAnomalyBtn?.isHidden = false
        
        followAnomalyBtn?.isHidden = true
        unfollowAnomalyBtn?.isHidden = true
        congratulateAnomalyBtn?.isHidden = true
    }
    
    //MARK: - Other functions
    func getDetailsAnomalies(anomalie: Anomalie, source: AnomalieSource) {
        if let anoEquipement = anomalie as? AnomalieEquipement {
            DispatchQueue.global().async {
                
                RestApiManager.sharedInstance.getIncidentEquipementById(idSignalement: anoEquipement.id){ (anomalie: AnomalieEquipement) in
                    DispatchQueue.main.async {
                        let anomalyDetailStoryboard = UIStoryboard(name: Constants.StoryBoard.detailAnomaly, bundle: nil)
                        let anomalyDetailViewController = anomalyDetailStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.detailAnomaly) as! AnomalyDetailViewController
                        anomalyDetailViewController.selectedAnomaly = anomalie
                        // Gestion du mode d'affichage de l'écran de détail en fonction du status de l'anomalie
                        anomalyDetailViewController.currentAnomalyState = (anomalie.anomalieStatus == .Resolu ? .solved : .notsolved)
                        self.present(anomalyDetailViewController, animated: true, completion: nil)
                        anomalyDetailViewController.customNavigationDelegate = self
                        
                    }
                }
            }
        } else {
            //Si ano DMR, on affiche le détail
            if source == AnomalieSource.dmr {
                DispatchQueue.global().async {
                    RestApiManager.sharedInstance.getIncidentById(idSignalement: anomalie.id, source: source){ (anomalie: Anomalie) in
                        DispatchQueue.main.async {
                            let anomalyDetailStoryboard = UIStoryboard(name: Constants.StoryBoard.detailAnomaly, bundle: nil)
                            let anomalyDetailViewController = anomalyDetailStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.detailAnomaly) as! AnomalyDetailViewController
                            anomalyDetailViewController.selectedAnomaly = anomalie
                            // Gestion du mode d'affichage de l'écran de détail en fonction du status de l'anomalie
                            anomalyDetailViewController.currentAnomalyState = (anomalie.anomalieStatus == .Resolu ? .solved : .notsolved)
                            self.present(anomalyDetailViewController, animated: true, completion: nil)
                            anomalyDetailViewController.customNavigationDelegate = self
                            
                        }
                    }
                }
            }
        }
        
    }
    
    @objc func addOrRemoveFavorite(recognizer: MyTapGesture){
        var favorite : [String] = getFavoritesAddress()
        //Récupération de l'adresse et des coordonées
        let addressWithCoordonate = MapsUtils.fullAddress() + Constants.Key.separatorAdresseCoordonate + String(MapsUtils.userLocation()!.latitude) + "-" + String(MapsUtils.userLocation()!.longitude)
        
        //Ajout d'une adresse aux favoris
        if(recognizer.addFavorite) {
            //Vérification si l'adresse est dans Paris
            if MapsUtils.postalCode.hasPrefix(Constants.prefix75) {
                favorite.append(addressWithCoordonate)
            } else {
                //Si hors de Paris, affichage d'une popup d'erreur
                let alertController = UIAlertController(title: Constants.AlertBoxTitle.adresseHorsParis, message: Constants.AlertBoxMessage.adresseHorsParis, preferredStyle: .alert)
                
                let OKAction = UIAlertAction(title: Constants.AlertBoxTitle.ok, style: UIAlertAction.Style.default, handler: nil)
                alertController.addAction(OKAction)
                
                // Present Dialog message
                self.present(alertController, animated: true, completion:nil)
            }
        } else {
            //Suppression si adresse et coordonnées égaux
            if let index = favorite.index(of: addressWithCoordonate) {
                favorite.remove(at: index)
            } else {
                //Suppression si coordonnées ou adresse égaux
                for fav in favorite {
                    var isAlreadyInFavorites = false
                    let favArr = fav.components(separatedBy: Constants.Key.separatorAdresseCoordonate)
                    
                    //Vérification sur le nom de l'adresse
                    if favArr[0] == MapsUtils.fullAddress() {
                        isAlreadyInFavorites = true
                    }
                    
                    //Vérification sur les coordonnées
                    if String(MapsUtils.userLocation()!.latitude) + "-" + String(MapsUtils.userLocation()!.longitude) == favArr[1] {
                        isAlreadyInFavorites = true
                    }
                    
                    if isAlreadyInFavorites {
                        let index = favorite.index(of: fav)
                        favorite.remove(at: index!)
                    }
                }
            }
        }
        let defaults = UserDefaults.standard
        defaults.set(favorite, forKey: "favoritesAddressArray")
        bottomSheetTableView.reloadData()
    }
    
    //Retourne les adresses favorites de l'utilisateur
    func getFavoritesAddress() -> [String] {
        let defaults = UserDefaults.standard
        var favorite : [String] = []
        
        //Récupération des favoris dans les UserDefaults
        if let favoritesArray = defaults.stringArray(forKey: "favoritesAddressArray") {
            favorite = favoritesArray
        }
        return favorite
    }
    
    @objc func displaySelectedAnomaly(_ sender:AnyObject){
        if let myAnomalie = selectAnomalie {
            getDetailsAnomalies(anomalie: myAnomalie, source: myAnomalie.source)
        }
    }
    
    @objc func hideUberPin(_ sender:AnyObject){
        setUberPinHidden(true)
    }
    
    func setUberPinHidden(_ isHidden: Bool) {
        if !isHidden {
            uberDelegate?.shouldDisplayUberPin(yesWeCan: true)
            uberDisplayed = true
            animateBottomSheet(withDuration: 0.3, status: .none)
        } else {
            uberDelegate?.shouldDisplayUberPin(yesWeCan: false)
            uberDisplayed = false
        }
    }
    
    func notificationToDisplayAnomalie(notification:Notification) {
        // Réception d'une notification push pour afficher le détail d'une anomalie
        if let anomalie = notification.object as? Anomalie {
            self.getDetailsAnomalies(anomalie: anomalie, source: .dmr)
        }
    }
    
    /// Animation de l'affichage de la BottomSheet en fonction du status
    ///
    /// - Parameters:
    ///   - duration: delay de l'animation
    ///   - status: status d'affichage
    func animateBottomSheet(withDuration duration: TimeInterval, status: BottomSheetStatus) {
        switch status {
        case .selected:
            currentStatus = .selected
            otherCellDisplay = true
            buttomSheetFullView = false
            
            if let anomalie = selectAnomalie {
                // Cas d'une anomalie outdoor
                if selectAnomalie?.anomalieStatus == .Resolu {
                    followAnomalyBtn?.isHidden = true
                    unfollowAnomalyBtn?.isHidden = true
                    congratulateAnomalyBtn?.isHidden = false
                    
                } else {
                    followAnomalyBtn?.isHidden = anomalie.isIncidentFollowedByUser
                    unfollowAnomalyBtn?.isHidden = !anomalie.isIncidentFollowedByUser
                    congratulateAnomalyBtn?.isHidden = true
                    
                    followAnomalyBtn?.isEnabled = anomalie.source == .dmr
                    unfollowAnomalyBtn?.isEnabled = anomalie.source == .dmr
                }
                
            } else {
                // Cas d'une anomalie indoor ou pas d'anomalie sélectionnée
                addAnomalyBtn?.isHidden = false
                followAnomalyBtn?.isHidden = true
                unfollowAnomalyBtn?.isHidden = true
                congratulateAnomalyBtn?.isHidden = true
                hidemanageFavoriteBtns = false
            }
            
            addAnomalyBtn?.setImage(imgAddAnomalySelected, for: .normal)
            followAnomalyBtn?.setImage(imgFollowAnomalySelected, for: .normal)
            unfollowAnomalyBtn?.setImage(imgUnfollowAnomalySelected, for: .normal)
            congratulateAnomalyBtn?.setImage(imgCongratulateAnomalySelected, for: .normal)

            UIView.animate(withDuration: duration) { [weak self] in
                let frame = self?.view.frame
                self?.view.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - 255, width: frame!.width, height: frame!.height)
            }
        case .full:
            currentStatus = .full
            otherCellDisplay = true
            buttomSheetFullView = true
            
            // En mode full, on cache le uberPin mais on conserve son status pour le remettre en sortie du mode full
            let saveUberStatus = uberDisplayed
            setUberPinHidden(true)
            uberDisplayed = saveUberStatus
            
            // Cache tous les boutons en plein écran
            addAnomalyBtn?.isHidden = true
            followAnomalyBtn?.isHidden = true
            unfollowAnomalyBtn?.isHidden = true
            congratulateAnomalyBtn?.isHidden = true
            hidemanageFavoriteBtns = true
            
            UIView.animate(withDuration: duration) { [weak self] in
                let frame = self?.view.frame
                self?.view.frame = CGRect(x: 0, y: (self?.fullView)!, width: frame!.width, height: frame!.height)
            }
        default:
            // Dans le cas où on vient du plein écran. On reprend le status du uberPin.
            if currentStatus == .full {
                currentStatus = .none
                setUberPinHidden(!uberDisplayed)
            }
            currentStatus = .none
            otherCellDisplay = false
            buttomSheetFullView = false
            selectAnomalie = nil
            //selectEquipement = nil

            addAnomalyBtn?.isHidden = false
            followAnomalyBtn?.isHidden = true
            unfollowAnomalyBtn?.isHidden = true
            congratulateAnomalyBtn?.isHidden = true
            hidemanageFavoriteBtns = false
            
            addAnomalyBtn?.setImage(imgAddAnomaly, for: .normal)
            followAnomalyBtn?.setImage(imgFollowAnomaly, for: .normal)
            unfollowAnomalyBtn?.setImage(imgUnfollowAnomaly, for: .normal)
            congratulateAnomalyBtn?.setImage(imgCongratulateAnomaly, for: .normal)
            
            if let anomalie = selectAnomalie {
                followAnomalyBtn?.isEnabled = anomalie.source == .dmr
                unfollowAnomalyBtn?.isEnabled = anomalie.source == .dmr
            }
            
            UIView.animate(withDuration: duration) { [weak self] in
                let frame = self?.view.frame
                self?.view.frame = CGRect(x: 0, y: (self?.partialView)!, width: frame!.width, height: frame!.height + 40)
            }
        }
        
        self.navigationController?.setNavigationBarHidden(buttomSheetFullView, animated: true)
        self.bottomSheetTableView.reloadData()
    }
    
    func displayAddAnomalyView() {
        // Outdoor : Si utilisateur connecté et en dehors de Paris, alors affiche message d'erreur
        if Reach().connectionStatus() && !MapsUtils.postalCode.hasPrefix(Constants.prefix75) && ContextManager.shared.typeContribution == .outdoor {
            let alertController = UIAlertController(title: Constants.AlertBoxTitle.adresseInvalide, message: Constants.AlertBoxMessage.adresseInvalide, preferredStyle: .alert)
            // Create OK button
            let OKAction = UIAlertAction(title: Constants.AlertBoxTitle.ok, style: .default) {
                (action:UIAlertAction!) in
            }
            alertController.addAction(OKAction)
            // Present Dialog message
            self.present(alertController, animated: true, completion:nil)
        } else {
            let addAnomalyStoryboard = UIStoryboard(name: Constants.StoryBoard.addAnomaly, bundle: nil)
            let addAnomalyViewController = addAnomalyStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.addAnomaly) as! AddAnomalyViewController
            addAnomalyViewController.typeContribution = ContextManager.shared.typeContribution
            self.navigationController?.navigationBar.tintColor = UIColor.white
            self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue:UIColor.white])
            self.navigationController?.pushViewController(addAnomalyViewController, animated: true)
        }
        
    }

    @objc func tapAddAnomaly(sender: UIButton) {
        if ContextManager.shared.typeContribution == .indoor {
            if ContextManager.shared.equipementSelected == nil {
                let alertController = UIAlertController.init(title: Constants.AlertBoxTitle.attention, message: ContextManager.shared.typeEquipementSelected?.msgAlertNoEquipement, preferredStyle: .alert)
                
                let OKAction = UIAlertAction(title: Constants.AlertBoxTitle.ok, style: .default) { (action:UIAlertAction!) in
                }
                
                alertController.addAction(OKAction)
                self.present(alertController, animated: true, completion: nil)
            } else {
                displayAddAnomalyView()
            }
        } else {
            displayAddAnomalyView()
        }
    }
    
    @objc func tapSearchAnomaly(sender: UIButton) {
        showSearchPopup(erreur: "")
    }
    
    func showSearchPopup ( erreur : String) {
        //Popup de recherche
        
        var message = ""
        //Ajout du message d'erreur si il y en a un
        if erreur != "" {
            message = "\n" + erreur + "\n\n\n"
        }
        let alertController = UIAlertController(title: Constants.AlertBoxTitle.searchAnomaly, message: message + Constants.AlertBoxMessage.searchAnomaly, preferredStyle: .alert)
        
        //Textfield pour la saisie du numéro
        alertController.addTextField { [weak self] (textField) in
           textField.delegate = self
            textField.placeholder = "n° : "
        }
        
        // Boutton rechercher
        let SearchAction = UIAlertAction.init(title: Constants.LabelMessage.searchAnomaly, style: .default, handler: { (action: UIAlertAction!) in
            let textField = alertController.textFields![0] as UITextField
            
            //Recherche
            self.searchAnomalyByNumber(number: textField.text!)
        })
        
        // Boutton annuler
        let cancelBtn = UIAlertAction(title:"Annuler" , style: .default, handler: {(_ action: UIAlertAction) -> Void in
        })
        
        alertController.addAction(SearchAction)
        alertController.addAction(cancelBtn)
        
         self.present(alertController, animated: true, completion:nil)
    }
    
    /// Méthode de recherche d'anomalie par numéro
    ///
    /// - Parameters:
    ///   - number: numéro de l'anomalie
    func searchAnomalyByNumber (number: String) {
        let pattern = "[BSGAbsga][2][0-9]{3}[A-La-l][0-9]+$"
        let result = number.range(of: pattern, options:.regularExpression)
        
        //Le format ne correspond pas
        if result == nil {
            //Affichage du message d'erreur
            print("Erreur lors la saisie du numéro")
            showSearchPopup(erreur: "Numéro incorrect")
        } else {
            //Lancement de la recherche
            RestApiManager.sharedInstance.getIncidentsByNumber(number: number) { (jsonDict) in
                if let answer = jsonDict["answer"]?.dictionary {
                    if let incident = answer["incident"]?.arrayValue {
                        let marker = incident [0]
                        RestApiManager.sharedInstance.getIncidentById(idSignalement: marker["id"].stringValue, source: AnomalieSource.dmr){ (anomalie: Anomalie) in
                            DispatchQueue.main.async {
                                var anomaliesBottomSheet = [Anomalie]()
                                DispatchQueue.main.async {
                                        // Ajout du GMSMarker sur la map
                                        self.delegate.addMarkerAnomalie(anomalie: anomalie)
                                        
                                        if anomalie.anomalieStatus != .Resolu && !anomaliesBottomSheet.contains(anomalie) {
                                            anomaliesBottomSheet.append(anomalie)
                                        }
                                    NotificationCenter.default.post(name: self.anomalieNotification, object: anomaliesBottomSheet)
                                    
                                    //Zoom sur l'anomalie
                                    let currentLocation = CLLocationCoordinate2D(latitude: anomalie.latitude, longitude: anomalie.longitude)
                                    self.delegate.mapContainerView.clear()
                                    self.delegate.centerCameraToPosition(currentLocation: currentLocation)
                                }
                            }
                        }
                    }
                }
                else if let answer = jsonDict["error_message"]?.stringValue {
                    self.showSearchPopup(erreur: answer)
                }
                else if let answer = jsonDict["erreurBO"]?.stringValue {
                    self.showSearchPopup(erreur: answer)
                }
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
        replacementString string: String) -> Bool {
        return textField.text!.count <= 12 || ( string == "")
    }
 
    @objc func tapFollowAnomaly(sender: UIButton) {
        if (!User.shared.isLogged){
            //Redirection vers le Compte Parisien
            let compteParisienVC = UIStoryboard(name: Constants.StoryBoard.compteParisien, bundle: nil).instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.compteParisien)
            self.navigationController?.present(compteParisienVC, animated: true)
        } else {
            if let anomalie = selectAnomalie {
                DispatchQueue.global().async {
                    RestApiManager.sharedInstance.follow(anomalie: anomalie, onCompletion: { (result: Bool) in
                        if result {
                            //Mise à jour de l'UI
                            DispatchQueue.main.async {
                                anomalie.isIncidentFollowedByUser = true
                                self.followAnomalyBtn?.isHidden = true
                                self.unfollowAnomalyBtn?.isHidden = false
                                
                                let snackbar = TTGSnackbar(message: Constants.AlertBoxMessage.followMalfunction, duration: .middle)
                                snackbar.messageTextAlign = .center
                                snackbar.messageTextFont = UIFont.init(name: Constants.fontDmr, size: 14)!
                                snackbar.show()
                            }
                            
                        }
                    })
                }
            }
            
        }
    }
    
    @objc func tapUnfollowAnomaly(sender: UIButton) {
        if let anomalie = selectAnomalie {
            DispatchQueue.global().async {
                RestApiManager.sharedInstance.unfollow(anomalie: anomalie, onCompletion: { (result: Bool) in
                    if result {
                        //Mise à jour de l'UI
                        DispatchQueue.main.async {
                            anomalie.isIncidentFollowedByUser = false
                            self.followAnomalyBtn?.isHidden = false
                            self.unfollowAnomalyBtn?.isHidden = true
                            
                            let snackbar = TTGSnackbar(message: Constants.AlertBoxMessage.unfollowMalfunction, duration: .middle)
                            snackbar.messageTextAlign = .center
                            snackbar.messageTextFont = UIFont.init(name: Constants.fontDmr, size: 14)!
                            snackbar.show()
                        }
                        
                    }
                })
            }
        }
        
    }
    
    @objc func tapCongratulateAnomaly(sender: UIButton) {
        if(!User.shared.isLogged){
            let compteParisienVC = UIStoryboard(name: Constants.StoryBoard.compteParisien, bundle: nil).instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.compteParisien)
            self.navigationController?.present(compteParisienVC, animated: true)
        } else {
            if let anomalie = selectAnomalie {
                var cancelAction = false
                self.congratulateAnomalyBtn?.isEnabled = false
                
                let snackbar = TTGSnackbar.init(message: Constants.AlertBoxMessage.congratulate, duration: .middle, actionText: Constants.AlertBoxTitle.annuler)
                { (snackbar) -> Void in
                    self.congratulateAnomalyBtn?.isEnabled = true
                    cancelAction = true
                }
                snackbar.actionTextColor = UIColor.pinkDmr()
                snackbar.actionTextFont = UIFont(name: Constants.fontDmr, size: 14.0)!
                snackbar.messageTextFont = UIFont(name: Constants.fontDmr, size: 15.0)!
                snackbar.messageTextAlign = NSTextAlignment.center
                
                //Callback si l'utilisateur ne fais pas "annuler"
                snackbar.dismissBlock = {
                    
                    (snackbar: TTGSnackbar) -> Void in
                    if !cancelAction {
                        DispatchQueue.global().async {
                            
                            RestApiManager.sharedInstance.congratulateAnomalie(anomalie: anomalie, onCompletion: { (result: Bool) in
                                
                                if result {
                                    //Mise à jour de l'UI
                                    DispatchQueue.main.async {
                                        self.congratulateAnomalyBtn?.isEnabled = false
                                    }
                                }
                            })
                        }
                    }
                    
                    
                }
                snackbar.show()
            }
        }
        
     }
}

/// Enumération contenant les différents status d'affichage de la BottomSheet
///
/// - none: BottomSheet visible en pied de page
/// - selected: Affichage partiel de la BottomSheet lors de la sélection de la première cellule
/// - full: Affichage de la BottomSheet en plein écran
enum BottomSheetStatus {
    case none
    case selected
    case full
}

extension BottomSheetViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            animateBottomSheet(withDuration: 0.3, status: (otherCellDisplay ? .none : .selected))
            
        case 1:
            if selectAnomalie == nil && selectEquipement == nil {
                setUberPinHidden(uberDisplayed)
            } else {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                self.displayAddAnomalyView()
            }
        default:
            let anomalie = otherMalfunctionsArray[indexPath.row - 3]
            self.getDetailsAnomalies(anomalie: anomalie, source: anomalie.source)
            
        }
        
    }
    
}

extension BottomSheetViewController: UITableViewDataSource {
    
    struct RowId {
        static let description = 0
        static let uberMode = 1
        static let labelAnomaly = 2
        static let other = 3
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case RowId.description:
            return 100
        case RowId.uberMode:
            // Cette ligne est visible uniquement pour les anomalies outdoor ou lors de la sélection d'un équipement indoor
            return (ContextManager.shared.typeContribution == .indoor && ContextManager.shared.equipementSelected == nil) ? 0 : 68
        case RowId.labelAnomaly:
            return 48
        default:
            return 90
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if otherCellDisplay {
            return 3 + self.otherMalfunctionsArray.count
        } else {
            return 1
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var customCell = tableView.dequeueReusableCell(withIdentifier: "localization_cell")
        
        switch indexPath.row {
        case RowId.description:
            customCell = tableView.dequeueReusableCell(withIdentifier: "localization_cell")
            
            let geolocMainTitle = customCell?.viewWithTag(102) as! UILabel
            let geolocSubtitle = customCell?.viewWithTag(103) as! UILabel

            // Hidden by default
            geolocSubtitle.isHidden = true
            
            if ContextManager.shared.typeContribution == .outdoor {
                showDetailAnomalie(forCell: customCell!)
            } else if ContextManager.shared.typeContribution == .indoor {
                showDetailEquipement(forCell: customCell!)
            }
            
            if self.otherCellDisplay {
                customCell?.backgroundColor = UIColor.pinkDmr()
                geolocMainTitle.textColor = .white
                geolocSubtitle.textColor = UIColor.lightGreyDmr()
            } else {
                customCell?.backgroundColor = .white
                geolocMainTitle.textColor = .black
                geolocSubtitle.textColor = UIColor.lightGreyDmr()
            }
            
            if buttomSheetFullView {
                let cellFrame = customCell?.frame
                let titleLabel:UILabel = UILabel()
                titleLabel.frame = CGRect(x: 0, y: 10, width: self.view.frame.width, height: (cellFrame?.height)!)
                titleLabel.numberOfLines = 2
                titleLabel.lineBreakMode = .byWordWrapping
                titleLabel.textColor = .white
                titleLabel.font = UIFont.init(name: Constants.fontDmr, size: 16)
                titleLabel.tag = 999
                titleLabel.textAlignment = .center
                titleLabel.text = MapsUtils.addressLabel
                
                if ContextManager.shared.typeContribution == .outdoor || self.selectEquipement == nil {
                    titleLabel.text = MapsUtils.addressLabel + "\n" + MapsUtils.boroughLabel
                } else if ContextManager.shared.typeContribution == .indoor {
                    titleLabel.text = selectEquipement?.name
                }
                
                customCell?.addSubview(titleLabel)
                
                // Ajout du bouton de fermeture
                let closeBtn = UIButton(frame: CGRect(x:15, y:(customCell?.frame.height)! / 2 - 5, width:30, height:30))
                closeBtn.backgroundColor = .clear
                closeBtn.layer.borderWidth = 0
                closeBtn.setImage(UIImage(named: Constants.Image.iconExit), for: .normal)
                closeBtn.tintColor = .white
                closeBtn.addTarget(self, action: #selector(self.closeBtnTouchUp(_:)), for: .touchUpInside)
                closeBtn.accessibilityLabel = Constants.LabelMessage.reduceBottomSheet
                customCell?.addSubview(closeBtn)
                
                geolocSubtitle.isHidden = true
                
            }
            
        case RowId.uberMode:
            customCell = tableView.dequeueReusableCell(withIdentifier: "preciser_position_cell")
            let precisionLabel = customCell?.viewWithTag(201) as! UILabel
            let precisionImage = customCell?.viewWithTag(202) as! UIImageView

            if selectAnomalie != nil || selectEquipement != nil {
                precisionLabel.text = Constants.LabelMessage.addAnomaly.uppercased()
                precisionImage.image = UIImage(named: Constants.Image.addAnomalie)
            } else {
                precisionLabel.text = Constants.LabelMessage.preciserPosition.uppercased()
                precisionImage.image = UIImage(named: Constants.Image.pinRose)
            }
            
            precisionLabel.textColor = UIColor.pinkDmr()
            bottomSheetTableView.isScrollEnabled = false
        case RowId.labelAnomaly:
            customCell = tableView.dequeueReusableCell(withIdentifier: "otherMalfunctionTitleCell")
            
            let otherAnomalieLabel = customCell?.viewWithTag(300) as! UILabel
            
            if ContextManager.shared.typeContribution == .indoor {
                otherAnomalieLabel.text = Constants.LabelMessage.otherAnomalieEquipementLabel
            } else {
                otherAnomalieLabel.text = Constants.LabelMessage.otherAnomalieLabel
            }
            
        default:
            customCell = tableView.dequeueReusableCell(withIdentifier: "otherMalfunctionCell")
            
            let otherMalfunction = otherMalfunctionsArray[indexPath.row - 3]
            let otherMalfunctionMainTitle = customCell?.viewWithTag(402) as! UILabel
            otherMalfunctionMainTitle.text = otherMalfunction.alias
            otherMalfunctionMainTitle.lineBreakMode = NSLineBreakMode.byTruncatingTail
            otherMalfunctionMainTitle.numberOfLines = 0
                        
            let otherMalfunctionAddress = customCell?.viewWithTag(403) as! UILabel
            otherMalfunctionAddress.lineBreakMode = .byClipping
            otherMalfunctionAddress.numberOfLines=0
            otherMalfunctionAddress.text = otherMalfunction.address + "\n" + otherMalfunction.number
            
            let otherMalfunctionImageView = customCell?.viewWithTag(401) as! UIImageView
            let imageURL =  (otherMalfunction.source == .ramen) ? URL(string: Constants.Image.ramen) : (URL(string: otherMalfunction.firstImageUrl) ?? URL(string: Constants.Image.noImage))
            
            otherMalfunctionImageView.sd_setImage(with: imageURL!, placeholderImage: otherMalfunction.imageCategorie, options: .allowInvalidSSLCertificates)
        }
        
        customCell?.selectionStyle = .none
        
        return customCell!
    }
    
    @objc private func closeBtnTouchUp(_ sender: UIButton) {
        self.animateBottomSheet(withDuration: 0.5, status: .none)
    }
    
    private func showDetailAnomalie(forCell customCell: UITableViewCell) {
        
        let geolocImageView = customCell.viewWithTag(101) as! UIImageView
        let geolocMainTitle = customCell.viewWithTag(102) as! UILabel
        
        geolocMainTitle.isHidden = buttomSheetFullView
        geolocImageView.isHidden = buttomSheetFullView
        
        if !buttomSheetFullView, let myAnomalie = selectAnomalie {
            geolocMainTitle.text = myAnomalie.alias
            
            // Affichage de l'adresse
            let geolocSubtitle = customCell.viewWithTag(103) as! UILabel
            geolocSubtitle.text = myAnomalie.address
            geolocSubtitle.isHidden = false
            
            if !self.buttomSheetFullView {
                let imageURL = URL(string: myAnomalie.firstImageUrl) ?? URL(string: Constants.Image.noImage)
                
                geolocImageView.sd_setImage(with: imageURL!, placeholderImage: myAnomalie.imageCategorie, options: .allowInvalidSSLCertificates)
                
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.displaySelectedAnomaly(_:)))
                
                geolocImageView.isUserInteractionEnabled = true
                geolocImageView.addGestureRecognizer(tapGestureRecognizer)
                geolocImageView.contentMode = .scaleAspectFill
            }
        } else {
            showDetailAdresse(forCell: customCell)
        }
    }
    
    private func showDetailEquipement(forCell customCell: UITableViewCell) {
        
        let geolocImageView = customCell.viewWithTag(101) as! UIImageView
        let geolocMainTitle = customCell.viewWithTag(102) as! UILabel
        
        
        geolocMainTitle.isHidden = buttomSheetFullView
        geolocImageView.isHidden = buttomSheetFullView
        
        if !buttomSheetFullView, let myEquipement = selectEquipement {
            geolocMainTitle.isHidden = true
            geolocImageView.isHidden = true

            // Affichage du nom de la piscine
            let nameLbl:UILabel = addLabel(withText: myEquipement.name, andTag: 104)
            nameLbl.numberOfLines = 1
            nameLbl.lineBreakMode = .byTruncatingTail
            nameLbl.frame = CGRect(x: 15, y: 8, width: geolocMainTitle.frame.width + geolocImageView.frame.width, height: geolocMainTitle.frame.height)
            if self.otherCellDisplay {
                nameLbl.textColor = .white
            } else {
                nameLbl.textColor = .black
            }
            
            customCell.addSubview(nameLbl)
            
            // Affichage de l'adresse
            let addressLbl:UILabel = addLabel(withText: myEquipement.adresse, andTag: 103)
            addressLbl.frame = CGRect(x: nameLbl.frame.origin.x, y: nameLbl.frame.origin.y + 12, width: geolocMainTitle.frame.width + geolocImageView.frame.width, height: 30)
            addressLbl.numberOfLines = 2
            addressLbl.lineBreakMode = .byWordWrapping
            
            customCell.addSubview(addressLbl)
            
            // Affichage du nombre d'anomalie
            let nbAnoText = (myEquipement.anomalies.count > 1) ? "\(myEquipement.anomalies.count) \(Constants.LabelMessage.anomalieCountLabel)" : "\(myEquipement.anomalies.count) \(Constants.LabelMessage.anomalieCountOneLabel)"
            let nbAnoLbl:UILabel = addLabel(withText: nbAnoText, andTag: 888)
            nbAnoLbl.frame = CGRect(x: addressLbl.frame.origin.x, y: addressLbl.frame.origin.y + 17, width: addressLbl.frame.width, height: addressLbl.frame.height)
            nbAnoLbl.font = UIFont.init(name: Constants.fontDmr, size: 10)
            if self.otherCellDisplay {
                nbAnoLbl.textColor = .white
            } else {
                nbAnoLbl.textColor = UIColor.pinkDmr()
            }
            
            customCell.addSubview(nbAnoLbl)
        } else {
            showDetailAdresse(forCell: customCell)
        }
    }
    
    private func showDetailAdresse(forCell customCell: UITableViewCell) {
        
        let geolocImageView = customCell.viewWithTag(101) as! UIImageView
        let geolocMainTitle = customCell.viewWithTag(102) as! UILabel
        let geolocSubtitle = customCell.viewWithTag(103) as! UILabel
        
        geolocImageView.image = UIImage(named: Constants.Image.iconGeolocation)
        geolocImageView.contentMode = .center
        geolocImageView.isUserInteractionEnabled = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.hideUberPin(_:)))
        geolocImageView.addGestureRecognizer(tapGestureRecognizer)
        
        if let myAddress = selectedAddress {
            if let firstAddressLine = myAddress.thoroughfare {
                geolocMainTitle.text = firstAddressLine
                MapsUtils.addressLabel = firstAddressLine
            } else {
                //Si l'api renvoi le quartier et non l'adresse
                geolocMainTitle.text = myAddress.lines![0]
                MapsUtils.addressLabel = myAddress.lines![0]
                MapsUtils.postalCode = myAddress.lines![1].components(separatedBy: " ")[0]
                var arrondissement = (myAddress.subLocality?.components(separatedBy: CharacterSet.decimalDigits.inverted)[0])!
                if(arrondissement=="1") {
                    arrondissement.append(" er")
                } else {
                    arrondissement.append(" ème")
                }
                MapsUtils.boroughLabel = arrondissement
                geolocSubtitle.text = MapsUtils.boroughLabel
                geolocSubtitle.isHidden = false
            }
            
            if let postalCode = myAddress.postalCode {
                MapsUtils.postalCode = postalCode
                MapsUtils.boroughLabel = MapsUtils.boroughLabel(postalCode: postalCode)
                geolocSubtitle.text = MapsUtils.boroughLabel
                geolocSubtitle.isHidden = false
            }
            if let locality = myAddress.locality {
                MapsUtils.locality = locality
            }
            
            //Gestion de l'affichage du btn de gestion de favoris
            let favorites : [String] = getFavoritesAddress()
            var isAlreadyInFavorites = false
            for favorite in favorites {
                let favArr = favorite.components(separatedBy: Constants.Key.separatorAdresseCoordonate)
                
                //Vérification sur le nom de l'adresse
                if favArr[0] == MapsUtils.fullAddress() {
                    isAlreadyInFavorites = true
                }
                
                //Vérification sur les coordonnées
                if String(MapsUtils.userLocation()!.latitude) + "-" + String(MapsUtils.userLocation()!.longitude) == favArr[1] {
                    isAlreadyInFavorites = true
                }
            }
            
            if hidemanageFavoriteBtns {
                addFavoriteBtn?.isHidden = true
                removeFavoriteBtn?.isHidden = true
            } else {
                addFavoriteBtn?.isHidden = isAlreadyInFavorites
                removeFavoriteBtn?.isHidden = !isAlreadyInFavorites
            }
            
            
        } else {
            geolocMainTitle.text = ""
            
            // Cas du mode Offline, on affiche les coordonnees GPS
            if let coordinates = selectedCoordinates {
                MapsUtils.addressLabel = "lat : \(coordinates.latitude), lgt : \(coordinates.longitude)"
                geolocMainTitle.text = MapsUtils.addressLabel
                MapsUtils.boroughLabel = ""
                MapsUtils.postalCode = ""
                MapsUtils.locality = ""
            }
        }
    }
    
    private func initButtonManageFavorite( isAddFavorite: Bool) -> UIButton
    {
        let button = UIButton(frame: CGRect(x:self.view.frame.width - 55, y:+45, width:33, height:33))
        //button.backgroundColor = .clear
        //button.imageEdgeInsets = UIEdgeInsets.init(top: -10, left: -10, bottom: -10, right: -10)
        button.isUserInteractionEnabled = true
        
        return button
    }
    
    private func addLabel(withText: String, andTag newTag: Int) -> UILabel {
        let myLabel:UILabel = UILabel()
        myLabel.numberOfLines = 1
        myLabel.lineBreakMode = .byWordWrapping
        myLabel.textColor = UIColor.greyDmr()
        myLabel.font = UIFont.init(name: Constants.fontDmr, size: 12)
        myLabel.tag = newTag
        myLabel.textAlignment = .left
        myLabel.text = withText
        
        return myLabel
    }
}

extension BottomSheetViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let gesture = (gestureRecognizer as! UIPanGestureRecognizer)
        let direction = gesture.velocity(in: view).y
        
        let y = view.frame.minY
        if (y == fullView && bottomSheetTableView.contentOffset.y == 0 && direction > 0) || (y == partialView) || (y == UIScreen.main.bounds.height - 225) {
            bottomSheetTableView.isScrollEnabled = false
        } else {
            bottomSheetTableView.isScrollEnabled = true
        }
        
        return false
    }
    
}

extension BottomSheetViewController: CustomNavigationDelegate {
    
    func displayAddAnomaly(anomalySelected: Anomalie) {
        let addAnomalyStoryboard = UIStoryboard(name: Constants.StoryBoard.addAnomaly, bundle: nil)
        let addAnomalyViewController = addAnomalyStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.addAnomaly) as! AddAnomalyViewController
        addAnomalyViewController.currentAnomalie = anomalySelected
        self.parent?.navigationController?.navigationBar.isHidden = false
        self.parent?.navigationController?.navigationBar.tintColor = UIColor.white
        self.parent?.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue:UIColor.white])
        self.parent?.navigationController?.pushViewController(addAnomalyViewController, animated: true)
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

//Class tapeGesture perso pour envoyre l'id en param
class MyTapGesture: UITapGestureRecognizer {
    var address = String()
    var addFavorite = Bool()
}
