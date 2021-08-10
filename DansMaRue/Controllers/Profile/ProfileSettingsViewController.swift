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

    let settingsArray = ["Profil", "Préférences", "Conditions générales d'utilisation", "À Propos"]

    
    //MARK: - IBOutlets
    @IBOutlet weak var settingsTableView: UITableView!
    @IBOutlet weak var loginLogoutBtn: UIButton!
    
    //MARK: - IBActions
    @IBAction func loginLogoutToCompteParisien(_ sender: Any) {
        
        if User.shared.isLogged {
            // Deconnexion de l'utilisateur
            User.shared.disconnect()
        } else {
            // Connexion de l'utilisateur
            let compteParisienVC = UIStoryboard(name: Constants.StoryBoard.compteParisien, bundle: nil).instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.compteParisien)
            compteParisienVC.modalPresentationStyle = .fullScreen
            self.navigationController?.present(compteParisienVC, animated: true)
        }
        
        displayLoginLogoutBtn()
    }
    
    
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            loginLogoutBtn.backgroundColor = UIColor.clear
            loginLogoutBtn.setTitleColor(UIColor.pinkDmr(), for: .normal)
            loginLogoutBtn.setTitle(Constants.TitleButton.deconnecter.uppercased(), for: .normal)
        } else {
            loginLogoutBtn.layer.cornerRadius = 25
            loginLogoutBtn.layer.borderWidth = 0.0
            loginLogoutBtn.backgroundColor = UIColor.pinkDmr()
            loginLogoutBtn.setTitleColor(UIColor.white, for: .normal)
            loginLogoutBtn.setTitle(Constants.TitleButton.connecter, for: .normal)
        }
    }
}



extension ProfileSettingsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let settingCell = tableView.dequeueReusableCell(withIdentifier: "settings_cell")
        let settingTitle = settingCell?.viewWithTag(101) as! UILabel
        settingTitle.text = settingsArray[indexPath.row]
        
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
        case 0:
            if (User.shared.isLogged){
                print("redirection vers page de profil")
                let profileDetailVC = profileStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.profileDetail) as! ProfileDetailViewController
                
                self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
                self.navigationController?.pushViewController(profileDetailVC, animated: true)
            } else {
                let compteParisienVC = UIStoryboard(name: Constants.StoryBoard.compteParisien, bundle: nil).instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.compteParisien)
                self.navigationController?.present(compteParisienVC, animated: true)
            }
           
        case 1:
           self.authorizationSettings()
            
//            let profilePreferencesVC = profileStoryboard.instantiateViewController(withIdentifier: "ProfilePreferencesViewController") as! ProfilePreferencesViewController
//            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
//            self.navigationController?.pushViewController(profilePreferencesVC, animated: true)
            
        case 2:
            let profileCGUVC = profileStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.profileCgu) as! ProfileCGUViewController
            
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            self.navigationController?.pushViewController(profileCGUVC, animated: true)
        case 3:
            let profileAboutVC = profileStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.profileAbout) as! ProfileAboutViewController
            
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            self.navigationController?.pushViewController(profileAboutVC, animated: true)
        default:
            print("nothing")
        }
    }
    
}
