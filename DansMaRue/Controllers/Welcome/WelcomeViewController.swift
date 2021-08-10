//
//  WelcomeViewController.swift
//  DansMaRue
//
//  Created by NTDC-Showroom on 16/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {
    
    //MARK: - IBOutlets
    @IBOutlet var sliderView: UIView!
    @IBOutlet var startButton: UIButton!
    
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let welcomePageContentViewController = WelcomePageContentViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        let sliderContainerView = welcomePageContentViewController.view
        sliderContainerView?.frame = CGRect(x: 0, y: 0, width: self.sliderView.frame.size.width, height: self.sliderView.frame.size.height)
        self.sliderView.addSubview(sliderContainerView!)
        self.addChild(welcomePageContentViewController)
        startButton.layer.cornerRadius = 8
        
    }
    
    //MARK: - IBActions
    @IBAction func beginApp(_ sender: UIButton) {
        UserDefaults.standard.set(true, forKey: Constants.Key.hasAlreadyBeenConnected)
        self.dismiss(animated: true, completion: nil)
    }
    
}
