//
//  AppDelegate.swift
//  DansMaRue
//
//  Created by NTDC-Showroom on 16/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import Fabric
import Crashlytics
import UserNotifications
import Firebase
//import TTGSnackbar

//import AdtagLocationDetection
//import AdtagAnalytics
//import AdtagConnection

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    /*var adtagInitializer: AdtagInitializer?
    var adtagPlaceManager: AdtagPlaceDetectionManager?
    var myNotificationDelegate: MyNotificationDelegate?*/

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Use Firebase library to configure APIs
        FirebaseApp.configure()
        
        // Override point for customization after application launch.
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        Fabric.with([Crashlytics.self])
        
        /*adtagInitializer = AdtagInitializer.shared
        adtagInitializer?.configPlatform(Platform.prod).configUser(login: "dansmarue", password: "QVLPbx7F5oM8cFpib3mE", company: "arvilledeparis").synchronize()
        adtagPlaceManager = AdtagPlaceDetectionManager.shared*/

        // Activate API Key Google Maps for iOS SDK
        GMSServices.provideAPIKey(Constants.Services.apiKeyGMS)
        GMSPlacesClient.provideAPIKey(Constants.Services.apiKeyGMS)
        
        //adtagPlaceManager?.registerReceiveNotificatonContentDelegate(self)
  
        // iOS 10 support
        if #available(iOS 10, *) {
            UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]){ (granted, error) in
                if granted {
                    DispatchQueue.main.async {
                        application.registerForRemoteNotifications()
                    }
                } else {
                    print("Remote Push Notification n'est pas activé")
                    UserDefaults.standard.removeObject(forKey: Constants.Key.deviceToken)
                }
            }
            /*let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
                if (error == nil) {
                    print("request authorization succeeded!");
                }
                self.myNotificationDelegate = MyNotificationDelegate(self.adtagPlaceManager!)
                center.delegate = self.myNotificationDelegate
            }*/
            
        }
            // iOS 9 support
        else if #available(iOS 9, *) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
            //UIApplication.shared.registerForRemoteNotifications()
        }
        
        else if(UIApplication.instancesRespond(to: #selector(UIApplication.registerUserNotificationSettings(_:)))){
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings (types: [.alert, .sound], categories: nil))
        }
        
        if let option = launchOptions {
            if let info = option[UIApplication.LaunchOptionsKey.remoteNotification] as? NSDictionary {
                
                var typeContribution : TypeContribution = .outdoor
                if let type = info["type"] as? String {
                    // type OUTDOOR ou EQUIPEMENT
                    typeContribution = (type == "OUTDOOR") ? .outdoor : .indoor
                }
                if let anomalieId = info["anomalyId"] as? String {
                    getDetailsAnomalies(anomalieId: anomalieId, typeContribution: typeContribution)
                } else {
                    getDetailsAnomalies(anomalieId: "", typeContribution: typeContribution)
                }
                
            }
        }
        
        showOpeningMessage()
        
        return true
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        //adtagPlaceManager?.didReceivePlaceNotification(notification.userInfo)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        //adtagInitializer?.onAppInBackground()
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
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
        
        /*let VC = MainViewController()
        VC.isLatestVersion()*/
    }
    
    // Affiche un message provenant du BO
    private func showOpeningMessage() {
        RestApiManager.sharedInstance.getOpeningMessage { messageBO in
            if(messageBO != "") {
                //Récupération du titre et du message
                let messageBOArr = messageBO.components(separatedBy: ".")
                
                var titrePopup = "Information"
                var textPopup = ""
                
                if (messageBOArr.count>1) {
                    titrePopup = messageBOArr[0]
                    textPopup = messageBO.replacingOccurrences(of: messageBOArr[0] + ".", with: "")
                } else {
                    //Pas de titre
                    textPopup = messageBO
                }
                
                let alert = UIAlertController(title: titrePopup , message: textPopup, preferredStyle: UIAlertController.Style.alert)
                
                let fermerBtn = UIAlertAction(title: "Fermer", style: .default, handler: {(_ action: UIAlertAction) -> Void in})
                alert.addAction(fermerBtn)
                self.window?.rootViewController?.present(alert, animated: true, completion: nil)
            }
        }
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
        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
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
        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        //adtagInitializer?.onAppInForeground()
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    
    // Handle remote notification registration.
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data){
        // Convert token to string
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        print("APNs device token: \(deviceTokenString)")

        UserDefaults.standard.set(deviceTokenString, forKey: Constants.Key.deviceToken)
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // The token is not currently available.
        print("Remote notification support is unavailable due to error: \(error.localizedDescription)")
        
        UserDefaults.standard.removeObject(forKey: Constants.Key.deviceToken)
    }
    
    /*func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        // Print notification payload data
        print("Push notification received: \(userInfo)")

        if(application.applicationState == .inactive) {
            
            var typeContribution : TypeContribution = .outdoor
            if let type = userInfo["type"] as? String {
                // type OUTDOOR ou EQUIPEMENT
                typeContribution = (type == "OUTDOOR") ? .outdoor : .indoor
            }
            if let anomalieId = userInfo["anomalyId"] as? String {
                getDetailsAnomalies(anomalieId: anomalieId, typeContribution: typeContribution)
            } else {
                getDetailsAnomalies(anomalieId: "", typeContribution: typeContribution)
            }
        } else {
            
            if let aps = userInfo["aps"] as? NSDictionary {
                if let alert = aps["alert"] as? NSDictionary {
                    if let message = alert["body"] as? String {
                        TTGSnackbar.init(message: message, duration: .middle).show()
                    }
                } else if let alert = aps["alert"] as? String {
                    TTGSnackbar.init(message: alert, duration: .middle).show()
                }
            }
        }
        
    }

    func didReceivePlaceNotification(_ placeNotification: AdtagPlaceNotification) {
        NSLog("open a controller with a place notification")
    }
    
    func didReceiveWelcomeNotification(_ welcomeNotification: AdtagPlaceWelcomeNotification) {
        NSLog("open a controller with a place welcome notification")
    }*/
    
    var activityIndicator:UIActivityIndicatorView = UIActivityIndicatorView()
    
    //MARK: - Other function
    func getDetailsAnomalies(anomalieId: String, typeContribution: TypeContribution) {
        if let rootView = (self.window?.rootViewController)!.view {
            let container: UIView = UIView()
            container.frame = rootView.frame
            container.center = rootView.center
            container.backgroundColor = .black
            container.isOpaque = true
            container.alpha = 0.8
            
            activityIndicator.center = container.center
            activityIndicator.hidesWhenStopped = true
            activityIndicator.style = .whiteLarge
            activityIndicator.backgroundColor = UIColor.lightGreyDmr()
            container.addSubview(activityIndicator)
            rootView.addSubview(container)
            
            UIApplication.shared.beginIgnoringInteractionEvents()
            activityIndicator.startAnimating()
            
            let when = DispatchTime.now() + 2 // change 2 to desired number of seconds
            DispatchQueue.main.asyncAfter(deadline: when) {
                UIApplication.shared.endIgnoringInteractionEvents()
                self.activityIndicator.stopAnimating()
                container.removeFromSuperview()
                
                if typeContribution == .outdoor {
                    let anomalie = Anomalie(id: anomalieId, address: "", latitude: 0, longitude: 0, categorieId: "", descriptive: "", priorityId: "", anomalieStatus: .Brouillon, photoCloseUrl: nil, photoFarUrl: nil, photoDoneUrl: nil, number: "")
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NoticationKey.pushNotification), object: anomalie)
                } else {
                    
                    let anomalie = AnomalieEquipement(id: anomalieId, address: "", latitude: 0, longitude: 0, categorieId: "", descriptive: "", priorityId: "", anomalieStatus: .Brouillon, photoCloseUrl: nil, photoFarUrl: nil, photoDoneUrl: nil, number: "")
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NoticationKey.pushNotification), object: anomalie)
                }
            }
            
        }
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
