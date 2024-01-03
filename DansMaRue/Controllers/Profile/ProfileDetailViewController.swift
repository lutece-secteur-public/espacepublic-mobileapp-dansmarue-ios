//
//  ProfileDetailViewController.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 15/05/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import SafariServices
import UIKit

class ProfileDetailViewController: UIViewController {
    // MARK: - IBOutlet

    @IBOutlet var firstnameLabel: UILabel!
    @IBOutlet var lastnameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var displayProfil: UIButton!
    @IBOutlet var deleteAccount: UIButton!
    @IBOutlet var subTitle: UILabel!
    @IBOutlet var headerLabel: UILabel!

    @IBOutlet var mailTitle: UILabel!
    @IBOutlet var firstNameTitle: UILabel!
    @IBOutlet var lastNameTitle: UILabel!

    @IBOutlet var scrollView: UIScrollView!

    // MARK: - View lifecycle

    override func viewDidLoad() {
        title = Constants.TabBarTitle.monEspace
        navigationItem.titleView?.isAccessibilityElement = true
        setTitleColor()
        firstnameLabel.text = User.shared.firstName
        lastnameLabel.text = User.shared.lastName
        emailLabel.text = User.shared.email
        subTitle.text = Constants.LabelMessage.monProfil

        applyDynamicType(label: firstnameLabel, fontName: "Montserrat-Regular", size: 14.0)
        applyDynamicType(label: firstNameTitle, fontName: "Montserrat-Regular", size: 14.0)
        applyDynamicType(label: lastnameLabel, fontName: "Montserrat-Regular", size: 14.0)
        applyDynamicType(label: lastNameTitle, fontName: "Montserrat-Regular", size: 14.0)
        applyDynamicType(label: emailLabel, fontName: "Montserrat-Regular", size: 14.0)
        applyDynamicType(label: mailTitle, fontName: "Montserrat-Regular", size: 14.0)
        applyDynamicTypeSystemFont(label: displayProfil.titleLabel!, size: 15.0)
        applyDynamicTypeSystemFont(label: deleteAccount.titleLabel!, size: 15.0)
        applyDynamicTypeSystemFont(label: headerLabel, size: 17.0)
        displayProfil.setTitle(Constants.LabelMessage.voirProfile, for: .normal)
        displayProfil.backgroundColor = .clear
        displayProfil.tintColor = UIColor.pinkDmr()

        deleteAccount.setTitle(Constants.LabelMessage.suppressionCompteMonParis, for: .normal)
        deleteAccount.backgroundColor = .clear
        deleteAccount.tintColor = UIColor.greyDmr()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        displayProfil.sizeToFit()
        deleteAccount.sizeToFit()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 120, right: 0)
    }

    override func viewDidAppear(_ animated: Bool) {
        User.shared.automaticAuthentification()
        if !User.shared.isLogged {
            _ = navigationController?.popViewController(animated: true)
        }
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: navigationItem.titleView)
    }

    // MARK: - IBActions

    @IBAction func displayProfil(_ sender: UIButton) {
        if let url = URL(string: Constants.Services.urlDisplayProfile) {
            let vc = SFSafariViewController(url: url, entersReaderIfAvailable: false)
            present(vc, animated: true)
        }
    }

    @IBAction func deleteAccount(_ sender: UIButton) {
        if let url = URL(string: Constants.Services.urlDeleteAccount) {
            let vc = SFSafariViewController(url: url, entersReaderIfAvailable: false)
            present(vc, animated: true)
        }
    }

    private func setTitleColor() {
        firstNameTitle.textColor = UIColor.greyDmr()
        lastNameTitle.textColor = UIColor.greyDmr()
        mailTitle.textColor = UIColor.greyDmr()
        headerLabel.textColor = UIColor.greyDmr()
    }

    private func applyDynamicType(label: UILabel, fontName: String, size: Float) {
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.scaledFont(name: fontName, textSize: CGFloat(size))
    }

    private func applyDynamicTypeSystemFont(label: UILabel, size: Float) {
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .title3)
    }
}
