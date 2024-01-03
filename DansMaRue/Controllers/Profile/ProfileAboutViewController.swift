//
//  ProfileAboutViewController.swift
//  DansMaRue
//
//  Created by Maxime Bureau on 28/04/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit

class ProfileAboutViewController: UIViewController {
    // MARK: - IBOutlets

    @IBOutlet var aboutDescriptionTextView: UITextView!
    @IBOutlet var subTitle: UILabel!

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Constants.TabBarTitle.monEspace
        navigationItem.titleView?.isAccessibilityElement = true
        subTitle.text = Constants.LabelMessage.about
        subTitle.isAccessibilityElement = true
        subTitle.textColor = UIColor.greyDmr()
        subTitle.accessibilityLabel = Constants.LabelMessage.about
        subTitle.accessibilityTraits = .header
        subTitle.adjustsFontForContentSizeCategory = true
        subTitle.font = UIFont.preferredFont(forTextStyle: .title2)
        aboutDescriptionTextView.adjustsFontForContentSizeCategory = true
        aboutDescriptionTextView.text = "Version : \(Bundle.main.version) (\(Bundle.main.build))"
        aboutDescriptionTextView.font = UIFont.scaledFont(name: "Montserrat-Regular", textSize: 15.0)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: navigationItem.titleView)
    }
}
