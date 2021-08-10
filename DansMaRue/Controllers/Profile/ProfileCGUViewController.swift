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
        
        let cguText = Constants.LabelMessage.cguText1 + "<br><br>" + Constants.LabelMessage.cguText2 + "<br>" + Constants.LabelMessage.cguText3 + "<br><br>" + Constants.LabelMessage.cguText4 + "<br><br>" + Constants.LabelMessage.cguText5 + "<br><br>" + Constants.LabelMessage.cguText6 + "<br><br>" + Constants.LabelMessage.cguText7 + "<br><br>" + Constants.LabelMessage.cguText8 + "<br><br>" + Constants.LabelMessage.cguText9 + "<br><br>" + Constants.LabelMessage.cguText10 + "<br><br>" + Constants.LabelMessage.cguText11
        
        let htmlData = NSString(string: cguText).data(using: String.Encoding.utf8.rawValue)
        let options = [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue] as [NSAttributedString.DocumentReadingOptionKey : Any]
        let attributedString = try! NSAttributedString(data: htmlData!,
                                                       options: options,
                                                       documentAttributes: nil)
        cguDescriptionTextView.attributedText = attributedString
        cguDescriptionTextView.font = UIFont(name: (cguDescriptionTextView.font?.fontName)!, size: 15)
    
    }

}
