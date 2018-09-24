//
//  ProfileDetailViewController.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 15/05/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit

class ProfileDetailViewController: UIViewController {
    
    // Mark: - IBOutlet
    @IBOutlet weak var firstnameLabel: UILabel!
    @IBOutlet weak var lastnameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var displayProfil: UIButton!
    
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        firstnameLabel.text = User.shared.firstName
        lastnameLabel.text = User.shared.lastName
        emailLabel.text = User.shared.email
        
        displayProfil.setTitle(Constants.LabelMessage.voirProfile, for: .normal)
        displayProfil.backgroundColor = .clear
        displayProfil.tintColor = UIColor.pinkDmr()
    }
    
    // MARK: - IBActions
    @IBAction func displayProfil(_ sender: UIButton) {
        UIApplication.shared.openURL(NSURL(string: Constants.Services.urlDisplayProfile)! as URL)
    }
}
