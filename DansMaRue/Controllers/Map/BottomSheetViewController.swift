//
//  BottomSheetViewController.swift
//  DansMaRue
//
//  Created by Maxime Bureau on 13/04/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import AppAuth
import GoogleMaps
import GooglePlaces
import SDWebImage
import TTGSnackbar
import UIKit

protocol UberDelegate: NSObjectProtocol {
    func shouldDisplayUberPin(yesWeCan: Bool)
}

class BottomSheetViewController: UIViewController, UITextFieldDelegate, OIDAuthStateChangeDelegate {
    // MARK: - IBOutlets

    @IBOutlet var bottomSheetTableView: UITableView!
    
    // MARK: - Properties

    var showAnomalyWidth: CGFloat = 0
    let fullView: CGFloat = 0
    var partialView: CGFloat = 600
    var bottomSheetInitialY: CGFloat = 0
    weak var uberDelegate: UberDelegate?
    var uberDisplayed = false
    var mapsUtils: MapsUtils?
    var selectedAddress: GMSAddress?
    var selectedCoordinates: CLLocationCoordinate2D?
    
    var otherCellDisplay: Bool = false
    var buttomSheetFullView: Bool = false
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
    let anomalieNotification = Notification.Name(rawValue: Constants.NoticationKey.anomaliesChanged)
    
    var addAnomalyBtn: UIButton?
    var searchAnomalyBtn: UIButton?
    var showAnomalyBtn: UIButton?
    var followAnomalyBtn: UIButton?
    var unfollowAnomalyBtn: UIButton?
    var congratulateAnomalyBtn: UIButton?
    var swipeImageView: UIImageView?
    
    let imgAddAnomaly = UIImage(named: Constants.Image.createAnomalie)
    let imgAddAnomalySelected = UIImage(named: Constants.Image.createAnomalieSelected)
    let imgSearchAnomalie = UIImage(named: Constants.Image.searchAnomalie)
    let imgShowAnomalie = UIImage(named: Constants.Image.showAnomalies)
    let imgFollowAnomaly = UIImage(named: Constants.Image.follow)
    let imgFollowAnomalySelected = UIImage(named: Constants.Image.followSelected)
    let imgFollowAnomalyDisabled = UIImage(named: Constants.Image.followDisabled)
    let imgUnfollowAnomaly = UIImage(named: Constants.Image.unfollow)
    let imgUnfollowAnomalySelected = UIImage(named: Constants.Image.unfollowSelected)
    let imgCongratulateAnomaly = UIImage(named: Constants.Image.congratulate)
    let imgCongratulateAnomalySelected = UIImage(named: Constants.Image.congratulateSelected)
    let imgCongratulateAnomalyDisabled = UIImage(named: Constants.Image.congratulateDisabled)
    let imgAddAddressFavorite = UIImage(named: Constants.Image.favoritePlus)
    let imgRemoveddressFavorite = UIImage(named: Constants.Image.favoriteCheck)

    var otherMalfunctionsArray = [Anomalie]()
    var currentStatus: BottomSheetStatus = .none
    var initFrameHeight: CGFloat = 0.0
    var buttonHeight: CGFloat = 40

    var isFirstFullView = true
    var isScrollEnable = true
    private var authState: OIDAuthState?
    typealias PostRegistrationCallback = (_ configuration: OIDServiceConfiguration?, _ registrationResponse: OIDRegistrationResponse?) -> Void
    let redirectURI: String = Constants.Authentification.RedirectURI
    let authStateKey: String = "authState"
    
    var showAnomalyInitialX: CGFloat = 0
    var showAnomalyInitialY: CGFloat = 0
    var showAnomalyInitialHeight: CGFloat = 0
    var showAnomalyInitialWidth: CGFloat = 0
    var isAlreadyInFavorites = false

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        bottomSheetTableView.delegate = self
        bottomSheetTableView.rowHeight = UITableView.automaticDimension
        bottomSheetTableView.estimatedRowHeight = 60
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(BottomSheetViewController.panGesture))
        gesture.delegate = self
        view.addGestureRecognizer(gesture)
        
        let nc = NotificationCenter.default
        nc.addObserver(forName: NSNotification.Name(rawValue: Constants.NoticationKey.addressNotification), object: nil, queue: nil, using: changeAddress)
        nc.addObserver(forName: NSNotification.Name(rawValue: Constants.NoticationKey.anomaliesChanged), object: nil, queue: nil, using: reloadAnomalies)
        
        nc.addObserver(forName: Notification.Name(rawValue: Constants.NoticationKey.pushNotification), object: nil, queue: nil, using: notificationToDisplayAnomalie)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bottomSheetTableView.layoutIfNeeded()
        bottomSheetTableView.reloadData()
    
        if buttomSheetFullView {
            animateBottomSheet(withDuration: 0, status: .full)
        } else if otherCellDisplay {
            animateBottomSheet(withDuration: 0, status: .selected)
        } else {
            animateBottomSheet(withDuration: 0, status: .none)
        }
        if addAnomalyBtn == nil {
            addAnomalyBtn = initButton()
            addAnomalyBtn?.setImage(imgAddAnomaly, for: .normal)
            addAnomalyBtn?.addTarget(self, action: #selector(tapAddAnomaly(sender:)), for: .touchUpInside)
            addAnomalyBtn?.accessibilityLabel = Constants.LabelMessage.addAnomaly
            addAnomalyBtn?.accessibilityTraits = .button
            view.addSubview(addAnomalyBtn!)
        }
        
        if searchAnomalyBtn == nil {
            searchAnomalyBtn = initSearchButton()
            searchAnomalyBtn?.setImage(imgSearchAnomalie, for: .normal)
            searchAnomalyBtn?.addTarget(self, action: #selector(tapSearchAnomaly(sender:)), for: .touchUpInside)
            searchAnomalyBtn?.accessibilityLabel = Constants.LabelMessage.searchAnomaly
            searchAnomalyBtn?.accessibilityTraits = .button
            view.addSubview(searchAnomalyBtn!)
        }
        if swipeImageView == nil {
            swipeImageView = initIconButton()
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(displayBottomSheet(sender:)))
            swipeImageView?.addGestureRecognizer(singleTap)
            view.addSubview(swipeImageView!)
        }

        if followAnomalyBtn == nil {
            followAnomalyBtn = initButton()
            followAnomalyBtn?.setImage(imgFollowAnomaly, for: .normal)
            followAnomalyBtn?.setImage(imgFollowAnomalyDisabled, for: .disabled)
            followAnomalyBtn?.addTarget(self, action: #selector(tapFollowAnomaly(sender:)), for: .touchUpInside)
            followAnomalyBtn?.isHidden = true
            followAnomalyBtn?.accessibilityLabel = Constants.LabelMessage.followAnomaly
            view.addSubview(followAnomalyBtn!)
        }
        
        if unfollowAnomalyBtn == nil {
            unfollowAnomalyBtn = initButton()
            unfollowAnomalyBtn?.setImage(imgUnfollowAnomaly, for: .normal)
            unfollowAnomalyBtn?.addTarget(self, action: #selector(tapUnfollowAnomaly(sender:)), for: .touchUpInside)
            unfollowAnomalyBtn?.isHidden = true
            unfollowAnomalyBtn?.accessibilityLabel = Constants.LabelMessage.unfollowAnomaly
            view.addSubview(unfollowAnomalyBtn!)
        }
        
        if congratulateAnomalyBtn == nil {
            congratulateAnomalyBtn = initButton()
            congratulateAnomalyBtn?.setImage(imgCongratulateAnomaly, for: .normal)
            congratulateAnomalyBtn?.setImage(imgCongratulateAnomalyDisabled, for: .disabled)
            congratulateAnomalyBtn?.addTarget(self, action: #selector(tapCongratulateAnomaly(sender:)), for: .touchUpInside)
            congratulateAnomalyBtn?.isHidden = true
            congratulateAnomalyBtn?.accessibilityLabel = Constants.LabelMessage.congratulateAnomaly
            view.addSubview(congratulateAnomalyBtn!)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if showAnomalyBtn == nil {
            showAnomalyBtn = initShowButton()
            showAnomalyBtn?.tag = 55
            showAnomalyBtn?.addTarget(self, action: #selector(displayBottomSheet(sender:)), for: .touchUpInside)
            showAnomalyBtn?.accessibilityLabel = Constants.LabelMessage.showAnomaly
            showAnomalyBtn?.setTitle(Constants.LabelMessage.showAnomaly, for: .normal)
            showAnomalyBtn?.tintColor = .white
            showAnomalyBtn?.backgroundColor = UIColor.pinkButtonDmr()
            showAnomalyBtn?.accessibilityTraits = .button
            applyDynamicType(label: (showAnomalyBtn?.titleLabel!)!, fontName: "Montserrat-Regular", size: 12)
            showAnomalyBtn?.sizeToFit()
            updateShowButtonFrame()
            view.addSubview(showAnomalyBtn!)
        }
        
        if swipeImageView == nil {
            swipeImageView = initIconButton()
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(displayBottomSheet(sender:)))
            swipeImageView?.addGestureRecognizer(singleTap)
            view.addSubview(swipeImageView!)
        }
    }

    override func viewDidLayoutSubviews() {
        handleOrientationChanged()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        handleOrientationChanged()
    }

    func initButton() -> UIButton {
        let frame = UIDevice.current.orientation.isLandscape ? CGRect(x: view.frame.width - 130, y: -30, width: 65, height: 65) :
            CGRect(x: view.frame.width - 70, y: -30, width: 65, height: 65)
        let button = UIButton(frame: frame)
        button.backgroundColor = .black
        button.layer.borderWidth = 0
        button.tintColor = .white
        button.backgroundColor = .clear
        button.imageEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        
        return button
    }
    
    func initSearchButton() -> UIButton {
        let frame = UIDevice.current.orientation.isLandscape ? CGRect(x: view.frame.width - 195, y: -85, width: 65, height: 65) :
            CGRect(x: view.frame.width - 70, y: -170, width: 65, height: 65)
    
        let button = UIButton(frame: frame)
        button.isUserInteractionEnabled = true
        
        return button
    }
    
    func initShowButton() -> UIButton {
        let btnWidth = view.frame.width / 2
        let button = UIButton(frame: CGRect(x: view.frame.width / 2 - btnWidth / 2, y: -40, width: btnWidth, height: 40))

        button.isUserInteractionEnabled = true
        button.layer.cornerRadius = buttonHeight / 2
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
         
        return button
    }
    
    func initIconButton() -> UIImageView {
        let imageName = "arrow_swipe"
        let image = UIImage(named: imageName)
        let imageView = UIImageView(image: image!)
        imageView.frame = CGRect(x: showAnomalyInitialX + showAnomalyInitialWidth / 2 - 10, y: -buttonHeight - 5, width: 20, height: 20)
        imageView.isUserInteractionEnabled = true
        return imageView
    }
    
    func isLargerTextEnabled() -> Bool {
        let contentSize = UIApplication.shared.preferredContentSizeCategory
        let accessibilitySizeEnabled = contentSize.isAccessibilityCategory
        return accessibilitySizeEnabled
    }

    func updateShowButtonFrame() {
        let initialButtonWidth: CGFloat = view.frame.width / 2
        let otherButtonWidths: CGFloat = 82
        let frameWidth = view.frame.width
        if showAnomalyBtn!.frame.width > initialButtonWidth {
            let isOverflow = showAnomalyBtn!.frame.width >= frameWidth - (otherButtonWidths + 16)
            var btnWidth: CGFloat = 0
            if isLargerTextEnabled() {
                btnWidth = isOverflow ? min(showAnomalyBtn!.frame.width, frameWidth - otherButtonWidths) : (frameWidth - 2 * (otherButtonWidths + 16))
            } else {
                btnWidth = initialButtonWidth
            }
            
            buttonHeight = showAnomalyBtn!.frame.height < showAnomalyBtn!.titleLabel!.frame.height ? 80 : 40
            
            showAnomalyInitialX = CGFloat(isLargerTextEnabled() ? 16 : view.frame.width / 2 - btnWidth / 2)
            showAnomalyInitialY = CGFloat(-buttonHeight + 20)
            showAnomalyInitialWidth = CGFloat(btnWidth)
            showAnomalyInitialHeight = CGFloat(buttonHeight)
            
            showAnomalyBtn?.frame = CGRect(
                origin: CGPoint(
                    x: showAnomalyInitialX,
                    y: showAnomalyInitialY),
                size: CGSize(width: showAnomalyInitialWidth, height: showAnomalyInitialHeight))
        } else {
            buttonHeight = showAnomalyBtn!.frame.height < showAnomalyBtn!.titleLabel!.frame.height ? 80 : 40
            showAnomalyInitialX = CGFloat(view.frame.width / 2 - initialButtonWidth / 2)
            showAnomalyInitialY = CGFloat(-20)
            showAnomalyInitialWidth = CGFloat(isLargerTextEnabled() ? (frameWidth - otherButtonWidths) : initialButtonWidth)
            showAnomalyInitialHeight = CGFloat(buttonHeight)
            showAnomalyBtn?.frame = CGRect(x: showAnomalyInitialX, y: showAnomalyInitialY, width: showAnomalyInitialWidth,
                                           height: showAnomalyInitialHeight)
        }
    }
    
    private func handleOrientationChanged() {
        let frameWidth = view.frame.width
        let btnWidth = view.frame.width / 2
        if UIDevice.current.orientation.isLandscape {
            if bottomSheetInitialY == 0 || bottomSheetInitialY > parent!.view.frame.height {
                bottomSheetInitialY = partialView
            }
            if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft {
                addAnomalyBtn?.frame = CGRect(x: view.frame.width - 130, y: -30, width: 65, height: 65)
                searchAnomalyBtn?.frame = CGRect(x: view.frame.width - 195, y: -85, width: 65, height: 65)
                updateShowButtonFrame()
                swipeImageView?.frame = CGRect(x: showAnomalyInitialX + showAnomalyInitialWidth / 2 - 10, y: -buttonHeight - 5, width: 20, height: 20)
            } else if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
                addAnomalyBtn?.frame = CGRect(x: view.frame.width - 130, y: -30, width: 65, height: 65)
                searchAnomalyBtn?.frame = CGRect(x: view.frame.width - 195, y: -85, width: 65, height: 65)
                showAnomalyBtn?.frame = CGRect(x: frameWidth / 2 - btnWidth / 2, y: -buttonHeight + 20, width: btnWidth * 4 / 3, height: buttonHeight)
                updateShowButtonFrame()
                swipeImageView?.frame = CGRect(x: showAnomalyInitialX + showAnomalyInitialWidth / 2 - 10, y: -buttonHeight - 5, width: 20, height: 20)
            }
        } else {
            if bottomSheetInitialY == 0 || bottomSheetInitialY < parent!.view.frame.height / 2 {
                bottomSheetInitialY = partialView
            }
            addAnomalyBtn?.frame = CGRect(x: view.frame.width - 70, y: -30, width: 65, height: 65)
            searchAnomalyBtn?.frame = CGRect(x: view.frame.width - 70, y: -170, width: 65, height: 65)
            updateShowButtonFrame()
            swipeImageView?.frame = CGRect(x: showAnomalyInitialX + showAnomalyInitialWidth / 2 - 10, y: -buttonHeight - 5, width: 20, height: 20)
        }
    }
    
    // MARK: - Bottom sheet methods

    @objc func panGesture(_ recognizer: UIPanGestureRecognizer) {
        let loc = recognizer.location(in: recognizer.view)
        let subview = view?.hitTest(loc, with: nil)
        let objectTapped = subview?.tag
        let translation = recognizer.translation(in: view)
        let velocity = recognizer.velocity(in: view)
        let y = view.frame.minY
        _ = recognizer.velocity(in: view).y
        
        if !buttomSheetFullView || (buttomSheetFullView && (objectTapped == 0 || objectTapped == nil)) {
            if (y + translation.y >= fullView) && (y + translation.y <= bottomSheetInitialY) {
                view.frame = CGRect(x: 0, y: y + translation.y, width: view.frame.width, height: view.frame.height)
                recognizer.setTranslation(CGPoint.zero, in: view)
            }
        
            if recognizer.state == .ended {
                var duration = velocity.y < 0 ? Double((y - fullView) / -velocity.y) : Double((bottomSheetInitialY - y) / velocity.y)
                
                duration = duration > 1.3 ? 1 : duration
                
                UIView.animate(withDuration: duration, delay: 0.0, options: [.allowUserInteraction], animations: {
                    if velocity.y >= 0 {
                        self.animateBottomSheet(withDuration: duration, status: .none)
                    } else {
                        if objectTapped != 0 {
                            self.animateBottomSheet(withDuration: duration, status: .full)
                        }
                    }
                    
                }, completion: nil)
            }
        }
    }
    
    // MARK: - Update data

    func changeAddress(notification: Notification) {
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
        
        bottomSheetTableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        let frame = view.frame
        view.frame = CGRect(x: 0, y: bottomSheetInitialY, width: frame.width, height: frame.height + buttonHeight)
    }
    
    func reloadAnomalies(notification: Notification) {
        otherMalfunctionsArray = (notification.object as? [Anomalie])!
        bottomSheetTableView.reloadData()
    }
    
    func showAnomalie(anomalie: Anomalie) {
        selectAnomalie = anomalie
        // Update first row
        bottomSheetTableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        if otherCellDisplay {
            bottomSheetTableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
        }
        
        addAnomalyBtn?.isHidden = true
        congratulateAnomalyBtn?.isEnabled = true
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
    
    func showEquipement(equipement: Equipement) {
        selectEquipement = equipement
        // Update first row
        bottomSheetTableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        if otherCellDisplay {
            bottomSheetTableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
        }
        
        addAnomalyBtn?.isHidden = false
        
        followAnomalyBtn?.isHidden = true
        unfollowAnomalyBtn?.isHidden = true
        congratulateAnomalyBtn?.isHidden = true
    }
    
    // MARK: - Other functions

    func getDetailsAnomalies(anomalie: Anomalie, source: AnomalieSource) {
        if let anoEquipement = anomalie as? AnomalieEquipement {
            DispatchQueue.global().async {
                RestApiManager.sharedInstance.getIncidentEquipementById(idSignalement: anoEquipement.id) { (anomalie: AnomalieEquipement) in
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
            // Si ano DMR, on affiche le détail
            if source == AnomalieSource.dmr {
                DispatchQueue.global().async {
                    RestApiManager.sharedInstance.getIncidentById(idSignalement: anomalie.id, source: source) { (anomalie: Anomalie) in
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
    
    func didChange(_ state: OIDAuthState) {
        setAuthState(state)
    }
    
    @objc func addOrRemoveFavorite(recognizer: MyTapGesture) {
        var favorite: [String] = getFavoritesAddress()
        // Récupération de l'adresse et des coordonées
        let addressWithCoordonate = MapsUtils.fullAddress() + Constants.Key.separatorAdresseCoordonate + String(MapsUtils.userLocation()!.latitude) + "-" + String(MapsUtils.userLocation()!.longitude)
        
        // Ajout d'une adresse aux favoris
        if recognizer.addFavorite {
            // Vérification si l'adresse est dans Paris
            if MapsUtils.postalCode.hasPrefix(Constants.prefix75) {
                favorite.append(addressWithCoordonate)
                isAlreadyInFavorites = true
            } else {
                // Si hors de Paris, affichage d'une popup d'erreur
                let alertController = UIAlertController(title: Constants.AlertBoxTitle.adresseHorsParis, message: Constants.AlertBoxMessage.adresseHorsParis, preferredStyle: .alert)
                
                let OKAction = UIAlertAction(title: Constants.AlertBoxTitle.ok, style: UIAlertAction.Style.default, handler: nil)
                alertController.addAction(OKAction)
                
                // Present Dialog message
                present(alertController, animated: true, completion: nil)
            }
        } else {
            // Suppression si adresse et coordonnées égaux
            if let index = favorite.index(of: addressWithCoordonate) {
                favorite.remove(at: index)
                isAlreadyInFavorites = false
            } else {
                // Suppression si coordonnées ou adresse égaux
                for fav in favorite {
                    let favArr = fav.components(separatedBy: Constants.Key.separatorAdresseCoordonate)
                    
                    // Vérification sur le nom de l'adresse
                    if favArr[0] == MapsUtils.fullAddress() {
                        isAlreadyInFavorites = true
                    }
                    
                    // Vérification sur les coordonnées
                    if String(MapsUtils.userLocation()!.latitude) + "-" + String(MapsUtils.userLocation()!.longitude) == favArr[1] {
                        isAlreadyInFavorites = true
                    }
                    
                    if isAlreadyInFavorites {
                        let index = favorite.index(of: fav)
                        favorite.remove(at: index!)
                        isAlreadyInFavorites = false
                    }
                }
            }
        }
        let defaults = UserDefaults.standard
        defaults.set(favorite, forKey: "favoritesAddressArray")
        bottomSheetTableView.reloadData()
    }
    
    // Retourne les adresses favorites de l'utilisateur
    func getFavoritesAddress() -> [String] {
        let defaults = UserDefaults.standard
        var favorite: [String] = []
        
        // Récupération des favoris dans les UserDefaults
        if let favoritesArray = defaults.stringArray(forKey: "favoritesAddressArray") {
            favorite = favoritesArray
        }
        return favorite
    }
    
    @objc func displaySelectedAnomaly(_ sender: AnyObject) {
        if let myAnomalie = selectAnomalie {
            getDetailsAnomalies(anomalie: myAnomalie, source: myAnomalie.source)
        }
    }
    
    @objc func hideUberPin(_ sender: AnyObject) {
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
    
    func notificationToDisplayAnomalie(notification: Notification) {
        // Réception d'une notification push pour afficher le détail d'une anomalie
        if let anomalie = notification.object as? Anomalie {
            getDetailsAnomalies(anomalie: anomalie, source: .dmr)
        }
    }
    
    @objc func displayBottomSheet(sender: UIButton) {
        animateBottomSheet(withDuration: 1, status: .full)
    }
    
    /// Animation de l'affichage de la BottomSheet en fonction du status
    ///
    /// - Parameters:
    ///   - duration: delay de l'animation
    ///   - status: status d'affichage
    func animateBottomSheet(withDuration duration: TimeInterval, status: BottomSheetStatus) {
        print("******animate******")
        switch status {
        case .selected:
            currentStatus = .selected
            otherCellDisplay = true
            buttomSheetFullView = false
            showAnomalyBtn?.isHidden = true
            swipeImageView?.isHidden = true
            
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
            showAnomalyBtn?.isHidden = true
            swipeImageView?.isHidden = true
            
            if isFirstFullView {
                initFrameHeight = view.frame.height
                isFirstFullView = false
            }
            delegate.activateTopConstraint(false)
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
            // selectEquipement = nil

            addAnomalyBtn?.isHidden = false
            followAnomalyBtn?.isHidden = true
            unfollowAnomalyBtn?.isHidden = true
            congratulateAnomalyBtn?.isHidden = true
            showAnomalyBtn?.isHidden = false
            swipeImageView?.isHidden = false
            
            addAnomalyBtn?.setImage(imgAddAnomaly, for: .normal)
            followAnomalyBtn?.setImage(imgFollowAnomaly, for: .normal)
            unfollowAnomalyBtn?.setImage(imgUnfollowAnomaly, for: .normal)
            congratulateAnomalyBtn?.setImage(imgCongratulateAnomaly, for: .normal)
            
            if let anomalie = selectAnomalie {
                followAnomalyBtn?.isEnabled = anomalie.source == .dmr
                unfollowAnomalyBtn?.isEnabled = anomalie.source == .dmr
            }
            delegate.activateTopConstraint(true)
            UIView.animate(withDuration: duration) { [weak self] in
                guard let self = self else { return }
                self.view.frame = CGRect(
                    x: 0,
                    y: self.bottomSheetInitialY,
                    width: self.view.frame.width,
                    height: self.view.frame.height + self.buttonHeight)
            }
        }
        bottomSheetTableView.reloadData()
        navigationController?.setNavigationBarHidden(buttomSheetFullView, animated: true)
    }
    
    func displayAddAnomalyView() {
        // Outdoor : Si utilisateur connecté et en dehors de Paris, alors affiche message d'erreur
        if Reach().connectionStatus() && !MapsUtils.postalCode.hasPrefix(Constants.prefix75) && ContextManager.shared.typeContribution == .outdoor {
            let alertController = UIAlertController(title: Constants.AlertBoxTitle.adresseInvalide, message: Constants.AlertBoxMessage.adresseInvalide, preferredStyle: .alert)
            // Create OK button
            let OKAction = UIAlertAction(title: Constants.AlertBoxTitle.ok, style: .default) {
                (_: UIAlertAction!) in
            }
            alertController.addAction(OKAction)
            // Present Dialog message
            present(alertController, animated: true, completion: nil)
        } else {
            let addAnomalyStoryboard = UIStoryboard(name: Constants.StoryBoard.addAnomaly, bundle: nil)
            let addAnomalyViewController = addAnomalyStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.addAnomaly) as! AddAnomalyViewController
            addAnomalyViewController.typeContribution = ContextManager.shared.typeContribution
            navigationController?.navigationBar.tintColor = UIColor.white
            navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.white])
            navigationController?.pushViewController(addAnomalyViewController, animated: true)
        }
    }

    @objc func tapAddAnomaly(sender: UIButton) {
        if ContextManager.shared.typeContribution == .indoor {
            if ContextManager.shared.equipementSelected == nil {
                let alertController = UIAlertController(title: Constants.AlertBoxTitle.attention, message: ContextManager.shared.typeEquipementSelected?.msgAlertNoEquipement, preferredStyle: .alert)
                
                let OKAction = UIAlertAction(title: Constants.AlertBoxTitle.ok, style: .default) { (_: UIAlertAction!) in
                }
                
                alertController.addAction(OKAction)
                present(alertController, animated: true, completion: nil)
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
    
    func showSearchPopup(erreur: String) {
        var message = ""
        // Ajout du message d'erreur si il y en a un
        if erreur != "" {
            message = erreur + "\n"
        }
    
        let alertController = UIAlertController(title: Constants.AlertBoxTitle.searchAnomaly, message: message + Constants.AlertBoxMessage.searchAnomaly, preferredStyle: .alert)
       
        // Textfield pour la saisie du numéro
        alertController.addTextField { [weak self] textField in
            textField.delegate = self
            textField.placeholder = "n° de l'anomalie: "
            textField.accessibilityHint = "numéro de l'anomalie"
            textField.accessibilityTraits = .searchField
            textField.attributedPlaceholder = NSAttributedString(
                string: "numéro de l'anomalie",
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.greyDmr()])
        }
        
        // Boutton rechercher
        let SearchAction = UIAlertAction(title: "Rechercher", style: .default, handler: { (_: UIAlertAction!) in
            let textField = alertController.textFields![0] as UITextField
            
            // Recherche
            self.searchAnomalyByNumber(number: textField.text!)
        })
        
        // Boutton annuler
        let cancelBtn = UIAlertAction(title: "Annuler", style: .default, handler: { (_: UIAlertAction) in
        })
        SearchAction.isAccessibilityElement = true
        SearchAction.accessibilityHint = Constants.LabelMessage.searchAnomaly
        SearchAction.accessibilityLabel = Constants.LabelMessage.searchAnomaly
        alertController.addAction(SearchAction)
        alertController.addAction(cancelBtn)
        
        present(alertController, animated: true, completion: nil)
        UIAccessibility.post(notification: .announcement, argument: erreur)
    }
    
    /// Méthode de recherche d'anomalie par numéro
    ///
    /// - Parameters:
    ///   - number: numéro de l'anomalie
    func searchAnomalyByNumber(number: String) {
        let pattern = "[BSGAWbsgaw][2][0-9]{3}[A-La-l][0-9]+$"
        let result = number.range(of: pattern, options: .regularExpression)
        
        // Le format ne correspond pas
        if result == nil {
            // Affichage du message d'erreur
            print("Erreur lors la saisie du numéro")
            showSearchPopup(erreur: "Numéro incorrect")
        } else {
            // Lancement de la recherche
            RestApiManager.sharedInstance.getIncidentsByNumber(number: number) { jsonDict in
                if let answer = jsonDict["answer"]?.dictionary {
                    if let incident = answer["incident"]?.arrayValue {
                        let marker = incident[0]
                        RestApiManager.sharedInstance.getIncidentById(idSignalement: marker["id"].stringValue, source: AnomalieSource.dmr) { (anomalie: Anomalie) in
                            DispatchQueue.main.async {
                                var anomaliesBottomSheet = [Anomalie]()
                                DispatchQueue.main.async {
                                    // Ajout du GMSMarker sur la map
                                    self.delegate.addMarkerAnomalie(anomalie: anomalie)
                                        
                                    if anomalie.anomalieStatus != .Resolu && !anomaliesBottomSheet.contains(anomalie) {
                                        anomaliesBottomSheet.append(anomalie)
                                    }
                                    NotificationCenter.default.post(name: self.anomalieNotification, object: anomaliesBottomSheet)
                                    
                                    // Zoom sur l'anomalie
                                    let currentLocation = CLLocationCoordinate2D(latitude: anomalie.latitude, longitude: anomalie.longitude)
                                    self.delegate.mapContainerView.clear()
                                    self.delegate.centerCameraToPosition(currentLocation: currentLocation)
                                }
                            }
                        }
                    }
                } else if let answer = jsonDict["error_message"]?.stringValue {
                    self.showSearchPopup(erreur: answer)
                } else if let answer = jsonDict["erreurBO"]?.stringValue {
                    self.showSearchPopup(erreur: answer)
                }
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool
    {
        return textField.text!.count <= 12 || (string == "")
    }
 
    @objc func tapFollowAnomaly(sender: UIButton) {
        if !User.shared.isLogged {
            // Redirection vers le Compte Parisien
            connectToMonParis()
        } else {
            if let anomalie = selectAnomalie {
                DispatchQueue.global().async {
                    RestApiManager.sharedInstance.follow(anomalie: anomalie, onCompletion: { (result: Bool) in
                        if result {
                            // Mise à jour de l'UI
                            DispatchQueue.main.async {
                                anomalie.isIncidentFollowedByUser = true
                                self.followAnomalyBtn?.isHidden = true
                                self.unfollowAnomalyBtn?.isHidden = false
                                
                                let snackbar = TTGSnackbar(message: Constants.AlertBoxMessage.followMalfunction, duration: .middle)
                                snackbar.messageTextAlign = .center
                                snackbar.messageTextFont = UIFont(name: Constants.fontDmr, size: 14)!
                                snackbar.show()
                                UIAccessibility.post(notification: .announcement, argument: Constants.AlertBoxMessage.followMalfunction)
                            }
                        } else {
                            self.showPopupMaintenance()
                        }
                    })
                }
            }
        }
    }
    
    func showPopupMaintenance() {
        let alert = UIAlertController(title: Constants.AlertBoxTitle.information, message: Constants.AlertBoxMessage.maintenance, preferredStyle: UIAlertController.Style.alert)
        let okBtn = UIAlertAction(title: "Ok", style: .default, handler: { (_: UIAlertAction) in
        })
        alert.addAction(okBtn)
        self.present(alert, animated: true, completion: nil)
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
                                if User.shared.isLogged {}
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

    @objc func tapUnfollowAnomaly(sender: UIButton) {
        if let anomalie = selectAnomalie {
            DispatchQueue.global().async {
                RestApiManager.sharedInstance.unfollow(anomalie: anomalie, onCompletion: { (result: Bool) in
                    if result {
                        // Mise à jour de l'UI
                        DispatchQueue.main.async {
                            anomalie.isIncidentFollowedByUser = false
                            self.followAnomalyBtn?.isHidden = false
                            self.unfollowAnomalyBtn?.isHidden = true
                            
                            let snackbar = TTGSnackbar(message: Constants.AlertBoxMessage.unfollowMalfunction, duration: .middle)
                            snackbar.messageTextAlign = .center
                            snackbar.messageTextFont = UIFont(name: Constants.fontDmr, size: 14)!
                            snackbar.show()
                            UIAccessibility.post(notification: .announcement, argument: Constants.AlertBoxMessage.unfollowMalfunction)
                        }
                    }
                    else {
                        self.showPopupMaintenance()
                    }
                })
            }
        }
    }
    
    @objc func tapCongratulateAnomaly(sender: UIButton) {
        if !User.shared.isLogged {
            connectToMonParis()
        } else {
            if let anomalie = selectAnomalie {
                var cancelAction = false
                congratulateAnomalyBtn?.isEnabled = false
                
                let snackbar = TTGSnackbar(message: Constants.AlertBoxMessage.congratulate, duration: .middle, actionText: Constants.AlertBoxTitle.annuler)
                    { _ in
                        self.congratulateAnomalyBtn?.isEnabled = true
                        cancelAction = true
                    }
                snackbar.actionTextColor = UIColor.pinkDmr()
                snackbar.actionTextFont = UIFont(name: Constants.fontDmr, size: 14.0)!
                snackbar.messageTextFont = UIFont(name: Constants.fontDmr, size: 15.0)!
                snackbar.messageTextAlign = NSTextAlignment.center
                
                // Callback si l'utilisateur ne fais pas "annuler"
                snackbar.dismissBlock = {
                    (_: TTGSnackbar) in
                    if !cancelAction {
                        DispatchQueue.global().async {
                            RestApiManager.sharedInstance.congratulateAnomalie(anomalie: anomalie, onCompletion: { (result: Bool) in
                                
                                if result {
                                    // Mise à jour de l'UI
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
    
    private func applyDynamicType(label: UILabel, fontName: String, size: Float) {
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.scaledFont(name: fontName, textSize: CGFloat(size))
    }
    
    func getBottomSheetVisibleHieght() -> CGFloat {
        //  let customCell = bottomSheetTableView.dequeueReusableCell(withIdentifier: "localization_cell")
        
        //  guard let height = customCell?.bounds.height else { return 0 }
        guard let height = bottomSheetTableView.cellForRow(at: IndexPath(row: 0, section: 0))?.contentView.bounds.height else { return 0 }
        return height
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
            break
        case 1:
            if selectAnomalie == nil && selectEquipement == nil {
                setUberPinHidden(uberDisplayed)
            } else {
                navigationController?.setNavigationBarHidden(false, animated: true)
                displayAddAnomalyView()
            }
        default:
            let anomalie = otherMalfunctionsArray[indexPath.row - 3]
            getDetailsAnomalies(anomalie: anomalie, source: anomalie.source)
        }
    }
}

extension BottomSheetViewController: UITableViewDataSource {
    enum RowId {
        static let description = 0
        static let uberMode = 1
        static let labelAnomaly = 2
        static let other = 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if otherCellDisplay {
            return 3 + otherMalfunctionsArray.count
        } else {
            return 1
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("cellForRowAt \(indexPath.row)")
        var customCell = tableView.dequeueReusableCell(withIdentifier: "localization_cell")
        
        switch indexPath.row {
        case RowId.description:
            if buttomSheetFullView {
                customCell = tableView.dequeueReusableCell(withIdentifier: "header_cell")
                customCell?.isAccessibilityElement = false
                let geolocImageView = customCell?.viewWithTag(101) as! UIImageView
                let geolocMainTitle = customCell?.viewWithTag(102) as! UILabel
                let favoriteBtn = customCell?.viewWithTag(103) as! UIButton
            
                favoriteBtn.setTitle("", for: .normal)
                favoriteBtn.backgroundColor = .white
                favoriteBtn.accessibilityTraits = .button
                if !isAlreadyInFavorites {
                    favoriteBtn.setImage(imgAddAddressFavorite, for: .normal)
                    favoriteBtn.accessibilityLabel = String(format: Constants.LabelMessage.addAdresseFavorite, MapsUtils.addressLabel)
                    let tapGestureRecognizer = MyTapGesture(target: self, action: #selector(addOrRemoveFavorite(recognizer:)))
                    tapGestureRecognizer.addFavorite = true
                    favoriteBtn.addGestureRecognizer(tapGestureRecognizer)
                } else {
                    favoriteBtn.setImage(imgRemoveddressFavorite, for: .normal)
                    favoriteBtn.accessibilityLabel = String(format: Constants.LabelMessage.removeAdresseFavorite, MapsUtils.addressLabel)
                    let tapGestureRecognizer = MyTapGesture(target: self, action: #selector(addOrRemoveFavorite(recognizer:)))
                    tapGestureRecognizer.addFavorite = false
                    favoriteBtn.addGestureRecognizer(tapGestureRecognizer)
                }
                customCell?.backgroundColor = UIColor.pinkDmr()
                geolocMainTitle.textColor = .white
                geolocMainTitle.isAccessibilityElement = true
                geolocMainTitle.accessibilityTraits = .staticText
                geolocMainTitle.lineBreakMode = .byWordWrapping
                geolocMainTitle.textColor = .white
                geolocMainTitle.font = UIFont(name: Constants.fontDmr, size: 16)
                geolocMainTitle.textAlignment = .center
                geolocMainTitle.text = MapsUtils.addressLabel
                if ContextManager.shared.typeContribution == .outdoor || selectEquipement == nil {
                    geolocMainTitle.text = MapsUtils.addressLabel + "\n" + MapsUtils.boroughLabel
                } else if ContextManager.shared.typeContribution == .indoor {
                    geolocMainTitle.text = selectEquipement?.name
                }
                geolocImageView.backgroundColor = .clear
                geolocImageView.layer.borderWidth = 0
                geolocImageView.image = UIImage(named: Constants.Image.iconExit)
                geolocImageView.tintColor = .white
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeBtnTouchUp(_:)))
                geolocImageView.isUserInteractionEnabled = true
                geolocImageView.addGestureRecognizer(tapGestureRecognizer)
                geolocImageView.isAccessibilityElement = true
                geolocImageView.accessibilityLabel = Constants.LabelMessage.reduceBottomSheet
                geolocImageView.accessibilityTraits = .button
                applyDynamicType(label: geolocMainTitle, fontName: "Montserrat-Regular", size: 12.0)
            } else {
                customCell = tableView.dequeueReusableCell(withIdentifier: "localization_cell")
                customCell?.isAccessibilityElement = false
                let geolocMainTitle = customCell?.viewWithTag(102) as! UILabel
                let geolocSubtitle = customCell?.viewWithTag(103) as! UILabel
                let favoriteBtn = customCell?.viewWithTag(105) as! UIButton
                applyDynamicType(label: geolocMainTitle, fontName: "Montserrat-Regular", size: 12.0)
                applyDynamicType(label: geolocSubtitle, fontName: "Montserrat-Regular", size: 12.0)
                // Hidden by default
                geolocSubtitle.isHidden = true
                favoriteBtn.setTitle("", for: .normal)
                favoriteBtn.backgroundColor = .white
                favoriteBtn.accessibilityTraits = .button
                if ContextManager.shared.typeContribution == .outdoor {
                    showDetailAnomalie(forCell: customCell!)
                } else if ContextManager.shared.typeContribution == .indoor {
                    showDetailEquipement(forCell: customCell!)
                }
                if !isAlreadyInFavorites {
                    favoriteBtn.setImage(imgAddAddressFavorite, for: .normal)
                    favoriteBtn.accessibilityLabel = String(format: Constants.LabelMessage.addAdresseFavorite, MapsUtils.addressLabel)
                    let tapGestureRecognizer = MyTapGesture(target: self, action: #selector(addOrRemoveFavorite(recognizer:)))
                    tapGestureRecognizer.addFavorite = true
                    favoriteBtn.addGestureRecognizer(tapGestureRecognizer)
                } else {
                    favoriteBtn.setImage(imgRemoveddressFavorite, for: .normal)
                    favoriteBtn.accessibilityLabel = String(format: Constants.LabelMessage.removeAdresseFavorite, MapsUtils.addressLabel)
                    let tapGestureRecognizer = MyTapGesture(target: self, action: #selector(addOrRemoveFavorite(recognizer:)))
                    tapGestureRecognizer.addFavorite = false
                    favoriteBtn.addGestureRecognizer(tapGestureRecognizer)
                }
                
                if otherCellDisplay {
                    customCell?.backgroundColor = UIColor.pinkDmr()
                    geolocMainTitle.textColor = .white
                    geolocSubtitle.textColor = .white
                } else {
                    customCell?.backgroundColor = .white
                    geolocMainTitle.textColor = .black
                    geolocSubtitle.textColor = UIColor.greyDmr()
                }
                geolocMainTitle.isAccessibilityElement = true
                geolocMainTitle.accessibilityTraits = .staticText
                geolocSubtitle.isAccessibilityElement = true
                geolocSubtitle.accessibilityTraits = .staticText
            }
            
        case RowId.uberMode:
            customCell = tableView.dequeueReusableCell(withIdentifier: "preciser_position_cell")
            let precisionLabel = customCell?.viewWithTag(201) as! UILabel
            let precisionImage = customCell?.viewWithTag(202) as! UIImageView
            applyDynamicType(label: precisionLabel, fontName: "Montserrat-Regular", size: 12.0)
        
            if selectAnomalie != nil || selectEquipement != nil {
                precisionLabel.text = Constants.LabelMessage.addAnomaly.uppercased()
                precisionImage.image = UIImage(named: Constants.Image.addAnomalie)
            } else {
                precisionLabel.text = Constants.LabelMessage.preciserPosition.uppercased()
                precisionLabel.accessibilityLabel = Constants.LabelMessage.preciserPosition.uppercased()
                precisionLabel.accessibilityTraits = .button
                precisionImage.image = UIImage(named: Constants.Image.pinRose)
            }
            
            precisionLabel.textColor = UIColor.pinkDmr()
            bottomSheetTableView.isScrollEnabled = buttomSheetFullView
        case RowId.labelAnomaly:
            customCell = tableView.dequeueReusableCell(withIdentifier: "otherMalfunctionTitleCell")
            
            let otherAnomalieLabel = customCell?.viewWithTag(300) as! UILabel
            applyDynamicType(label: otherAnomalieLabel, fontName: "Montserrat-Light", size: 15.0)
            if ContextManager.shared.typeContribution == .indoor {
                otherAnomalieLabel.text = Constants.LabelMessage.otherAnomalieEquipementLabel
            } else {
                otherAnomalieLabel.text = Constants.LabelMessage.otherAnomalieLabel
            }
            otherAnomalieLabel.accessibilityTraits = .header
            otherAnomalieLabel.isAccessibilityElement = true
            
        default:
            customCell = tableView.dequeueReusableCell(withIdentifier: "otherMalfunctionCell")
            customCell?.accessibilityTraits = .button
            
            let otherMalfunction = otherMalfunctionsArray[indexPath.row - 3]
            let otherMalfunctionMainTitle = customCell?.viewWithTag(402) as! UILabel
            otherMalfunctionMainTitle.text = otherMalfunction.alias
            otherMalfunctionMainTitle.accessibilityLabel = otherMalfunction.alias
            otherMalfunctionMainTitle.accessibilityTraits = .staticText
            otherMalfunctionMainTitle.lineBreakMode = NSLineBreakMode.byTruncatingTail
            otherMalfunctionMainTitle.numberOfLines = 0
            applyDynamicType(label: otherMalfunctionMainTitle, fontName: "Montserrat-Regular", size: 14.0)
            let otherMalfunctionAddress = customCell?.viewWithTag(403) as! UILabel
            otherMalfunctionAddress.lineBreakMode = .byClipping
            otherMalfunctionAddress.numberOfLines = 0
            otherMalfunctionAddress.text = otherMalfunction.address + "\n" + otherMalfunction.number
            otherMalfunctionAddress.accessibilityLabel = otherMalfunction.address + "\n" + otherMalfunction.number
            otherMalfunctionAddress.accessibilityTraits = .staticText
            applyDynamicType(label: otherMalfunctionAddress, fontName: "Montserrat-Regular", size: 12.0)
            let otherMalfunctionImageView = customCell?.viewWithTag(401) as! UIImageView
            otherMalfunctionImageView.accessibilityTraits = .image
            let imageURL = (otherMalfunction.source == .ramen) ? URL(string: Constants.Image.ramen) : (URL(string: otherMalfunction.firstImageUrl) ?? URL(string: Constants.Image.noImage))
            
            otherMalfunctionImageView.sd_setImage(with: imageURL!, placeholderImage: otherMalfunction.imageCategorie, options: .allowInvalidSSLCertificates)
            if currentStatus == .full {
                bottomSheetTableView.isScrollEnabled = true
            } else {
                bottomSheetTableView.isScrollEnabled = false
            }
        }
        
        customCell?.selectionStyle = .none
        
        return customCell!
    }
    
    @objc private func closeBtnTouchUp(_ sender: UIButton) {
        animateBottomSheet(withDuration: 0.5, status: .none)
    }
    
    private func showDetailAnomalie(forCell customCell: UITableViewCell) {
        let geolocImageView = customCell.viewWithTag(101) as! UIImageView
        let geolocMainTitle = customCell.viewWithTag(102) as! UILabel
        
        if !buttomSheetFullView, let myAnomalie = selectAnomalie {
            geolocMainTitle.text = myAnomalie.alias
            
            // Affichage de l'adresse
            let geolocSubtitle = customCell.viewWithTag(103) as! UILabel
            geolocSubtitle.text = myAnomalie.address
            geolocSubtitle.isHidden = false
            
            if !buttomSheetFullView {
                let imageURL = URL(string: myAnomalie.firstImageUrl) ?? URL(string: Constants.Image.noImage)
                
                geolocImageView.sd_setImage(with: imageURL!, placeholderImage: myAnomalie.imageCategorie, options: .allowInvalidSSLCertificates)
                
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(displaySelectedAnomaly(_:)))
                
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
            let nameLbl: UILabel = addLabel(withText: myEquipement.name, andTag: 104)
            nameLbl.numberOfLines = 1
            nameLbl.lineBreakMode = .byTruncatingTail
            nameLbl.frame = CGRect(x: 15, y: 8, width: geolocMainTitle.frame.width + geolocImageView.frame.width, height: geolocMainTitle.frame.height)
            if otherCellDisplay {
                nameLbl.textColor = .white
            } else {
                nameLbl.textColor = .black
            }
            
            customCell.addSubview(nameLbl)
            
            // Affichage de l'adresse
            let addressLbl: UILabel = addLabel(withText: myEquipement.adresse, andTag: 103)
            addressLbl.frame = CGRect(x: nameLbl.frame.origin.x, y: nameLbl.frame.origin.y + 12, width: geolocMainTitle.frame.width + geolocImageView.frame.width, height: 30)
            addressLbl.numberOfLines = 2
            addressLbl.lineBreakMode = .byWordWrapping
            
            customCell.addSubview(addressLbl)
            
            // Affichage du nombre d'anomalie
            let nbAnoText = (myEquipement.anomalies.count > 1) ? "\(myEquipement.anomalies.count) \(Constants.LabelMessage.anomalieCountLabel)" : "\(myEquipement.anomalies.count) \(Constants.LabelMessage.anomalieCountOneLabel)"
            let nbAnoLbl: UILabel = addLabel(withText: nbAnoText, andTag: 888)
            nbAnoLbl.frame = CGRect(x: addressLbl.frame.origin.x, y: addressLbl.frame.origin.y + 17, width: addressLbl.frame.width, height: addressLbl.frame.height)
            nbAnoLbl.font = UIFont(name: Constants.fontDmr, size: 10)
            if otherCellDisplay {
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
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideUberPin(_:)))
        geolocImageView.addGestureRecognizer(tapGestureRecognizer)
        
        if let myAddress = selectedAddress {
            if let firstAddressLine = myAddress.thoroughfare {
                geolocMainTitle.text = firstAddressLine
                MapsUtils.addressLabel = firstAddressLine
            } else {
                // Si l'api renvoi le quartier et non l'adresse
                geolocMainTitle.text = myAddress.lines![0]
                MapsUtils.addressLabel = myAddress.lines![0]
                MapsUtils.postalCode = myAddress.lines![1].components(separatedBy: " ")[0]
                var arrondissement = (myAddress.subLocality?.components(separatedBy: CharacterSet.decimalDigits.inverted)[0])!
                if arrondissement == "1" {
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
            
            // Gestion de l'affichage du btn de gestion de favoris
            let favorites: [String] = getFavoritesAddress()
            for favorite in favorites {
                let favArr = favorite.components(separatedBy: Constants.Key.separatorAdresseCoordonate)
                
                // Vérification sur le nom de l'adresse
                if favArr[0] == MapsUtils.fullAddress() {
                    isAlreadyInFavorites = true
                }
                
                // Vérification sur les coordonnées
                if String(MapsUtils.userLocation()!.latitude) + "-" + String(MapsUtils.userLocation()!.longitude) == favArr[1] {
                    isAlreadyInFavorites = true
                }
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
    
    private func addLabel(withText: String, andTag newTag: Int) -> UILabel {
        let myLabel = UILabel()
        myLabel.numberOfLines = 1
        myLabel.lineBreakMode = .byWordWrapping
        myLabel.textColor = UIColor.greyDmr()
        myLabel.font = UIFont(name: Constants.fontDmr, size: 12)
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
        if (y == fullView && bottomSheetTableView.contentOffset.y == 0 && direction > 0) || (y == bottomSheetInitialY) || (y == UIScreen.main.bounds.height - 225) {
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
        parent?.navigationController?.navigationBar.isHidden = false
        parent?.navigationController?.navigationBar.tintColor = UIColor.white
        parent?.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.white])
        parent?.navigationController?.pushViewController(addAnomalyViewController, animated: true)
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}

// Class tapeGesture perso pour envoyre l'id en param
class MyTapGesture: UITapGestureRecognizer {
    var address = String()
    var addFavorite = Bool()
}

extension UILabel {
    var maxNumberOfLines: Int {
        let maxSize = CGSize(width: frame.size.width, height: CGFloat(MAXFLOAT))
        let text = (self.text ?? "") as NSString
        let textHeight = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil).height
        let lineHeight = font.lineHeight
        return Int(ceil(textHeight / lineHeight))
    }
}

extension BottomSheetViewController: CustomAlertViewDelegate {
    func okButtonTapped(textFieldValue: String) {
        searchAnomalyByNumber(number: textFieldValue)
    }
       
    func cancelButtonTapped() {
        print("cancelButtonTapped")
    }
}
