//
//  String+DMR.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 28/04/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit

extension String {
    
    //On vérifie le format de l'email
    func isValidEmail() -> Bool {
        // print("validate calendar: \(testStr)")
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,5}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }

    func base64ToImage() -> UIImage? {
        if let url = URL(string: self),let data = try? Data(contentsOf: url),let image = UIImage(data: data) {
            return image
        }
        
        return nil
    }
    
    /// Methode permettant de gérer les retours à la ligne lors de l'envoi de donnée JSON
    func toHttpBody() -> String {
        return self.replacingOccurrences(of: "\n", with: "\\n")
    }
    
    /// Méthode permettant de tester si l'email est contenu dans la liste des emails valides pour service fait
    func isMailServiceFait() -> Bool {
        
        for domaine in Constants.Services.emailServiceFait {
            if (self.range(of: domaine) != nil) {
                return true
            }
        }
        
        return false
    }
    
    func versionToInt() -> [Int] {
        return self.components(separatedBy: ".")
            .map { Int.init($0) ?? 0 }
    }
}
