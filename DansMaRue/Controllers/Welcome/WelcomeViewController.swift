//
//  WelcomeViewController.swift
//  DansMaRue
//
//  Created by NTDC-Showroom on 16/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {
    // MARK: - IBOutlets

    @IBOutlet var sliderView: UIView!
    @IBOutlet var startButton: UIButton!

    @IBOutlet var backgroundView: UIView!

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let welcomePageContentViewController = WelcomePageContentViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        let sliderContainerView = welcomePageContentViewController.view
        sliderContainerView?.frame = CGRect(x: 0, y: 0, width: self.sliderView.frame.size.width, height: self.sliderView.frame.size.height)
        self.sliderView.addSubview(sliderContainerView!)
        self.addChild(welcomePageContentViewController)
        self.startButton.layer.cornerRadius = 8
        self.startButton.isAccessibilityElement = true
        self.startButton.accessibilityLabel = "Commencer"
        self.startButton.accessibilityTraits = .button
        self.startButton.titleLabel?.adjustsFontForContentSizeCategory = true
        self.startButton.titleLabel?.font = UIFont.scaledFont(name: "Montserrat-Regular", textSize: 16.0)
        self.backgroundView.backgroundColor = UIColor(hexString: "#224659")
    }

    // MARK: - IBActions

    @IBAction func beginApp(_ sender: UIButton) {
        UserDefaults.standard.set(true, forKey: Constants.Key.hasAlreadyBeenConnected)
        self.dismiss(animated: true, completion: nil)
    }
}
