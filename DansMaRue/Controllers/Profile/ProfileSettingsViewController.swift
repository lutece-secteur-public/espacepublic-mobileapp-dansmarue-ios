//
//  ProfileSettingsViewController.swift
//  DansMaRue
//
//  Created by Maxime Bureau on 14/04/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit

class ProfileSettingsViewController: UIViewController {

    //MARK: - Properties

    var settingsArray = ["Mon profil", "Mes anomalies", "Actualités", "Aide et conseils d'utilisation", "Préférences","Conditions générales d'utilisation", "À Propos"]

    
    //MARK: - IBOutlets
    @IBOutlet weak var settingsTableView: UITableView!
    @IBOutlet weak var logoutBtn: UIButton!
    
    //MARK: - IBActions
    @IBAction func logoutCompteParisien(_ sender: Any) {
        if User.shared.isLogged {
            // Deconnexion de l'utilisateur
            User.shared.disconnect()
        }
        displayLoginLogoutBtn()
    }
    
    @IBAction func loginToCompteParisien(_ sender: Any) {
        let compteParisienVC = UIStoryboard(name: Constants.StoryBoard.compteParisien, bundle: nil).instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.compteParisien)
        compteParisienVC.modalPresentationStyle = .fullScreen
        self.navigationController?.present(compteParisienVC, animated: true)
        displayLoginLogoutBtn()
    }
    
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.barTintColor = UIColor.pinkDmr()
        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue:UIColor.white])


        if #available(iOS 13.0, *) {
           let appearance = UINavigationBarAppearance()
           appearance.configureWithOpaqueBackground()
           appearance.backgroundColor = UIColor.pinkButtonDmr()
           appearance.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue:UIColor.white])!
           self.navigationController?.navigationBar.standardAppearance = appearance;
           self.navigationController?.navigationBar.scrollEdgeAppearance = self.navigationController?.navigationBar.standardAppearance
       }
        
        settingsTableView.tableFooterView = UIView()
        displayLoginLogoutBtn()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        displayLoginLogoutBtn()
    }

    //MARK: - Private function
    
    func authorizationSettings() {
        let alertController = UIAlertController (title: Constants.AlertBoxTitle.modificationPreferences, message: Constants.AlertBoxMessage.modificationPreferences, preferredStyle: UIAlertController.Style.alert)
        
        let settingsAction = UIAlertAction(title: Constants.AlertBoxTitle.reglages, style: UIAlertAction.Style.default) { (_) -> Void in
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
            logoutBtn.backgroundColor = UIColor.clear
            logoutBtn.setTitleColor(UIColor.pinkDmr(), for: .normal)
            logoutBtn.setTitle(Constants.TitleButton.deconnecter.uppercased(), for: .normal)
            logoutBtn.isHidden = false
            settingsArray[0] =  "Mon profil"
            self.settingsTableView.reloadData()
        } else {
            logoutBtn.isHidden = true
            settingsArray[0] =  "Se connecter"
            self.settingsTableView.reloadData()
        }
    }
}



extension ProfileSettingsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let settingCell = tableView.dequeueReusableCell(withIdentifier: "settings_cell")
        let settingTitle = settingCell?.viewWithTag(101) as! UILabel
        settingTitle.text = settingsArray[indexPath.row]
        
        let loginBtn = settingCell?.viewWithTag(102) as! UIButton
        
        if(indexPath.row == 0 && !User.shared.isLogged ) {
            loginBtn.setTitle(Constants.TitleButton.monCompte.uppercased(), for: .normal)
            loginBtn.isHidden = false
            loginBtn.backgroundColor = UIColor.pinkButtonDmr()
            loginBtn.tintColor = UIColor.white
            loginBtn.layer.cornerRadius = 10
        } else {
            loginBtn.isHidden = true
        }
               
        return settingCell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsArray.count
    }
}

extension ProfileSettingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let profileStoryboard = UIStoryboard(name: Constants.StoryBoard.profile, bundle: nil)
        switch indexPath.row {
        case Constants.ProfilTableView.profil:
            if (User.shared.isLogged){
                print("redirection vers page de profil")
                let profileDetailVC = profileStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.profileDetail) as! ProfileDetailViewController
                
                self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
                self.navigationController?.pushViewController(profileDetailVC, animated: true)
            } else {
                let compteParisienVC = UIStoryboard(name: Constants.StoryBoard.compteParisien, bundle: nil).instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.compteParisien)
                compteParisienVC.modalPresentationStyle = .fullScreen
                self.navigationController?.present(compteParisienVC, animated: true)
                displayLoginLogoutBtn()
            }
        case Constants.ProfilTableView.anomalies:
            if (User.shared.isLogged){
                print("redirection vers page d'anomalie")
                let profileVC = profileStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.profile) as! ProfileViewController
                
                self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
                self.navigationController?.pushViewController(profileVC, animated: true)
            } else {
                let compteParisienVC = UIStoryboard(name: Constants.StoryBoard.compteParisien, bundle: nil).instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.compteParisien)
                self.navigationController?.present(compteParisienVC, animated: true)
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
            let profileCGUVC = profileStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.profileCgu) as! ProfileCGUViewController
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            self.navigationController?.pushViewController(profileCGUVC, animated: true)
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
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
