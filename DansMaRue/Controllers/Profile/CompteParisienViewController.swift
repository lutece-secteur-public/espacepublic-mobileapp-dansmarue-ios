//
//  CompteParisienViewController.swift
//  DansMaRue
//
//  Created by NTDC-Showroom on 18/04/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit
import TTGSnackbar

class CompteParisienViewController: UIViewController {

    //MARK: - Properties
    var completionHandler : ((_ controller:CompteParisienViewController) -> Void)?
    
    //MARK: - IBoutlets
    @IBOutlet var mailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var forgetPasswordButton: UIButton!
    @IBOutlet var registerButton: UIButton!
    @IBOutlet var connectionButton: UIButton_PublierAnomalie!
    @IBOutlet var monCompteLabel: UILabel!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var backgroundImage: UIImageView!
    @IBOutlet var blueFilterView: UIView!
    
    //MARK: - IBactions
    @IBAction func connectToCompteParisien(_ sender: Any) {
        let mail = mailTextField.text
        let password = passwordTextField.text
        UserDefaults.standard.set(mail, forKey: "mail")

        
        RestApiManager.sharedInstance.authenticate(email: mail!, password: password!) {
            (result: Bool) in
            
            DispatchQueue.main.async {
                if result {
                    TTGSnackbar.init(message: Constants.AlertBoxMessage.authenticationOk, duration: .middle).show()
                    self.backToCompteParisien(self)
                } else {
                    let alertController = UIAlertController (title: Constants.AlertBoxTitle.erreur, message: Constants.AlertBoxMessage.erreur, preferredStyle: UIAlertControllerStyle.alert)
                    
                    let okAction = UIAlertAction(title: Constants.AlertBoxTitle.ok, style: UIAlertActionStyle.default) { (_) -> Void in
                        // nothing
                    }
                    
                    alertController.addAction(okAction)
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func backToCompteParisien(_ sender: Any) {
        self.dismiss(animated: true) {
            if let handler = self.completionHandler {
                handler(self)
            }
        }
    }
    
    @IBAction func didTapForgetPwd(_ sender: Any) {
        UIApplication.shared.openURL(NSURL(string: Constants.Services.urlForgetPassword)! as URL)
    }
    
    @IBAction func didTapRegister(_ sender: Any) {
        UIApplication.shared.openURL(NSURL(string: Constants.Services.urlRegiserCompteParisien)! as URL)
    }

    
    //MARK: - View lifecyle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mailTextField.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)
        
        mailTextField.delegate = self
        passwordTextField.delegate = self
    
        // Initialisation du bouton 
        textFieldDidChange()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        //Création de la ligne en dessous des champs textes
        let bottomBorder = CALayer()
        let bottomBorder2 = CALayer()
        bottomBorder.frame = CGRect(x: 0, y: mailTextField.frame.height - 1.0, width: mailTextField.frame.size.width , height: 6)
        bottomBorder2.frame = CGRect(x: 0, y: passwordTextField.frame.height - 1.0, width: passwordTextField.frame.width , height: 2)
        bottomBorder.backgroundColor = UIColor.white.cgColor
        bottomBorder2.backgroundColor = UIColor.white.cgColor
        
        self.mailTextField.layer.addSublayer(bottomBorder)
        self.passwordTextField.layer.addSublayer(bottomBorder2)
        self.mailTextField.text =  UserDefaults.standard.string(forKey: "mail")
        
        designUITextField()
        
    }
    
    func designUITextField(){
        mailTextField.attributedPlaceholder = NSAttributedString(string: Constants.PlaceHolder.mail, attributes: [NSForegroundColorAttributeName: UIColor.white])
        mailTextField.textColor = UIColor.white
        mailTextField.borderStyle = UITextBorderStyle.none
        mailTextField.tintColor = UIColor.white

        
        passwordTextField.attributedPlaceholder = NSAttributedString(string: Constants.PlaceHolder.password, attributes: [NSForegroundColorAttributeName: UIColor.white])
        passwordTextField.textColor = UIColor.white
        passwordTextField.borderStyle = UITextBorderStyle.none
        passwordTextField.tintColor = UIColor.white
    }

    
}

extension CompteParisienViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func textFieldDidChange () {
        if ((mailTextField.text!.isValidEmail() == false) || (mailTextField.text?.isEmpty)! || (passwordTextField.text?.isEmpty)!) {
            connectionButton.isEnabled = false
            connectionButton.backgroundColor = UIColor.lightGreyDmr()
        } else {
            connectionButton.isEnabled = true
            connectionButton.backgroundColor = UIColor.pinkDmr()
            
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        var myMutableStringTitle = NSMutableAttributedString()
        let placeHolder  = textField.attributedPlaceholder?.string
        myMutableStringTitle = NSMutableAttributedString(string:placeHolder!, attributes: [NSFontAttributeName:UIFont(name: Constants.fontDmr, size: 12.0)!])
        myMutableStringTitle.addAttribute(NSForegroundColorAttributeName, value: UIColor.white, range:NSRange(location:0,length:(placeHolder?.count)!))
        textField.attributedPlaceholder = myMutableStringTitle
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {

       designUITextField()
        
    }
    
    
    
}
