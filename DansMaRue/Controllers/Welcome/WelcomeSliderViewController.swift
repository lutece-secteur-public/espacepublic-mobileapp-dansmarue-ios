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
    
    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        welcomeMainImage.image = UIImage(named: welcomeImage)
        welcomeTitle.text = welcomeTitleText
        welcomeSubtitle.text = welcomeSubtitleText
        
        welcomeMainImage.layer.cornerRadius = welcomeMainImage.frame.height/2
        welcomeMainImageBackground.layer.cornerRadius = welcomeMainImageBackground.frame.height/2
        welcomeMainImageBackground.layer.cornerRadius = welcomeMainImageBackground.frame.height/2
        
        // Ajout du l'espacement entre les lignes
        let attributedString = NSMutableAttributedString(string: welcomeSubtitleText)
        let paragraphStyle = NSMutableParagraphStyle()
        
        paragraphStyle.lineSpacing = 3
        paragraphStyle.alignment = NSTextAlignment.center
        
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedString.length))
        
        welcomeSubtitle.attributedText = attributedString
        configureAccessibility()
    }
    
    func configureAccessibility() {
        welcomeTitle.adjustsFontForContentSizeCategory = true
        welcomeTitle.font = UIFont.scaledFont(name: "Montserrat-Regular", textSize: 20)
        welcomeSubtitle.adjustsFontForContentSizeCategory = true
        welcomeSubtitle.font = UIFont.scaledFont(name: "Montserrat-Regular", textSize: 16)
        welcomeTitle.isAccessibilityElement = true
        welcomeTitle.accessibilityTraits = .header
        welcomeTitle.accessibilityLabel = welcomeTitleText
        welcomeSubtitle.isAccessibilityElement = true
        welcomeSubtitle.accessibilityLabel = welcomeSubtitleText
        welcomeSubtitle.accessibilityTraits = .staticText
    }
}
