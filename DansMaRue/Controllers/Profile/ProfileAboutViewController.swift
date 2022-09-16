//
//  ProfileAboutViewController.swift
//  DansMaRue
//
//  Created by Maxime Bureau on 28/04/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit

class ProfileAboutViewController: UIViewController {

    //MARK: - IBOutlets

    @IBOutlet weak var aboutDescriptionTextView: UITextView!
    @IBOutlet weak var subTitle: UILabel!
    
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = Constants.TabBarTitle.monEspace
        subTitle.text = Constants.LabelMessage.about

        aboutDescriptionTextView.text = "Version : \(Bundle.main.version) (\(Bundle.main.build))"
        aboutDescriptionTextView.font = UIFont(name: (aboutDescriptionTextView.font?.fontName)!, size: 15)
    }

}
