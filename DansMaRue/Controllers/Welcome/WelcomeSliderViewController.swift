//
//  WelcomeSliderViewController.swift
//  DansMaRue
//
//  Created by NTDC-Showroom on 20/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit

class WelcomeSliderViewController: UIViewController {

    var welcomePageIndex = 0
    var welcomeImage = ""
    var welcomeTitleText = ""
    var welcomeSubtitleText = ""
    
    @IBOutlet var welcomeMainImage: UIImageView!
    @IBOutlet var welcomeTitle: UILabel!
    @IBOutlet var welcomeSubtitle: UILabel!
    @IBOutlet var welcomeMainImageBackground: UIView!
    
    
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.welcomeMainImage.image = UIImage(named: welcomeImage)
        self.welcomeTitle.text = welcomeTitleText
        self.welcomeSubtitle.text = welcomeSubtitleText
        
        self.welcomeMainImage.layer.cornerRadius = welcomeMainImage.frame.height/2
        self.welcomeMainImageBackground.layer.cornerRadius = welcomeMainImageBackground.frame.height/2
        self.welcomeMainImageBackground.layer.cornerRadius = welcomeMainImageBackground.frame.height/2
        
        //Ajout du l'espacement entre les lignes
        let attributedString = NSMutableAttributedString(string: welcomeSubtitleText)
        let paragraphStyle = NSMutableParagraphStyle()
        
        paragraphStyle.lineSpacing = 3
        paragraphStyle.alignment = NSTextAlignment.center
        
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))
        
        welcomeSubtitle.attributedText = attributedString;
        
        let modelResolution = UIDevice.current.deviceResolution
        if modelResolution[0] == "640" {
            welcomeTitle.font = UIFont(name: welcomeSubtitle.font.fontName, size: 17)
            welcomeSubtitle.font = UIFont(name: welcomeSubtitle.font.fontName, size: 13)
        }
        if modelResolution[0] == "1242" {
            welcomeTitle.font = UIFont(name: welcomeSubtitle.font.fontName, size: 22)
            welcomeSubtitle.font = UIFont(name: welcomeSubtitle.font.fontName, size: 18)
        }
        

    }


}
