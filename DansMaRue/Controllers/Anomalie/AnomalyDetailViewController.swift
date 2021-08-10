//
//  AnomalyDetailViewController.swift
//  DansMaRue
//
//  Created by Maxime Bureau on 20/04/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit
import SwiftyJSON
import TTGSnackbar
import SDWebImage


protocol CustomNavigationDelegate: NSObjectProtocol {
    func displayAddAnomaly(anomalySelected: Anomalie)
}

enum AnomalieDetailStatus {
    case notsolved
    case solved
    case undefined
}

class AnomalyDetailViewController: UIViewController {
    
    //MARK: - Properties
    var selectedAnomaly: Anomalie? = nil
    var currentAnomalyState = AnomalieDetailStatus.notsolved
    weak var customNavigationDelegate: CustomNavigationDelegate?
    var numberPhotoSelect = 1
    
    //MARK: - IBOutlets
    @IBOutlet weak var anomalyMainImageView: UIImageView!
    @IBOutlet weak var anomalyCloseButton: UIButton!
    @IBOutlet weak var anomalyEditButton: UIButton!
    @IBOutlet weak var anomalyStreetLabel: UILabel!
    @IBOutlet weak var anomalyStreetBisLabel: UILabel!
    @IBOutlet weak var timelineLabel: UILabel!
    @IBOutlet weak var mainTitleLabel: UILabel!
    @IBOutlet weak var anomalyDescriptionLabel: UILabel!
    @IBOutlet weak var concernedLabel: UILabel!
    @IBOutlet weak var greetingsLabel: UILabel!
    @IBOutlet weak var anomalySolvedLabel: UIButton!
    @IBOutlet weak var anomalyInProgressLabel: UILabel!
    @IBOutlet var detailView: UIView!
    @IBOutlet var previousButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var solvedButton: UIButton_Solved!
    @IBOutlet var followButton: UIButton!
    @IBOutlet var congratsButton: UIButton_Congrats!
   
    let imgGreetingsButton = UIImage(named:Constants.Image.thumbsUp)
    let imgFollow = UIImage(named:Constants.Image.follow)
    let imgUnfollow = UIImage(named:Constants.Image.unfollow)
    let imgFollowDisabled = UIImage(named:Constants.Image.followDisabled)
    let imgChevronPrevious = UIImage(named:Constants.Image.iconBackChevron)
    let imgChevronNext = UIImage(named:Constants.Image.iconChevron)

    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.numberPhotoSelect = 1
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        
        swipeRight.direction = UISwipeGestureRecognizer.Direction.right
        swipeLeft.direction = UISwipeGestureRecognizer.Direction.left
        
        self.view.addGestureRecognizer(swipeRight)
        self.view.addGestureRecognizer(swipeLeft)
        
        
        let tintedImageBack = imgChevronPrevious?.withRenderingMode(.alwaysTemplate)
        self.previousButton.setImage(tintedImageBack, for: .normal)
        self.previousButton.tintColor =  .white
        
        let tintedImageNext = imgChevronNext?.withRenderingMode(.alwaysTemplate)
        self.nextButton.setImage(tintedImageNext, for: .normal)
        self.nextButton.tintColor = .white
        
        self.followButton.setImage(self.imgFollowDisabled, for: .disabled)
        self.showOrHideSubviews()
        self.replaceAnomalyValues()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        //Permet de de dessiner la ligne grise au dessus des félicitations/personnes concernées
        let doYourPath = UIBezierPath(rect: CGRect(x: 0, y: concernedLabel.frame.origin.y - 10, width: detailView.frame.size.width - 20, height: 1))
        let layer = CAShapeLayer()
        layer.path = doYourPath.cgPath
        layer.fillColor = UIColor.lightGreyDmr().cgColor
        self.detailView.layer.addSublayer(layer)
        
    }
    
    //MARK: - UI management
    func showOrHideSubviews() {
        switch currentAnomalyState {
        case .notsolved:
            self.anomalyCloseButton.isHidden = false
            self.anomalyEditButton.isHidden = true
            
            self.anomalySolvedLabel.isHidden = true
            self.greetingsLabel.isHidden = true
            self.congratsButton.isHidden = true
            self.concernedLabel.isHidden = selectedAnomaly?.source == .ramen
            
            
            self.anomalyInProgressLabel.isHidden = false
            self.anomalyInProgressLabel.text = Constants.LabelMessage.anomalieInProgress
            self.anomalyInProgressLabel.layer.masksToBounds = true
            self.anomalyInProgressLabel.layer.cornerRadius = 20

            self.anomalyInProgressLabel.backgroundColor = UIColor.orangeDmr()
            
            if (selectedAnomaly?.resolvedAuthorization)! {
                self.solvedButton.isHidden = false
            } else {
                self.solvedButton.isEnabled = false
                self.solvedButton.backgroundColor = UIColor.greyDmr()
            }
            
        
            //Suivi d'une anomalie
            if let anomalie = self.selectedAnomaly, !anomalie.isIncidentFollowedByUser {
                self.followButton.isHidden = false
                self.followButton.isEnabled = anomalie.source == .dmr
                self.followButton.setImage(self.imgFollow, for: .normal)
                self.followButton.accessibilityLabel = Constants.LabelMessage.followAnomaly
            } else  {
                self.followButton.isHidden = false
                self.followButton.isEnabled = true
                self.followButton.setImage(self.imgUnfollow, for: .normal)
                self.followButton.accessibilityLabel = Constants.LabelMessage.unfollowAnomaly
            }
            
        case .solved:
            self.anomalyCloseButton.isHidden = false
            self.anomalyEditButton.isHidden = true
            self.followButton.isHidden = true
            self.solvedButton.isHidden = true
            self.anomalyInProgressLabel.isHidden = true
            self.anomalySolvedLabel.isHidden = false
            self.anomalySolvedLabel.setTitle(Constants.LabelMessage.anomalieSolved, for: .normal)
            self.anomalySolvedLabel.layer.cornerRadius = 15
            self.anomalySolvedLabel.backgroundColor = UIColor.greenDmr()
            
            self.greetingsLabel.isHidden = false
            self.congratsButton.isHidden = false
            self.congratsButton.isEnabled = selectedAnomaly?.source == .dmr
        
        default:
            self.anomalyCloseButton.isHidden = false
            self.anomalyEditButton.isHidden = false
            self.followButton.isHidden = false
            self.greetingsLabel.isHidden = false
            self.congratsButton.isHidden = false
            self.anomalySolvedLabel.isHidden = false
            self.anomalyInProgressLabel.isHidden = true
            
            
        }
    }
    
    func replaceAnomalyValues() {
        
        if let anomalie = selectedAnomaly {
            let postalCode = MapsUtils.getPostalCode(address: anomalie.address)
            
            self.mainTitleLabel.text = anomalie.alias
            self.anomalyDescriptionLabel.text = anomalie.descriptive
            self.anomalyStreetLabel.text = MapsUtils.getStreetAddress(address: anomalie.address)
            self.anomalyStreetBisLabel.text = MapsUtils.boroughLabel(postalCode: postalCode)
            self.timelineLabel.text = DateUtils.formatDateByLocal(dateString: anomalie.date) + " " + anomalie.hour + "\n" + anomalie.number
            self.timelineLabel.lineBreakMode = .byClipping
            self.timelineLabel.numberOfLines=0
            self.concernedLabel.text = "\(anomalie.followers) intéressé(e)s"
            self.greetingsLabel.text = "\(anomalie.congratulations) félicitation(s)"
            
            self.previousButton.isHidden = anomalie.nbPhoto <= 1
            self.nextButton.isHidden = anomalie.nbPhoto <= 1
            
            if anomalie.firstImageUrl.isEmpty {
                if(anomalie.photoDoneUrl.isEmpty) {
                    anomalyMainImageView.image = anomalie.imageCategorie
                    anomalyMainImageView.contentMode = UIView.ContentMode.scaleAspectFit
                } else {
                    let imageURL = URL(string: anomalie.photoDoneUrl) ?? URL(string: Constants.Image.noImage)
                    anomalyMainImageView.sd_setImage(with: imageURL!, placeholderImage: anomalie.imageCategorie, options: .allowInvalidSSLCertificates)
                }
            } else {
                let imageURL = URL(string: anomalie.firstImageUrl) ?? URL(string: Constants.Image.noImage)
                anomalyMainImageView.sd_setImage(with: imageURL!, placeholderImage: anomalie.imageCategorie, options: .allowInvalidSSLCertificates)
            }
            
        }
        
    }
    
    //Navigation entre photos
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            
            
            switch swipeGesture.direction {
            case UISwipeGestureRecognizer.Direction.right:
                print("Swiped right")                
                if (self.numberPhotoSelect>1) {
                    numberPhotoSelect-=1
                }
                anomalyMainImageView.sd_setImage(with: setPhotoURL(), placeholderImage: self.selectedAnomaly?.imageCategorie, options: .allowInvalidSSLCertificates)
            case UISwipeGestureRecognizer.Direction.left:
                print("Swiped left")
                if (self.numberPhotoSelect<(self.selectedAnomaly?.nbPhoto)!) {
                    self.numberPhotoSelect+=1
                }
                anomalyMainImageView.sd_setImage(with: setPhotoURL(), placeholderImage: self.selectedAnomaly?.imageCategorie, options: .allowInvalidSSLCertificates)
            default:
                break
            }
        }
    }
    
    
    //MARK: - IBActions
    @IBAction func closeWindow(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func editAnomaly(_ sender: Any) {
        self.dismiss(animated: true) {
            self.customNavigationDelegate?.displayAddAnomaly(anomalySelected: self.selectedAnomaly!)
        }
    }
    
    @IBAction func seePreviousPhoto(_ sender: Any) {
        
        if (self.numberPhotoSelect>1) {
            numberPhotoSelect-=1
        }
        
        anomalyMainImageView.sd_setImage(with: setPhotoURL(), placeholderImage: self.selectedAnomaly?.imageCategorie, options: .allowInvalidSSLCertificates)
    }
    
    
    @IBAction func seeNextPhoto(_ sender: Any) {
        
        if (self.numberPhotoSelect<(self.selectedAnomaly?.nbPhoto)!) {
            self.numberPhotoSelect+=1
        }
        anomalyMainImageView.sd_setImage(with: setPhotoURL(), placeholderImage: self.selectedAnomaly?.imageCategorie, options: .allowInvalidSSLCertificates)
    }
    
    private func setPhotoURL () -> URL {
        var imageURL = URL(string: Constants.Image.noImage)
        
        switch self.numberPhotoSelect {
        case 1:
            if(self.selectedAnomaly?.firstImageUrl.isEmpty)! {
                imageURL = URL(string: (self.selectedAnomaly?.photoDoneUrl)!) ?? URL(string: Constants.Image.noImage)
            } else {
                //on a juste la photo done
                imageURL = URL(string: (self.selectedAnomaly?.firstImageUrl)!) ?? URL(string: Constants.Image.noImage)
            }
        case 2:
            //1 image de l'ano (close ou far) + 1 photo done
            if(URL(string: (self.selectedAnomaly?.firstImageUrl)!) == URL(string: (self.selectedAnomaly?.secondImageUrl)!)) {
                imageURL = URL(string: (self.selectedAnomaly?.photoDoneUrl)!) ?? URL(string: Constants.Image.noImage)
            } else {
                //Pas de photo done
                imageURL = URL(string: (self.selectedAnomaly?.secondImageUrl)!) ?? URL(string: Constants.Image.noImage)
            }
        case 3:
            imageURL = URL(string: (self.selectedAnomaly?.photoDoneUrl)!) ?? URL(string: Constants.Image.noImage)
        default:
            break
        }
        
        return imageURL!
    }
    
    //Abonnement ou désabonnement du suivi de l'anomalie
    @IBAction func doAwesomeFeature(_ sender: Any) {
        if (!User.shared.isLogged){
            followButton.setImage(imgFollow, for: .normal)
            //Redirection vers le Compte Parisien
            let compteParisienVC = UIStoryboard(name: Constants.StoryBoard.compteParisien, bundle: nil).instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.compteParisien)
            self.present(compteParisienVC, animated: true)
        } else {
            var hasFollow = false
            if let anomalie = selectedAnomaly {
                hasFollow = selectedAnomaly?.isIncidentFollowedByUser ?? false
                
                if (!hasFollow) {
                    
                    self.followButton.isEnabled = false
                    
                    DispatchQueue.global().async {
                        RestApiManager.sharedInstance.follow(anomalie: anomalie, onCompletion: { (result: Bool) in
                            DispatchQueue.main.async {
                                if result {
                                    //Mise à jour de l'UI
                                    
                                    self.selectedAnomaly?.isIncidentFollowedByUser = true
                                    self.selectedAnomaly?.followers += 1
                                    let numberOfFollowers = self.selectedAnomaly?.followers
                                    self.concernedLabel.text = "\(String(numberOfFollowers!)) concerné(e)s"
                                    self.followButton.setImage(self.imgUnfollow, for: .normal)
                                    
                                    let snackbar = TTGSnackbar.init(message: Constants.AlertBoxMessage.followMalfunction, duration: .middle)
                                    
                                    snackbar.actionTextColor = UIColor.pinkDmr()
                                    snackbar.actionTextFont = UIFont(name: Constants.fontDmr, size: 14.0)!
                                    snackbar.messageTextFont = UIFont(name: Constants.fontDmr, size: 15.0)!
                                    snackbar.messageTextAlign = NSTextAlignment.center
                                    
                                    snackbar.show()
                                }
                                
                                self.followButton.isEnabled = true

                            }
                        })
                    }
                } else {
                    self.followButton.isEnabled = false
                    
                    DispatchQueue.global().async {
                        RestApiManager.sharedInstance.unfollow(anomalie: anomalie, onCompletion: { (result: Bool) in
                            DispatchQueue.main.async {
                                if result {
                                    //Mise à jour de l'UI
                                    
                                    self.selectedAnomaly?.isIncidentFollowedByUser = false
                                    self.selectedAnomaly?.followers -= 1
                                    let numberOfFollowers = self.selectedAnomaly?.followers
                                    self.concernedLabel.text = "\(String(numberOfFollowers!)) concerné(e)s"
                                    self.followButton.setImage(self.imgFollow, for: .normal)
                                    let snackbar = TTGSnackbar.init(message: Constants.AlertBoxMessage.unfollowMalfunction, duration: .middle)
                                    
                                    
                                    snackbar.actionTextColor = UIColor.pinkDmr()
                                    snackbar.actionTextFont = UIFont(name: Constants.fontDmr, size: 14.0)!
                                    snackbar.messageTextFont = UIFont(name: Constants.fontDmr, size: 15.0)!
                                    snackbar.messageTextAlign = NSTextAlignment.center
                                    
                                    snackbar.show()
                                }
                                
                                self.followButton.isEnabled = true
                                
                            }
                        })
                    }
                }
            }
        }

    }
    
    @IBAction func congratsTheAnomaly(_ sender: Any) {
        
        if(!User.shared.isLogged){
            let compteParisienVC = UIStoryboard(name: Constants.StoryBoard.compteParisien, bundle: nil).instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.compteParisien)
            self.navigationController?.present(compteParisienVC, animated: true)
        } else {
            
            var cancelAction = false
            self.congratsButton.isEnabled = false
            self.congratsButton.backgroundColor = UIColor.greyDmr()
            
            let snackbar = TTGSnackbar.init(message: Constants.AlertBoxMessage.congratulate, duration: .middle, actionText: Constants.AlertBoxTitle.annuler)
            { (snackbar) -> Void in
                cancelAction = true
                self.congratsButton.isEnabled = true
                let numberOfCongrats = self.selectedAnomaly?.congratulations
                self.greetingsLabel.text = "\(String(numberOfCongrats!)) félicitation(s)"
                self.congratsButton.backgroundColor = UIColor.greenDmr()

            }
            snackbar.actionTextColor = UIColor.pinkDmr()
            snackbar.actionTextFont = UIFont(name: Constants.fontDmr, size: 14.0)!
            snackbar.messageTextFont = UIFont(name: Constants.fontDmr, size: 15.0)!
            snackbar.messageTextAlign = NSTextAlignment.center
            
            //Callback si l'utilisateur ne fais pas "annuler"
            snackbar.dismissBlock = {
                
                (snackbar: TTGSnackbar) -> Void in
                if !cancelAction {
                    DispatchQueue.global().async {
                        
                        RestApiManager.sharedInstance.congratulateAnomalie(anomalie: (self.selectedAnomaly)!, onCompletion: { (result: Bool) in
                            
                            if result {
                                //Mise à jour de l'UI
                                DispatchQueue.main.async {
                                    self.selectedAnomaly?.congratulations += 1
                                    let numberOfCongrats = self.selectedAnomaly?.congratulations
                                    self.greetingsLabel.text = "\(String(numberOfCongrats!)) félicitation(s)"
                                    self.congratsButton.isHidden = true
   
                                }
                            }
                        })
                    }
                }
                
                
            }
            snackbar.show()
            
        }
        
    }
    
    @IBAction func solvedAction(_ sender: Any) {
        
        self.solvedButton.isEnabled = false
        self.solvedButton.backgroundColor = UIColor.greyDmr()
        var cancelAction = false
        
        let snackbar = TTGSnackbar.init(message: Constants.AlertBoxMessage.solvedMalfunction, duration: .middle, actionText: Constants.AlertBoxTitle.annuler)
        { (snackbar) -> Void in
            cancelAction = true
            self.solvedButton.isEnabled = true
            self.solvedButton.backgroundColor = UIColor.pinkDmr()
            
        }
        snackbar.actionTextColor = UIColor.pinkDmr()
        snackbar.actionTextFont = UIFont(name: Constants.fontDmr, size: 14.0)!
        snackbar.messageTextFont = UIFont(name: Constants.fontDmr, size: 15.0)!
        snackbar.messageTextAlign = NSTextAlignment.center
        
        //Callback si l'utilisateur ne fais pas "annuler"
        snackbar.dismissBlock = {
            
            (snackbar: TTGSnackbar) -> Void in
            if !cancelAction {
                DispatchQueue.global().async {
                    
                    RestApiManager.sharedInstance.incidentResolved(anomalie: (self.selectedAnomaly)!, onCompletion: { (result: Bool) in
                        DispatchQueue.main.async {
                            if result {
                                
                                let snackbar = TTGSnackbar.init(message: Constants.AlertBoxMessage.anomalieResolue, duration: .middle)
                                
                                snackbar.messageTextFont = UIFont(name: Constants.fontDmr, size: 15.0)!
                                snackbar.messageTextAlign = NSTextAlignment.center
                                snackbar.show()
                                
                                self.anomalySolvedLabel.isHidden = false
                                self.anomalySolvedLabel.setTitle(Constants.LabelMessage.anomalieSolved, for: .normal)
                                self.anomalySolvedLabel.layer.cornerRadius = 15
                                self.anomalySolvedLabel.backgroundColor = UIColor.greenDmr()
                                self.anomalyInProgressLabel.isHidden = true
                                self.congratsButton.isHidden = false
                                self.greetingsLabel.isHidden = false
                                self.solvedButton.isHidden = true
                                self.followButton.isHidden = true
                                
                            }
                            else {
                                self.solvedButton.backgroundColor = UIColor.pinkDmr()
                                self.solvedButton.isEnabled = true
                            }
                        }
                    })
                }
            }
            
            
        }
        snackbar.show()
        
        
        
        
        
        
     
    }
}


