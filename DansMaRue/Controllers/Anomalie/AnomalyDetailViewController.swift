//
//  AnomalyDetailViewController.swift
//  DansMaRue
//
//  Created by Maxime Bureau on 20/04/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import AppAuth
import SDWebImage
import SwiftyJSON
import TTGSnackbar
import UIKit

protocol CustomNavigationDelegate: NSObjectProtocol {
    func displayAddAnomaly(anomalySelected: Anomalie)
}

enum AnomalieDetailStatus {
    case notsolved
    case solved
    case undefined
}

enum UpdateAnomalieStateStatus {
    case success
    case failure
    case nothing
}

class AnomalyDetailViewController: UIViewController, OIDAuthStateChangeDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    // MARK: - Properties

    var selectedAnomaly: Anomalie? = nil
    var currentAnomalyState = AnomalieDetailStatus.notsolved
    weak var customNavigationDelegate: CustomNavigationDelegate?
    var numberPhotoSelect = 1
    var idMessageServiceFait: String = ""
    
    // MARK: - IBOutlets

    @IBOutlet var detailsTableView: UITableView!
    
    @IBOutlet var detailView: UIView!
  
    let imgGreetingsButton = UIImage(named: Constants.Image.thumbsUp)
    let imgFollow = UIImage(named: Constants.Image.follow)
    let imgUnfollow = UIImage(named: Constants.Image.unfollow)
    let imgFollowDisabled = UIImage(named: Constants.Image.followDisabled)
    let imgChevronPrevious = UIImage(named: Constants.Image.iconBackChevron)
    let imgChevronNext = UIImage(named: Constants.Image.iconChevron)
    
    private var authState: OIDAuthState?
    typealias PostRegistrationCallback = (_ configuration: OIDServiceConfiguration?, _ registrationResponse: OIDRegistrationResponse?) -> Void
    let redirectURI: String = Constants.Authentification.RedirectURI
    let authStateKey: String = "authState"
    private var updateAnomlieState: UpdateAnomalieStateStatus = .nothing

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.detailsTableView.delegate = self
        self.detailsTableView.dataSource = self
        self.detailsTableView.estimatedRowHeight = 186
        self.detailsTableView.rowHeight = UITableView.automaticDimension
        self.numberPhotoSelect = 1
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.detailsTableView.layoutIfNeeded()
        self.detailsTableView.reloadData()
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: nil)
    }
 
    // Navigation entre photos
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizer.Direction.right:
                print("Swiped right")
                if self.numberPhotoSelect > 1 {
                    self.numberPhotoSelect -= 1
                }
                self.detailsTableView.reloadData()
            case UISwipeGestureRecognizer.Direction.left:
                print("Swiped left")
                if self.numberPhotoSelect < (self.selectedAnomaly?.nbPhoto)! {
                    self.numberPhotoSelect += 1
                }
                self.detailsTableView.reloadData()
            default:
                break
            }
        }
    }

    // MARK: - IBActions

    @objc func closeWindow(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func editAnomaly(_ sender: Any) {
        self.dismiss(animated: true) {
            self.customNavigationDelegate?.displayAddAnomaly(anomalySelected: self.selectedAnomaly!)
        }
    }

    @objc func seePreviousPhoto(_ sender: UIButton) {
        if self.numberPhotoSelect > 1 {
            self.numberPhotoSelect -= 1
            self.detailsTableView.reloadData()
        }
    }
    
    @objc func seeNextPhoto(_ sender: UIButton) {
        if self.numberPhotoSelect < (self.selectedAnomaly?.nbPhoto)! {
            self.numberPhotoSelect += 1
            self.detailsTableView.reloadData()
        }
    }
   
    private func setPhotoURL() -> URL {
        var imageURL = URL(string: Constants.Image.noImage)
        
        switch self.numberPhotoSelect {
        case 1:
            if (self.selectedAnomaly?.firstImageUrl.isEmpty)! {
                imageURL = URL(string: (self.selectedAnomaly?.photoDoneUrl)!) ?? URL(string: Constants.Image.noImage)
        
            } else {
                // on a juste la photo done
                imageURL = URL(string: (self.selectedAnomaly?.firstImageUrl)!) ?? URL(string: Constants.Image.noImage)
            }
        case 2:
            // 1 image de l'ano (close ou far) + 1 photo done
            if URL(string: (self.selectedAnomaly?.firstImageUrl)!) == URL(string: (self.selectedAnomaly?.secondImageUrl)!) {
                imageURL = URL(string: (self.selectedAnomaly?.photoDoneUrl)!) ?? URL(string: Constants.Image.noImage)
            } else {
                // Pas de photo done
                imageURL = URL(string: (self.selectedAnomaly?.secondImageUrl)!) ?? URL(string: Constants.Image.noImage)
            }

        case 3:
            imageURL = URL(string: (self.selectedAnomaly?.photoDoneUrl)!) ?? URL(string: Constants.Image.noImage)
        default:
            break
        }
        
        return imageURL!
    }

    // Abonnement ou désabonnement du suivi de l'anomalie
    @objc func doAwesomeFeature(followButton: UIButton) {
        if !User.shared.isLogged {
            followButton.setImage(self.imgFollow, for: .normal)
            followButton.accessibilityLabel = Constants.LabelMessage.followAnomaly
            // Redirection vers le Compte Parisien
            self.connectToMonParis()
        } else {
            var hasFollow = false
            if let anomalie = selectedAnomaly {
                hasFollow = self.selectedAnomaly?.isIncidentFollowedByUser ?? false
                followButton.isEnabled = false
                if !hasFollow {
                    DispatchQueue.global().async {
                        RestApiManager.sharedInstance.follow(anomalie: anomalie, onCompletion: { (result: Bool) in
                            DispatchQueue.main.async {
                                if result {
                                    // Mise à jour de l'UI
                                    
                                    self.selectedAnomaly?.isIncidentFollowedByUser = true
                                    self.selectedAnomaly?.followers += 1
                                    self.detailsTableView.reloadData()
                                    followButton.setImage(self.imgUnfollow, for: .normal)
                                    followButton.accessibilityLabel = Constants.LabelMessage.unfollowAnomaly
                                    let snackbar = TTGSnackbar(message: Constants.AlertBoxMessage.followMalfunction, duration: .middle)
                                    
                                    snackbar.actionTextColor = UIColor.pinkDmr()
                                    snackbar.actionTextFont = UIFont(name: Constants.fontDmr, size: 14.0)!
                                    snackbar.messageTextFont = UIFont(name: Constants.fontDmr, size: 15.0)!
                                    snackbar.messageTextAlign = NSTextAlignment.center
                                    
                                    snackbar.show()
                                    UIAccessibility.post(notification: .announcement, argument: Constants.AlertBoxMessage.followMalfunction)
                                } else {
                                    self.showPopupMaintenance()
                                }
                                
                                followButton.isEnabled = true
                            }
                        })
                    }
                } else {
                    DispatchQueue.global().async {
                        RestApiManager.sharedInstance.unfollow(anomalie: anomalie, onCompletion: { (result: Bool) in
                            DispatchQueue.main.async {
                                if result {
                                    // Mise à jour de l'UI
                                    
                                    self.selectedAnomaly?.isIncidentFollowedByUser = false
                                    self.selectedAnomaly?.followers -= 1
                                    self.detailsTableView.reloadData()
                                    followButton.setImage(self.imgFollow, for: .normal)
                                    followButton.accessibilityLabel = Constants.LabelMessage.followAnomaly
                                    let snackbar = TTGSnackbar(message: Constants.AlertBoxMessage.unfollowMalfunction, duration: .middle)
                                    
                                    snackbar.actionTextColor = UIColor.pinkDmr()
                                    snackbar.actionTextFont = UIFont(name: Constants.fontDmr, size: 14.0)!
                                    snackbar.messageTextFont = UIFont(name: Constants.fontDmr, size: 15.0)!
                                    snackbar.messageTextAlign = NSTextAlignment.center
                                    
                                    snackbar.show()
                                    UIAccessibility.post(notification: .announcement, argument: Constants.AlertBoxMessage.unfollowMalfunction)
                                } else {
                                    self.showPopupMaintenance()
                                }
                                
                                followButton.isEnabled = true
                            }
                        })
                    }
                }
            }
        }
    }

    func didChange(_ state: OIDAuthState) {
        self.setAuthState(state)
    }
     
    func connectToMonParis() {
        let authorizationEndpoint = Constants.Authentification.authorizationEndpoint
        let tokenEndpoint = Constants.Authentification.tokenEndpoint
        let configuration = OIDServiceConfiguration(authorizationEndpoint: authorizationEndpoint,
                                                    tokenEndpoint: tokenEndpoint)
        
        self.doAuthWithAutoCodeExchange(configuration: configuration,
                                        clientID: Constants.Authentification.clientID,
                                        clientSecret: nil)
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
            userDefaults.set(data, forKey: self.authStateKey)
            userDefaults.synchronize()
        }
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
        let currentAccessToken: String? = self.authState?.lastTokenResponse?.accessToken

        self.authState?.performAction { accessToken, _, error in
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
                            }
                        }
                    }
                }
            }

            task.resume()
        }
    }

    @objc func congratsTheAnomaly(congratsButton: UIButton) {
        if !User.shared.isLogged {
            self.connectToMonParis()
        } else {
            var cancelAction = false
            congratsButton.isEnabled = false
            congratsButton.backgroundColor = UIColor.greyDmr()
            
            let snackbar = TTGSnackbar(message: Constants.AlertBoxMessage.congratulate, duration: .middle, actionText: Constants.AlertBoxTitle.annuler)
                { _ in
                    cancelAction = true
                    congratsButton.isEnabled = true
                    self.detailsTableView.reloadData()
                    congratsButton.backgroundColor = UIColor.greenDmr()
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
                        RestApiManager.sharedInstance.congratulateAnomalie(anomalie: (self.selectedAnomaly)!, onCompletion: { (result: Bool) in
                            
                            if result {
                                // Mise à jour de l'UI
                                DispatchQueue.main.async {
                                    self.selectedAnomaly?.congratulations += 1
                                    self.detailsTableView.reloadData()
                                    congratsButton.isHidden = true
                                }
                                self.updateAnomlieState = .success
                            } else {
                                self.updateAnomlieState = .failure
                            }
                            self.detailsTableView.reloadData()
                        })
                    }
                }
            }
            snackbar.show()
        }
    }
    
    @objc func solvedAction(solvedButton: UIButton) {
        let isAnomalieFromRamen = self.selectedAnomaly!.number.uppercased().starts(with: "W")
        
        if isAnomalieFromRamen && self.selectedAnomaly!.resolvedAuthorization {
            // Affichage alert selection message service fait
            let alert = UIAlertController(title: "Choisir un message ci-dessous", message: "\n\n\n\n\n\n\n\n\n", preferredStyle: UIAlertController.Style.alert)
            alert.isModalInPopover = true
            let pickerFrame: CGRect = .init(x: 5, y: 70, width: 250, height: 140)
            let picker: UIPickerView = .init(frame: pickerFrame)
            picker.delegate = self
            picker.dataSource = self
            alert.view.addSubview(picker)
        
            if selectedAnomaly!.messagesSFTypologie.count>0 {
                idMessageServiceFait = selectedAnomaly!.messagesSFTypologie[0].id
            }
                
            let OKAction = UIAlertAction(title: Constants.AlertBoxTitle.ok, style: .default, handler: { (_: UIAlertAction!) in
                self.doSolvedAction(solvedButton: solvedButton)
            })
            alert.addAction(OKAction)
             
            self.present(alert, animated: true, completion: nil)
        }
        else {
            self.doSolvedAction(solvedButton: solvedButton)
        }
        
    }
    
    func doSolvedAction(solvedButton: UIButton) {
        solvedButton.isEnabled = false
        solvedButton.backgroundColor = UIColor.greyDmr()
        var cancelAction = false
        
        let snackbar = TTGSnackbar(message: Constants.AlertBoxMessage.solvedMalfunction, duration: .middle, actionText: Constants.AlertBoxTitle.annuler)
            { _ in
                cancelAction = true
                solvedButton.isEnabled = true
                solvedButton.backgroundColor = UIColor.pinkDmr()
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
                    RestApiManager.sharedInstance.incidentResolved(anomalie: (self.selectedAnomaly)!, numeroMessage: self.idMessageServiceFait, email: User.shared.email ?? "", onCompletion: { (result: Bool) in
                        DispatchQueue.main.async {
                            if result {
                                let snackbar = TTGSnackbar(message: Constants.AlertBoxMessage.anomalieResolue, duration: .middle)
                                
                                snackbar.messageTextFont = UIFont(name: Constants.fontDmr, size: 15.0)!
                                snackbar.messageTextAlign = NSTextAlignment.center
                                snackbar.show()
                                self.updateAnomlieState = UpdateAnomalieStateStatus.success
                                self.currentAnomalyState = .solved
                            } else {
                                self.updateAnomlieState = UpdateAnomalieStateStatus.failure
                                self.showPopupMaintenance()
                            }
                            self.detailsTableView.reloadData()
                        }
                    })
                }
            }
        }
        snackbar.show()
    }
    
    func showPopupMaintenance() {
        let alert = UIAlertController(title: Constants.AlertBoxTitle.information, message: Constants.AlertBoxMessage.maintenance, preferredStyle: UIAlertController.Style.alert)
        let okBtn = UIAlertAction(title: "Ok", style: .default, handler: { (_: UIAlertAction) in
        })
        alert.addAction(okBtn)
        self.present(alert, animated: true, completion: nil)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.selectedAnomaly!.messagesSFTypologie.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return selectedAnomaly!.messagesSFTypologie[row].message
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        idMessageServiceFait = selectedAnomaly!.messagesSFTypologie[row].id
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel();
            pickerLabel?.font = UIFont(name: "Montserrat", size: 13.0)!
        }
        pickerLabel?.text = selectedAnomaly!.messagesSFTypologie[row].message

        return pickerLabel!
    }
  
    private func applyDynamicTypeSystemFont(label: UILabel, size: Float) {
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .title3)
    }
}

extension AnomalyDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var customCell: UITableViewCell
        switch indexPath.row {
        case 0: customCell = self.configureHeaderCellView(tableView: tableView, anomalie: self.selectedAnomaly!)
        case 1: customCell = self.configureDetailsCellView(tableView: tableView, anomalie: self.selectedAnomaly!)
        case 2: customCell = self.configureButtonsCellView(tableView: tableView, anomalie: self.selectedAnomaly!)
        default:
            customCell = UITableViewCell()
        }
        return customCell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    private func configureHeaderCellView(tableView: UITableView, anomalie: Anomalie) -> UITableViewCell {
        var customCell: UITableViewCell
        customCell = tableView.dequeueReusableCell(withIdentifier: "header_cell")!
        let anomalyMainImageView = customCell.viewWithTag(100) as! UIImageView
        let anomalyCloseButton = customCell.viewWithTag(101) as! UIButton
        let anomalyEditButton = customCell.viewWithTag(102) as! UIButton
        let previousButton = customCell.viewWithTag(103) as! UIButton
        let nextButton = customCell.viewWithTag(104) as! UIButton
        let followButton = customCell.viewWithTag(105) as! UIButton
        let anomalySolvedLabel = customCell.viewWithTag(106) as! UILabel
        let anomalyInProgressLabel = customCell.viewWithTag(107) as! UILabel
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        
        swipeRight.direction = UISwipeGestureRecognizer.Direction.right
        swipeLeft.direction = UISwipeGestureRecognizer.Direction.left
        
        anomalyMainImageView.isUserInteractionEnabled = true
        anomalyMainImageView.addGestureRecognizer(swipeRight)
        anomalyMainImageView.addGestureRecognizer(swipeLeft)
        anomalyMainImageView.contentMode = .scaleAspectFit
        anomalyMainImageView.sd_setImage(with: self.setPhotoURL(), placeholderImage: anomalie.imageCategorie, options: .allowInvalidSSLCertificates)
    
        anomalyCloseButton.addTarget(self, action: #selector(self.closeWindow(_:)), for: .touchUpInside)
        anomalyCloseButton.accessibilityLabel = Constants.TitleButton.close
        anomalyEditButton.addTarget(self, action: #selector(self.editAnomaly(_:)), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(self.seeNextPhoto(_:)), for: .touchUpInside)
        
        previousButton.addTarget(self, action: #selector(self.seePreviousPhoto(_:)), for: .touchUpInside)
        followButton.setImage(self.imgFollowDisabled, for: .disabled)
        followButton.addTarget(self, action: #selector(self.doAwesomeFeature(followButton:)), for: .touchUpInside)
        let tintedImageBack = self.imgChevronPrevious?.withRenderingMode(.alwaysTemplate)
        previousButton.setImage(tintedImageBack, for: .normal)
        previousButton.tintColor = .white
        
        let tintedImageNext = self.imgChevronNext?.withRenderingMode(.alwaysTemplate)
        nextButton.setImage(tintedImageNext, for: .normal)
        nextButton.tintColor = .white

        previousButton.isHidden = anomalie.nbPhoto <= 1
        nextButton.isHidden = anomalie.nbPhoto <= 1

        switch self.currentAnomalyState {
        case .notsolved:
            anomalyCloseButton.isHidden = false
            anomalyEditButton.isHidden = true
            
            anomalySolvedLabel.isHidden = true
            
            anomalyInProgressLabel.isHidden = false
            anomalyInProgressLabel.text = Constants.LabelMessage.anomalieInProgress
            anomalyInProgressLabel.layer.masksToBounds = true
            anomalyInProgressLabel.layer.cornerRadius = 15
            
            anomalyInProgressLabel.backgroundColor = UIColor.orangeDmr()
            followButton.isAccessibilityElement = true
            followButton.accessibilityTraits = .button
            anomalyMainImageView.contentMode = .scaleAspectFit
            anomalyMainImageView.sd_setImage(with: self.setPhotoURL(), placeholderImage: anomalie.imageCategorie, options: .allowInvalidSSLCertificates)
    
            if !anomalie.isIncidentFollowedByUser {
                followButton.isHidden = false
                followButton.isEnabled = anomalie.source == .dmr
                followButton.setImage(self.imgFollow, for: .normal)
                followButton.accessibilityLabel = Constants.LabelMessage.followAnomaly
                followButton.accessibilityHint = Constants.LabelMessage.followAnomaly
            } else {
                followButton.isHidden = false
                followButton.isEnabled = true
                followButton.setImage(self.imgUnfollow, for: .normal)
                followButton.accessibilityLabel = Constants.LabelMessage.unfollowAnomaly
                followButton.accessibilityHint = Constants.LabelMessage.unfollowAnomaly
            }
        case .solved:
            anomalyCloseButton.isHidden = false
            anomalyEditButton.isHidden = true
            followButton.isHidden = true
            anomalyInProgressLabel.isHidden = true
            anomalySolvedLabel.isHidden = false
            anomalySolvedLabel.numberOfLines = 0
            anomalySolvedLabel.text = Constants.LabelMessage.anomalieSolved
            anomalySolvedLabel.layer.masksToBounds = true
            anomalySolvedLabel.layer.cornerRadius = 15
            anomalySolvedLabel.backgroundColor = UIColor.greenDmr()
        default:
            anomalyCloseButton.isHidden = false
            anomalyEditButton.isHidden = false
            followButton.isHidden = false
            anomalySolvedLabel.isHidden = false
            anomalyInProgressLabel.isHidden = true
        }
        anomalyInProgressLabel.adjustsFontForContentSizeCategory = true
        anomalyInProgressLabel.font = UIFont.scaledFont(name: "Montserrat-Regular", textSize: 13.0)
        anomalyInProgressLabel.sizeToFit()
        anomalySolvedLabel.adjustsFontForContentSizeCategory = true
        anomalySolvedLabel.font = UIFont.scaledFont(name: "Montserrat-Regular", textSize: 13.0)
        
        if self.updateAnomlieState == .success {
            anomalySolvedLabel.isHidden = false
            anomalySolvedLabel.text = Constants.LabelMessage.anomalieSolved
            anomalySolvedLabel.layer.cornerRadius = 15
            anomalySolvedLabel.backgroundColor = UIColor.greenDmr()
            anomalyInProgressLabel.isHidden = true
            followButton.isHidden = true
        }
        return customCell
    }
    
    private func configureDetailsCellView(tableView: UITableView, anomalie: Anomalie) -> UITableViewCell {
        var customCell: UITableViewCell
        customCell = tableView.dequeueReusableCell(withIdentifier: "details_cell")!
        customCell.isAccessibilityElement = false
        let anomalyStreetLabel = customCell.viewWithTag(101) as! UILabel
        let anomalyStreetBisLabel = customCell.viewWithTag(102) as! UILabel
        let timelineLabel = customCell.viewWithTag(103) as! UILabel
        let mainTitleLabel = customCell.viewWithTag(104) as! UILabel
        let anomalyDescriptionLabel = customCell.viewWithTag(105) as! UILabel
        let concernedLabel = customCell.viewWithTag(106) as! UILabel
        let greetingsLabel = customCell.viewWithTag(107) as! UILabel
        anomalyStreetLabel.isAccessibilityElement = true
        anomalyStreetLabel.accessibilityTraits = .staticText
        anomalyStreetBisLabel.isAccessibilityElement = true
        anomalyStreetBisLabel.accessibilityTraits = .staticText
        timelineLabel.isAccessibilityElement = true
        timelineLabel.accessibilityTraits = .staticText
        mainTitleLabel.isAccessibilityElement = true
        mainTitleLabel.accessibilityTraits = .staticText
        anomalyDescriptionLabel.isAccessibilityElement = true
        anomalyDescriptionLabel.accessibilityTraits = .staticText
        concernedLabel.isAccessibilityElement = true
        concernedLabel.accessibilityTraits = .staticText
        greetingsLabel.isAccessibilityElement = true
        greetingsLabel.accessibilityTraits = .staticText
        let postalCode = MapsUtils.getPostalCode(address: anomalie.address)
      
        mainTitleLabel.text = anomalie.alias
        anomalyDescriptionLabel.text = anomalie.descriptive
        anomalyStreetLabel.text = MapsUtils.getStreetAddress(address: anomalie.address)
        anomalyStreetBisLabel.text = MapsUtils.boroughLabel(postalCode: postalCode)
        timelineLabel.text = DateUtils.formatDateByLocal(dateString: anomalie.date) + " " + anomalie.hour + "\n" + anomalie.number
        timelineLabel.lineBreakMode = .byClipping
        timelineLabel.numberOfLines = 0
        concernedLabel.isHidden = anomalie.source == .ramen
        concernedLabel.text = "\(anomalie.followers) intéressé(e)s"
        greetingsLabel.isHidden = self.currentAnomalyState == .notsolved
        greetingsLabel.text = "\(anomalie.congratulations) félicitation(s)"
        
        anomalyStreetLabel.adjustsFontForContentSizeCategory = true
        anomalyStreetLabel.font = UIFont.scaledFont(name: "Montserrat-Regular", textSize: 14.0)
        anomalyStreetBisLabel.adjustsFontForContentSizeCategory = true
        anomalyStreetBisLabel.font = UIFont.scaledFont(name: "Montserrat-Regular", textSize: 12.0)
        timelineLabel.adjustsFontForContentSizeCategory = true
        timelineLabel.font = UIFont.scaledFont(name: "Montserrat-Regular", textSize: 14.0)
        mainTitleLabel.adjustsFontForContentSizeCategory = true
        mainTitleLabel.font = UIFont.scaledFont(name: "Montserrat-Regular", textSize: 24.0)
        anomalyDescriptionLabel.adjustsFontForContentSizeCategory = true
        anomalyDescriptionLabel.font = UIFont.scaledFont(name: "Montserrat-Regular", textSize: 14.0)
        concernedLabel.adjustsFontForContentSizeCategory = true
        concernedLabel.font = UIFont.scaledFont(name: "Montserrat-Regular", textSize: 14.0)
        greetingsLabel.adjustsFontForContentSizeCategory = true
        greetingsLabel.font = UIFont.scaledFont(name: "Montserrat-Regular", textSize: 14.0)
        if self.updateAnomlieState == .success {
            greetingsLabel.isHidden = false
        }
        return customCell
    }
    
    private func configureButtonsCellView(tableView: UITableView, anomalie: Anomalie) -> UITableViewCell {
        var customCell: UITableViewCell
        customCell = tableView.dequeueReusableCell(withIdentifier: "buttons_cell")!
        let solvedButton = customCell.viewWithTag(101) as! UIButton_Solved
        solvedButton.titleLabel?.adjustsFontForContentSizeCategory = true
        solvedButton.titleLabel?.font = UIFont.scaledFont(name: "Montserrat-Regular", textSize: 15.0)
        let congratsButton = customCell.viewWithTag(102) as! UIButton_Congrats
        congratsButton.titleLabel?.adjustsFontForContentSizeCategory = true
        congratsButton.titleLabel?.font = UIFont.scaledFont(name: "Montserrat-Regular", textSize: 18.0)
        
        if anomalie.resolvedAuthorization {
            solvedButton.isHidden = false
            congratsButton.isHidden = true
        } else {
            congratsButton.isHidden = true
            solvedButton.isEnabled = false
            solvedButton.backgroundColor = UIColor.greyDmr()
        }
        solvedButton.addTarget(self, action: #selector(self.solvedAction(solvedButton:)), for: .touchUpInside)
        congratsButton.isHidden = self.currentAnomalyState != .solved
        congratsButton.addTarget(self, action: #selector(self.congratsTheAnomaly(congratsButton:)), for: .touchUpInside)
        if self.updateAnomlieState == .success {
            solvedButton.isHidden = true
            congratsButton.isHidden = false
        }
        if self.updateAnomlieState == .failure {
            solvedButton.backgroundColor = UIColor.pinkDmr()
            solvedButton.isEnabled = true
        }
        if self.currentAnomalyState == .solved {
            solvedButton.isHidden = true
        }
        congratsButton.isEnabled = self.selectedAnomaly?.source == .dmr
        return customCell
    }
}
