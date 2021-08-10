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
    
    var tokenId: String?
    var uid: String?
    var accessToken: String?
    
    var isLogged:Bool = false
    
    private init() {
        firstName = UserDefaults.standard.object(forKey: Constants.Key.firstName) as? String
        lastName = UserDefaults.standard.object(forKey: Constants.Key.lastName) as? String
        email = UserDefaults.standard.object(forKey: Constants.Key.email) as? String
        password = UserDefaults.standard.object(forKey: Constants.Key.password) as? String
        isAgent = UserDefaults.standard.object(forKey: Constants.Key.isAgent) as? Bool
    }
    
    static let shared = User()
    
    func automaticAuthentification() {
        if let email = self.email, let password = self.password {
            RestApiManager.sharedInstance.authenticate(email: email, password: password) {
                (result: Bool) in
                
                if result {
                    print("Autentification réussi ...")
                    DispatchQueue.main.async {
                        TTGSnackbar.init(message: "Authentification réussie", duration: .middle).show()
                    }
                } else {
                    print("Echec Autentification ...")
                    DispatchQueue.main.async {
                        TTGSnackbar.init(message: "Echec de l'authentification", duration: .middle).show()
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
        
        UserDefaults.standard.removeObject(forKey: Constants.Key.firstName)
        UserDefaults.standard.removeObject(forKey: Constants.Key.lastName)
        UserDefaults.standard.removeObject(forKey: Constants.Key.email)
        UserDefaults.standard.removeObject(forKey: Constants.Key.password)
        UserDefaults.standard.removeObject(forKey: Constants.Key.isAgent)
    }
}
