//
//  User.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 09/05/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import Foundation
import TTGSnackbar

class User {
    // MARK: - Properties

    var firstName: String?
    var lastName: String?
    var email: String?
    var password: String?
    var isAgent: Bool?
    var uid: String?
    
    var tokenId: String?
    var accessToken: String?
    
    var isLogged: Bool = false
    
    private init() {
        self.firstName = UserDefaults.standard.object(forKey: Constants.Key.firstName) as? String
        self.lastName = UserDefaults.standard.object(forKey: Constants.Key.lastName) as? String
        self.email = UserDefaults.standard.object(forKey: Constants.Key.email) as? String
        self.password = UserDefaults.standard.object(forKey: Constants.Key.password) as? String
        self.isAgent = UserDefaults.standard.object(forKey: Constants.Key.isAgent) as? Bool
    }
    
    static let shared = User()
    
    func automaticAuthentification() {
        if let uid = UserDefaults.standard.object(forKey: Constants.Key.uid) as? String {
            User.shared.uid = uid
            RestApiManager.sharedInstance.getIdentityStore(guid: uid) {
                (result: Bool) in
                if result {
                    print("Autentification réussi ...")
                    DispatchQueue.main.async {
                        TTGSnackbar(message: "Authentification réussie", duration: .middle).show()
                        UIAccessibility.post(notification: .announcement, argument: "Authentification réussie")
                    }
                } else {
                    print("Echec Autentification ...")
                    DispatchQueue.main.async {
                        TTGSnackbar(message: "Echec de l'authentification", duration: .middle).show()
                        UIAccessibility.post(notification: .announcement, argument: "Echec de l'authentification")
                        self.email = nil
                        self.password = nil
                    }
                }
            }
        }
    }
    
    func disconnect() {
        self.isLogged = false
        self.firstName = nil
        self.lastName = nil
        self.email = nil
        self.password = nil
        self.isAgent = nil
        self.uid = nil
        
        UserDefaults.standard.removeObject(forKey: Constants.Key.firstName)
        UserDefaults.standard.removeObject(forKey: Constants.Key.lastName)
        UserDefaults.standard.removeObject(forKey: Constants.Key.email)
        UserDefaults.standard.removeObject(forKey: Constants.Key.password)
        UserDefaults.standard.removeObject(forKey: Constants.Key.isAgent)
        UserDefaults.standard.removeObject(forKey: Constants.Key.uid)
    }
}
