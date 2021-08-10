//
//  MessageTypeAnoViewController.swift
//  DansMaRue
//
//  Created by geoffroy.huet on 01/10/2019.
//  Copyright © 2019 VilleDeParis. All rights reserved.
//

import UIKit

class MessageTypeAnoViewController: UIViewController {
    
    @IBOutlet weak var typeAnoTextView: UITextView!
    var typeAnomalie = TypeAnomalie()
    
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = Constants.LabelMessage.titreTypeAno
        
        //Possibilité d'ajouter des balise style au richtext définie dans le BO
        //Ex: <style type='text/css'>p{color: #26b72b;font-size: 52px;}</style>
        
        let htmlData = NSString(string: typeAnomalie.messageBO).data(using: String.Encoding.utf8.rawValue)
        let options = [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html]
        let attributedString = try! NSAttributedString(data: htmlData!,
                                                       options: options,
                                                       documentAttributes: nil)
        
        typeAnoTextView.attributedText = attributedString
    }

}
