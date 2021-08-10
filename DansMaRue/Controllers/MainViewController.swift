//
//  MainViewController.swift
//  DansMaRue
//
//  Created by NTDC-Showroom on 16/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit
import SwiftyJSON
//import AdtagConnection

class MainViewController: UITabBarController {
    
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Vérification accessibilité BO
        RestApiManager.sharedInstance.isDMROnline { (isDMROnline) in
            if !isDMROnline {
                let alert = UIAlertController(title: Constants.AlertBoxTitle.information, message: Constants.AlertBoxMessage.maintenance, preferredStyle: UIAlertController.Style.alert)
                let okBtn = UIAlertAction(title:"Ok" , style: .default, handler: {(_ action: UIAlertAction) -> Void in
                })
                alert.addAction(okBtn)
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        configureTabBarItems()
        //Customisation de la bar de naviguation
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().barTintColor = UIColor.pinkDmr()
        UINavigationBar.appearance().titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue:UIColor.white])

        UITabBar.appearance().tintColor = UIColor.pinkButtonDmr()
        
        //Chargement des catégories/Types d'anomalies outdoor
        getCategories()
        //Chargement des types équipements et équipements
        getEquipements()
        
        //Ckeck si une MAJ est disponible
        isLatestVersion()

        // Authentification automatique de l'utilisateur
        User.shared.automaticAuthentification()
        
        let nc = NotificationCenter.default
        nc.addObserver(forName:Notification.Name(rawValue: Constants.NoticationKey.pushNotification), object:nil, queue:nil, using:displayProfil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let hasAlreadyBeenConnected = UserDefaults.standard.bool(forKey: "hasAlreadyBeenConnected")
        
        if !hasAlreadyBeenConnected {
            
            //Redirect to walkthrough view
            let welcomeStoryboard = UIStoryboard(name: Constants.StoryBoard.welcome, bundle: nil)
            let welcomeViewController = welcomeStoryboard.instantiateViewController(withIdentifier: "WelcomeViewController") as! WelcomeViewController
            welcomeViewController.modalPresentationStyle = .fullScreen
            
            self.navigationController?.addChild(welcomeViewController)
            self.present(welcomeViewController, animated: true, completion: nil)
            
        }
        //showOptinPopUp()
    }

    // MARK: - Other Methods
    func configureTabBarItems() {
        var newMenuArray: [UIViewController] = []
        
        let menuArray = self.customizableViewControllers
        
        let menuMap = menuArray![0]
        let menuProfile = menuArray![1]
        
        newMenuArray.append(menuMap)
        menuMap.tabBarItem.image = UIImage(named: "map_menu_selected")
        menuMap.tabBarItem.title = "Carte"
        
        newMenuArray.append(menuProfile)
        menuProfile.tabBarItem.image = UIImage(named: "profil_menu_selected")
        menuProfile.tabBarItem.title = "Mon espace"
        
        self.setViewControllers(newMenuArray, animated: true)
    }
    
    
    func displayProfil(notification:Notification) {
        // Réception d'une notification push pour afficher le profil de l'utilisateur
        if notification.object as? Anomalie == nil {
            self.selectedIndex = 1
        }
    }
    
    func isLatestVersion() {
        VersionsUtils().isLatestVersion(onCompletion: { isUpdateDispo, err in
            if(isUpdateDispo) {
                //Une MAJ est disponible
                print("update disponible")
                
                //On vérifie si la MAJ est obligatoire
                VersionsUtils().isMAJObligatoire(onCompletion: { isMAJObligatoire, err in
                    if isMAJObligatoire {
                        print("update obligatoire")
                        self.popupUpdateObligatoireDialogue()
                    } else {
                        print("update non obligatoire")
                        self.popupUpdateDialogue()
                    }
                })
            }
        })
    }
    
    private func popupUpdateDialogue(){
        let alertMessage = Constants.AlertBoxMessage.majDisponible
        let alert = UIAlertController(title: "Nouvelle version disponible", message: alertMessage, preferredStyle: UIAlertController.Style.alert)
        
        let okBtn = UIAlertAction(title: "Oui", style: .default, handler: {(_ action: UIAlertAction) -> Void in
            if let url = URL(string: "itms-apps://itunes.apple.com/us/app/apple-store/id662045577?mt=8"),
                UIApplication.shared.canOpenURL(url){
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        })
        let noBtn = UIAlertAction(title:"Non" , style: .default, handler: {(_ action: UIAlertAction) -> Void in
        })
        alert.addAction(okBtn)
        alert.addAction(noBtn)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func popupUpdateObligatoireDialogue(){
        let alertMessage = Constants.AlertBoxMessage.majObligatoire
        let alert = UIAlertController(title: "Nouvelle version disponible", message: alertMessage, preferredStyle: UIAlertController.Style.alert)
        
        let okBtn = UIAlertAction(title: "Mettre à jour", style: .default, handler: {(_ action: UIAlertAction) -> Void in
            if let url = URL(string: "itms-apps://itunes.apple.com/us/app/apple-store/id662045577?mt=8"),
                UIApplication.shared.canOpenURL(url){
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        })
        alert.addAction(okBtn)
        self.present(alert, animated: true, completion: nil)
    }
    
    func getCategories() {
        DispatchQueue.global().async {
            RestApiManager.sharedInstance.getCategories{(result: Bool) in
                
                if result {
                    ReferalManager.shared.loadTypeAnomalie()
                } else {
                    //Récupération des anciennes valeurs dans le fichier JSON
                    ReferalManager.shared.loadTypeAnomalie()
                    let alertController = UIAlertController(title: Constants.AlertBoxTitle.erreur, message: Constants.AlertBoxMessage.erreurChargementTypes, preferredStyle: .alert)
                    // Create try again button
                    let okButton = UIAlertAction(title: Constants.AlertBoxTitle.ok, style: .default) { (action:UIAlertAction!) in
                        //self.getCategories()
                    }
                    alertController.addAction(okButton)
                    //self.present(alertController, animated: true, completion:nil)
                    
                    
                }
                
                
            }
        }
    }
    
    func getEquipements() {
        DispatchQueue.global().async {
            RestApiManager.sharedInstance.getEquipements{(result: Bool) in
                
                if !result {
                    let alertController = UIAlertController(title: Constants.AlertBoxTitle.erreur, message: Constants.AlertBoxMessage.erreurChargementEquipement, preferredStyle: .alert)
                    // Create try again button
                    let okButton = UIAlertAction(title: Constants.AlertBoxTitle.ok, style: .default) { (action:UIAlertAction!) in
                        self.getEquipements()
                    }
                    alertController.addAction(okButton)
                    //self.present(alertController, animated: true, completion:nil)
                    
                } else {
                    ReferalManager.shared.loadTypeEquipementAndEquipements()
                    // Chargement des types d'anomalies par equipement
                    self.getCategoriesEquipements()
                }
            }
        }
    }
    
    func getCategoriesEquipements() {
        DispatchQueue.global().async {
            RestApiManager.sharedInstance.getCategoriesEquipements{(result: Bool) in
                
                if result {
                    ReferalManager.shared.loadTypeAnomalieByEquipement()
                } else {
                    let alertController = UIAlertController(title: Constants.AlertBoxTitle.erreur, message: Constants.AlertBoxMessage.erreurChargementTypes, preferredStyle: .alert)
                    // Create try again button
                    let okButton = UIAlertAction(title: Constants.AlertBoxTitle.ok, style: .default) { (action:UIAlertAction!) in
                        self.getCategoriesEquipements()
                    }
                    alertController.addAction(okButton)
                    //self.present(alertController, animated: true, completion:nil)
                    
                }
                
            }
        }
    }
    
    /*func showOptinPopUp() {
        let adtagInitializer = AdtagInitializer.shared
        //To know if an optin has been updated
        if adtagInitializer.optinsNeverAsked() {
            // No update, ask the optin ?
            let alertController = UIAlertController(title: Constants.AlertBoxTitle.parametres, message: Constants.AlertBoxMessage.optinAutorisation, preferredStyle: .alert)
            // Create Non button
            let NonAction = UIAlertAction(title: Constants.AlertBoxTitle.non, style: .default) { (action:UIAlertAction!) in
                self.manageOptin(permission: false)
            }
            alertController.addAction(NonAction)
            // Create Oui button
            let OuiAction = UIAlertAction(title: Constants.AlertBoxTitle.oui, style: .default) { (action:UIAlertAction!) in
                self.manageOptin(permission: true)
            }
            alertController.addAction(OuiAction)
            self.present(alertController, animated: true, completion:nil)
        }
    }
    
    func manageOptin(permission : Bool) {
        let adtagInitializer = AdtagInitializer.shared
        //get the optin status
        adtagInitializer.isOptinAuthorized(.USER_DATA)
        //Update the optin status even if it's false
        adtagInitializer.updateOptin(.USER_DATA, permission: permission)
        // Notify the SDK that you have finished with the opti-ns update - call it each time the opt-ins are udpated
        adtagInitializer.allOptinsAreUpdated()
    }*/
}



// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
