//
//  ThanksAnomalyViewController.swift
//  DansMaRue
//
//  Created by NTDC-Showroom on 13/04/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit
import SwiftyJSON
import TTGSnackbar

protocol CloseDelegate: NSObjectProtocol {
    func displayMap()
    func displayThanks()
}

public enum ThanksAnomalyStatus: String {
    case showMail = "M"
    case showThanks = "T"
    case saveIncident = "S"
}

class ThanksAnomalyViewController: UIViewController {

    //MARK: - Properties
    var currentAnomaly: Anomalie?
    weak var closeDelegate: CloseDelegate?
    
    var confirmAction: UIAlertAction?
    var status : ThanksAnomalyStatus = .showMail
    var typeContribution: TypeContribution = .outdoor
    
    var timer : Timer = Timer()
    var timerInterval = 90 // Interval de 90 secondes

    
    //MARK: - IBoutlets
 
    @IBOutlet weak var greyView: UIView!
    @IBOutlet weak var checkImage: UIImageView!
    @IBOutlet weak var thanksLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var myAccountButton: UIButton!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var mailButton: UIButton!
    @IBOutlet weak var infoBisLabel: UILabel!
    @IBOutlet weak var stayTunedLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var connectLabel: UILabel!
    @IBOutlet weak var closeButtonMail: UIButton!
    
    
    //MARK: - IBactions
    @IBAction func closeModal(_ sender: Any) {
        if self.status == .showMail {
            // Cas de la demande de mail. On sauvegarde l'anomalie et on ferme la view
            self.saveAndClose()
        } else {
            // Cas du message de remerciement. On ferme la view et on revient sur la map
            self.dismiss(animated: true)
            self.closeDelegate?.displayMap()
        }
    }

    //Connection de l'utilisateur via son compte Parisien
    @IBAction func connectToCp(_ sender: Any) {
        
        let completionHandler: (CompteParisienViewController) -> Void = {
            controller in
            
            if User.shared.isLogged {
                self.greyView.isHidden = true
                self.currentAnomaly?.mailUser = User.shared.email!
                
                self.saveAndClose()
            }
        }
        
        let compteParisienVC = UIStoryboard(name: Constants.StoryBoard.compteParisien, bundle: nil).instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.compteParisien) as! CompteParisienViewController
        compteParisienVC.completionHandler = completionHandler

        self.present(compteParisienVC, animated: true, completion: nil)
        self.navigationController?.navigationBar.isTranslucent = false
        
    }

    //Connection de l'utilisateur via son adresse mail
    @IBAction func enterMail(_ sender: Any) {
        let alertController = UIAlertController(title: Constants.AlertBoxTitle.restezInforme, message: "", preferredStyle: .alert)
        
        self.confirmAction = UIAlertAction(title: Constants.AlertBoxTitle.valider, style: .default) { (_) in
            let field = alertController.textFields![0]
            if (field.text?.isValidEmail())! {
                let email = field.text
                UserDefaults.standard.set(email, forKey: "userEmail")
                UserDefaults.standard.synchronize()
                self.currentAnomaly?.mailUser = email!
                self.saveAndClose()
            } else {
                field.layer.borderColor = UIColor.red.cgColor
                
            }
        }
        
        let cancelAction = UIAlertAction(title: Constants.AlertBoxTitle.annuler, style: .cancel) { (_) in }
        alertController.view.tintColor = UIColor.pinkDmr()
        alertController.addTextField { (textField) in
            textField.placeholder = Constants.PlaceHolder.email
            textField.text = UserDefaults.standard.string(forKey: "userEmail")
            textField.keyboardType = .emailAddress

            textField.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)

        }
        
        alertController.addAction(confirmAction!)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
       
    }
    
    
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if status == .showMail {
            //Ajustement de la police selon le device
            let modelResolution = UIDevice.current.deviceResolution
            if modelResolution[0] == "640" {
                infoBisLabel.font = UIFont(name: infoBisLabel.font.fontName, size: 13)
                infoLabel.font = UIFont(name: infoLabel.font.fontName, size: 13)
            }
            
            let originalImage = UIImage(named: Constants.Image.iconExit)
            let tintedImage = originalImage?.withRenderingMode(.alwaysTemplate)
            closeButtonMail.setImage(tintedImage, for: .normal)
            closeButtonMail.tintColor =  UIColor.greyDmr()
        } else if status == .showThanks {
            let originalImage = UIImage(named: Constants.Image.iconExit)
            let tintedImage = originalImage?.withRenderingMode(.alwaysTemplate)
            closeButton.setImage(tintedImage, for: .normal)
            closeButton.tintColor =  UIColor.greyDmr()
        } else if status == .saveIncident {
            self.saveAndClose()
        }
    }
    
    
    //MARK: - Other function
    @objc func textFieldDidChange (textToCheck: UITextField) {
        if !textToCheck.text!.isValidEmail() {
            self.confirmAction?.isEnabled = false
        } else {
            self.confirmAction?.isEnabled = true
        }
    }

    func saveAndClose() {
        
        // Start the timer
        self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(self.timerInterval), target: self, selector: #selector(ThanksAnomalyViewController.closeForTimeout), userInfo: nil, repeats: true)

        DispatchQueue.main.async {
            SaveAnomalyActivityIndicator.shared.showOverlay(self.view, self.greyView.frame)
        }
        
        if (Reach().connectionStatus()) {
            
            DispatchQueue.global().async {
                //Envoie de la requete si l'utilisateur se connecte avec son compte parisien ou entre son adresse mail.
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
        } else {
            let snackbar = TTGSnackbar.init(message:Constants.AlertBoxMessage.noConnexion, duration: .middle)
            
            snackbar.actionTextColor = UIColor.pinkDmr()
            snackbar.actionTextFont = UIFont(name: Constants.fontDmr, size: 14.0)!
            snackbar.messageTextFont = UIFont(name: Constants.fontDmr, size: 15.0)!
            snackbar.messageTextAlign = NSTextAlignment.center
            
            snackbar.show()
        }
        
    }
    
    @objc func closeForTimeout() {
        self.timer.invalidate()
        
        //message alerte
        let alertController = UIAlertController(title: Constants.AlertBoxTitle.information, message: Constants.AlertBoxMessage.errorSaveLabel, preferredStyle: .alert)
        // Create OK button
        let OKAction = UIAlertAction(title: Constants.AlertBoxTitle.ok, style: .default) {
            (action:UIAlertAction!) in
            
            SaveAnomalyActivityIndicator.shared.hideOverlayView()
            self.currentAnomaly?.anomalieStatus = .Brouillon
            self.currentAnomaly?.saveToDraft()
            self.dismiss(animated: true)
            self.closeDelegate?.displayMap()
        }
        alertController.addAction(OKAction)
        
        // Present Dialog message
        self.present(alertController, animated: true, completion:nil)
        
    }
}

class SaveAnomalyActivityIndicator: UIActivityIndicatorView {
    
    var overlayView = UIView()
    var backView = UIView()
    
    var activityIndicator = UIActivityIndicatorView()
    
    class var shared: SaveAnomalyActivityIndicator {
        struct Static {
            static let instance: SaveAnomalyActivityIndicator = SaveAnomalyActivityIndicator()
        }
        return Static.instance
    }
    
    open func showOverlay(_ view: UIView, _ frame: CGRect) {
        overlayView.frame = CGRect(x: 0, y: 0, width: frame.width, height: (frame.height + 25))
        backView.frame = CGRect(x: 0, y: 0, width: view.frame.width , height: view.frame.height)
        backView.center = view.center
        let white = UIColor ( red: 1/255, green: 0/255, blue:0/255, alpha: 0.0 )
        
        backView.backgroundColor = white
        view.addSubview(backView)
        
        overlayView.center = view.center
        overlayView.backgroundColor = UIColor.white
        overlayView.clipsToBounds = true
        //overlayView.layer.cornerRadius = 10

        // Create wait label
        let waitLabel = UILabel()
        waitLabel.text = Constants.LabelMessage.waitLabel
        waitLabel.frame = CGRect(x: 0, y: 10, width: frame.width, height: 50)
        waitLabel.numberOfLines = 2
        waitLabel.lineBreakMode = .byWordWrapping
        waitLabel.textColor = .black
        waitLabel.font = UIFont.init(name: Constants.fontDmr, size: 16)
        waitLabel.textAlignment = .center
        waitLabel.tag=100
        
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        //activityIndicator.center = overlayView.center
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

