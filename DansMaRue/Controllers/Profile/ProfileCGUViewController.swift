//
//  ProfileCGUViewController.swift
//  DansMaRue
//
//  Created by Maxime Bureau on 28/04/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit

class ProfileCGUViewController: UIViewController {

    //MARK: - IBOutlets
    @IBOutlet weak var cguDescriptionTextView: UITextView!
    
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = Constants.LabelMessage.cgu
        
        cguDescriptionTextView.attributedText = NSAttributedString(string: Constants.LabelMessage.cguText)
   
        cguDescriptionTextView.font = UIFont(name: (cguDescriptionTextView.font?.fontName)!, size: 15)
    
    }

}
