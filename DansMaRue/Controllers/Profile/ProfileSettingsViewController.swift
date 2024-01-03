//
//  ProfileSettingsViewController.swift
//  DansMaRue
//
//  Created by Maxime Bureau on 14/04/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import AppAuth
import SafariServices
import UIKit

class ProfileSettingsViewController: UIViewController, OIDAuthStateChangeDelegate, SFSafariViewControllerDelegate {
    func didChange(_ state: OIDAuthState) {
        self.setAuthState(state)
    }

    // MARK: - Properties

    var settingsArray = ["Mon profil", "Mes anomalies", "Actualités", "Aide et conseils d'utilisation", "Préférences", "Conditions générales d'utilisation", "Politique de confidentialité et de vie privée - Ville de Paris", "À Propos"]
    private var authState: OIDAuthState?
    typealias PostRegistrationCallback = (_ configuration: OIDServiceConfiguration?, _ registrationResponse: OIDRegistrationResponse?) -> Void
    let redirectURI: String = Constants.Authentification.RedirectURI
    let authStateKey: String = "authState"

    // MARK: - IBOutlets

    @IBOutlet var settingsTableView: UITableView!
    @IBOutlet var logoutBtn: UIButton!

    // MARK: - IBActions

    @IBAction func logoutCompteParisien(_ sender: Any) {
        if User.shared.isLogged {
            // Deconnexion de l'utilisateur
            if let token = self.authState?.lastTokenResponse?.accessToken {
                RestApiManager.sharedInstance.logoutMonParis(token: token) { (_: Bool) in
                    User.shared.disconnect()
                    self.displayLoginLogoutBtn()
                }
            } else {
                User.shared.disconnect()
                self.displayLoginLogoutBtn()
            }
            self.setAuthState(nil)
        }
    }

    @IBAction func loginToCompteParisien(_ sender: Any) {
        self.connectToMonParis()
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.barTintColor = UIColor.pinkDmr()
        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.white])

        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.pinkButtonDmr()
            appearance.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.white])!
            self.navigationController?.navigationBar.standardAppearance = appearance
            self.navigationController?.navigationBar.scrollEdgeAppearance = self.navigationController?.navigationBar.standardAppearance
        }
        self.applyDynamicType(label: self.logoutBtn.titleLabel!, fontName: "Montserrat-Regular", size: 16.0)
        self.settingsTableView.tableFooterView = UIView()
        self.displayLoginLogoutBtn()
    }

    override func viewDidAppear(_ animated: Bool) {
        self.displayLoginLogoutBtn()
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: navigationItem.titleView)
    }

    // MARK: - Private function

    func authorizationSettings() {
        let alertController = UIAlertController(title: Constants.AlertBoxTitle.modificationPreferences, message: Constants.AlertBoxMessage.modificationPreferences, preferredStyle: UIAlertController.Style.alert)

        let settingsAction = UIAlertAction(title: Constants.AlertBoxTitle.reglages, style: UIAlertAction.Style.default) { _ in
            let settingsUrl = NSURL(string: UIApplication.openSettingsURLString)
            if let url = settingsUrl {
                UIApplication.shared.openURL(url as URL)
            }
        }

        let cancelAction = UIAlertAction(title: Constants.AlertBoxTitle.annuler, style: UIAlertAction.Style.default, handler: nil)
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }

    func displayLoginLogoutBtn() {
        if User.shared.isLogged {
            self.logoutBtn.backgroundColor = UIColor.clear
            self.logoutBtn.setTitleColor(UIColor.pinkDmr(), for: .normal)
            self.logoutBtn.setTitle(Constants.TitleButton.deconnecter.uppercased(), for: .normal)
            self.logoutBtn.isAccessibilityElement = true
            self.logoutBtn.accessibilityTraits = .button
            self.logoutBtn.isHidden = false
            self.settingsArray[0] = "Mon profil"
            self.settingsTableView.reloadData()
        } else {
            self.logoutBtn.isHidden = true
            self.settingsArray[0] = "Se connecter"
            self.settingsTableView.reloadData()
        }
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
                                self.displayLoginLogoutBtn()
                            }
                        }
                    }
                }
            }

            task.resume()
        }
    }

    private func applyDynamicType(label: UILabel, fontName: String, size: Float) {
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.scaledFont(name: fontName, textSize: CGFloat(size))
    }
}

extension ProfileSettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        if indexPath.row == 0 && !User.shared.isLogged {
            cell = tableView.dequeueReusableCell(withIdentifier: "settings_cell")!
            let title = cell.viewWithTag(101) as! UILabel
            title.text = self.settingsArray[indexPath.row]
            self.applyDynamicType(label: title, fontName: "Montserrat-Regular", size: 14.0)
            cell.isAccessibilityElement = true
            cell.accessibilityTraits = .button
            cell.accessibilityLabel = self.settingsArray[indexPath.row]

            let loginBtn = cell.viewWithTag(102) as! UIButton
            loginBtn.setTitle(Constants.TitleButton.monCompte.uppercased(), for: .normal)
            loginBtn.isHidden = false
            loginBtn.backgroundColor = UIColor.pinkButtonDmr()
            loginBtn.tintColor = UIColor.white
            loginBtn.layer.cornerRadius = 10
            self.applyDynamicType(label: loginBtn.titleLabel!, fontName: "Montserrat-Regular", size: 14.0)
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "profil_cell")!
            let title = cell.viewWithTag(101) as! UILabel
            title.text = self.settingsArray[indexPath.row]
            title.numberOfLines = 0
            self.applyDynamicType(label: title, fontName: "Montserrat-Regular", size: 14.0)
            cell.isAccessibilityElement = true
            cell.accessibilityTraits = .button
        }

        switch indexPath.row {
        case 4:
            cell.accessibilityLabel = "Liens vers les préférences"
        case 5:
            cell.accessibilityLabel = "Liens vers les conditions générales d'utilisation"
        case 6:
            cell.accessibilityLabel = "Liens vers la politique de confidentialité et de vie privée - Ville de Paris"
        default:
            cell.accessibilityLabel = self.settingsArray[indexPath.row]
        }

        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.settingsArray.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return UITableView.automaticDimension
        } else {
            return 40
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return UITableView.automaticDimension
        } else {
            return 40
        }
    }
}

extension ProfileSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let profileStoryboard = UIStoryboard(name: Constants.StoryBoard.profile, bundle: nil)
        switch indexPath.row {
        case Constants.ProfilTableView.profil:
            if User.shared.isLogged {
                print("redirection vers page de profil")
                let profileDetailVC = profileStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.profileDetail) as! ProfileDetailViewController

                self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
                self.navigationController?.pushViewController(profileDetailVC, animated: true)
            } else {
                self.connectToMonParis()
            }
        case Constants.ProfilTableView.anomalies:
            if User.shared.isLogged {
                print("redirection vers page d'anomalie")
                let profileVC = profileStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.profile) as! ProfileViewController

                self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
                self.navigationController?.pushViewController(profileVC, animated: true)
            } else {
                self.connectToMonParis()
            }

        case Constants.ProfilTableView.actualites:
            let profileAtualiteVC = profileStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.profileActualites) as! ProfileActualitesViewController
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            self.navigationController?.pushViewController(profileAtualiteVC, animated: true)
        case Constants.ProfilTableView.aides:
            let profileAideVC = profileStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.profileAide) as! ProfileAidesViewController
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            self.navigationController?.pushViewController(profileAideVC, animated: true)
        case Constants.ProfilTableView.preferences:
            self.authorizationSettings()
        case Constants.ProfilTableView.cgu:
            if let url = URL(string: Constants.Services.urlCGU) {
                let vc = SFSafariViewController(url: url, entersReaderIfAvailable: false)
                vc.delegate = self
                present(vc, animated: true)
            }
        case Constants.ProfilTableView.confidentialite:
            if let url = URL(string: Constants.Services.urlConfidentialité) {
                let vc = SFSafariViewController(url: url, entersReaderIfAvailable: false)
                vc.delegate = self
                present(vc, animated: true)
            }
        case Constants.ProfilTableView.aPropos:
            let profileAboutVC = profileStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.profileAbout) as! ProfileAboutViewController
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            self.navigationController?.pushViewController(profileAboutVC, animated: true)
        default:
            print("nothing")
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}
