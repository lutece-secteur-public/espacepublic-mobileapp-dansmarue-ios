//
//  ProfileDetailViewController.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 15/05/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit
import SafariServices

class ProfileDetailViewController: UIViewController {
    
    // Mark: - IBOutlet
    @IBOutlet weak var firstnameLabel: UILabel!
    @IBOutlet weak var lastnameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var displayProfil: UIButton!
    @IBOutlet weak var deleteAccount: UIButton!
    @IBOutlet weak var subTitle: UILabel!
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        self.title = Constants.TabBarTitle.monEspace
        
        firstnameLabel.text = User.shared.firstName
        lastnameLabel.text = User.shared.lastName
        emailLabel.text = User.shared.email
        subTitle.text = Constants.LabelMessage.monProfil
        
        displayProfil.setTitle(Constants.LabelMessage.voirProfile, for: .normal)
        displayProfil.backgroundColor = .clear
        displayProfil.tintColor = UIColor.pinkDmr()
        
        deleteAccount.setTitle(Constants.LabelMessage.suppressionCompteMonParis, for: .normal)
        deleteAccount.backgroundColor = .clear
        deleteAccount.tintColor = UIColor.midLightGreyDmr()
    }
    
    // MARK: - IBActions
    @IBAction func displayProfil(_ sender: UIButton) {
        if let url = URL(string: Constants.Services.urlDisplayProfile) {
            let vc = SFSafariViewController(url: url, entersReaderIfAvailable: true)
            present(vc, animated: true)
        }
    }
    
    @IBAction func deleteAccount(_ sender: UIButton) {
        if let url = URL(string: Constants.Services.urlDeleteAccount) {
            let vc = SFSafariViewController(url: url, entersReaderIfAvailable: true)
            present(vc, animated: true)
        }

    }
}
