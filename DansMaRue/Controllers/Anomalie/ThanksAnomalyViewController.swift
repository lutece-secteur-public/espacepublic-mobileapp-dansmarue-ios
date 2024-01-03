//
//  ThanksAnomalyViewController.swift
//  DansMaRue
//
//  Created by NTDC-Showroom on 13/04/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import AppAuth
import SwiftyJSON
import TTGSnackbar
import UIKit

protocol CloseDelegate: NSObjectProtocol {
    func displayMap()
    func displayThanks()
}

public enum ThanksAnomalyStatus: String {
    case showMail = "M"
    case showThanks = "T"
    case saveIncident = "S"
}

class ThanksAnomalyViewController: UIViewController, OIDAuthStateChangeDelegate {
    func didChange(_ state: OIDAuthState) {
        setAuthState(state)
    }
    
    // MARK: - Properties

    var currentAnomaly: Anomalie?
    weak var closeDelegate: CloseDelegate?
    @IBOutlet weak var greyView: UIView!

    var confirmAction: UIAlertAction?
    var status: ThanksAnomalyStatus = .showMail
    var typeContribution: TypeContribution = .outdoor
    
    var timer: Timer = .init()
    var timerInterval = 90 // Interval de 90 secondes
    
    private var authState: OIDAuthState?
    typealias PostRegistrationCallback = (_ configuration: OIDServiceConfiguration?, _ registrationResponse: OIDRegistrationResponse?) -> Void
    let redirectURI: String = Constants.Authentification.RedirectURI
    let authStateKey: String = "authState"

    // MARK: - IBoutlets
 
    @IBOutlet var checkImage: UIImageView!
    @IBOutlet var thanksLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var closeButton: UIButton!
    
    // MARK: - IBactions

    @IBAction func closeModal(_ sender: Any) {
        if status == .showMail {
            // Cas de la demande de mail. On sauvegarde l'anomalie et on ferme la view
            saveAndClose()
        } else {
            // Cas du message de remerciement. On ferme la view et on revient sur la map
            dismiss(animated: true)
            closeDelegate?.displayMap()
        }
    }
    
    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        if status == .showThanks {
            let originalImage = UIImage(named: Constants.Image.iconExit)
            let tintedImage = originalImage?.withRenderingMode(.alwaysTemplate)
            closeButton.setImage(tintedImage, for: .normal)
            closeButton.tintColor = UIColor.greyDmr()
        } else if status == .saveIncident {
            saveAndClose()
        }
    }
    
    // MARK: - Other function

    @objc func textFieldDidChange(textToCheck: UITextField) {
        if !textToCheck.text!.isValidEmail() {
            confirmAction?.isEnabled = false
        } else {
            confirmAction?.isEnabled = true
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
                                    self.currentAnomaly?.mailUser = User.shared.email!
                                    self.saveAndClose()
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
    
    func saveAndClose() {
        // Start the timer
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(timerInterval), target: self, selector: #selector(ThanksAnomalyViewController.closeForTimeout), userInfo: nil, repeats: true)

        DispatchQueue.main.async {
            SaveAnomalyActivityIndicator.shared.showOverlay(self.view, self.greyView.frame)
        }
                
        DispatchQueue.global().async {
            // Envoie de la requete si l'utilisateur se connecte avec son compte parisien ou entre son adresse mail.
            RestApiManager.sharedInstance.saveIncident(anomalie: self.currentAnomaly!) { (result: Bool) in
                
                if result {
                    print("Enregistrement des photos pour l'incident \(result)")
                    
                    DispatchQueue.main.async {
                        SaveAnomalyActivityIndicator.shared.hideOverlayView()
                        self.dismiss(animated: true)
                        self.closeDelegate?.displayThanks()
                    }
                } else {
                    print("Erreur sur l'enregistrement de l'incident")
                    self.closeForTimeout()
                }
            }
        }        
    }
    
    @objc func closeForTimeout() {
        timer.invalidate()
        
        // message alerte
        let alertController = UIAlertController(title: Constants.AlertBoxTitle.information, message: Constants.AlertBoxMessage.errorSaveLabel, preferredStyle: .alert)
        // Create OK button
        let OKAction = UIAlertAction(title: Constants.AlertBoxTitle.ok, style: .default) {
            (_: UIAlertAction!) in
            
            SaveAnomalyActivityIndicator.shared.hideOverlayView()
            self.currentAnomaly?.anomalieStatus = .Brouillon
            self.currentAnomaly?.saveToDraft()
            self.dismiss(animated: true)
            self.closeDelegate?.displayMap()
        }
        alertController.addAction(OKAction)
        
        // Present Dialog message
        present(alertController, animated: true, completion: nil)
    }
}

class SaveAnomalyActivityIndicator: UIActivityIndicatorView {
    var overlayView = UIView()
    var backView = UIView()
    
    var activityIndicator = UIActivityIndicatorView()
    
    class var shared: SaveAnomalyActivityIndicator {
        enum Static {
            static let instance: SaveAnomalyActivityIndicator = .init()
        }
        return Static.instance
    }
    
    open func showOverlay(_ view: UIView, _ frame: CGRect) {
        overlayView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height + 25)
        backView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        backView.center = view.center
        let white = UIColor(red: 1 / 255, green: 0 / 255, blue: 0 / 255, alpha: 0.0)
        
        backView.backgroundColor = white
        view.addSubview(backView)
        
        overlayView.center = view.center
        overlayView.backgroundColor = UIColor.white
        overlayView.clipsToBounds = true
        // overlayView.layer.cornerRadius = 10

        // Create wait label
        let waitLabel = UILabel()
        waitLabel.text = Constants.LabelMessage.waitLabel
        waitLabel.frame = CGRect(x: 0, y: 10, width: frame.width, height: 50)
        waitLabel.numberOfLines = 2
        waitLabel.lineBreakMode = .byWordWrapping
        waitLabel.textColor = .black
        waitLabel.font = UIFont(name: Constants.fontDmr, size: 16)
        waitLabel.textAlignment = .center
        waitLabel.tag = 100
        
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        // activityIndicator.center = overlayView.center
        activityIndicator.transform = CGAffineTransform(scaleX: 3, y: 3)
        activityIndicator.style = .white
        activityIndicator.color = UIColor.pinkDmr()
        activityIndicator.center = CGPoint(x: overlayView.bounds.width / 2, y: overlayView.bounds.height / 2 + 30)
        
        overlayView.addSubview(waitLabel)
        overlayView.addSubview(activityIndicator)
        view.addSubview(overlayView)
        activityIndicator.startAnimating()
    }
    
    open func hideOverlayView() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        overlayView.removeFromSuperview()
        backView.removeFromSuperview()
        if let viewWithTag = overlayView.viewWithTag(100) {
            viewWithTag.removeFromSuperview()
        }
    }
}
