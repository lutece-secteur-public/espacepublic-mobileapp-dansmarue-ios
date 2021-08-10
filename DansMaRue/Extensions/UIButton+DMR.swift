//
//  UIButton+DMR.swift
//  DansMaRue
//
//  Created by xavier.noel on 28/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import Foundation
import UIKit


class UIButton_Custom: UIButton {
    required public init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        self.layer.cornerRadius = 25
        self.layer.borderWidth = 1.2
        self.frame.size = CGSize(width: self.frame.size.width, height: 49.0)
        self.titleLabel?.font = UIFont(name: Constants.fontDmr, size: 16.0)
        
        self.setTitleColor(UIColor.white, for: UIControl.State.normal)

    }
}


class UIButton_AddAnomalie: UIButton {
    required public init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        self.layer.cornerRadius = 0.5 * self.bounds.size.width
        self.layer.borderWidth = 0
        self.titleLabel?.font = UIFont(name: Constants.fontDmr, size: 32.0)
        self.setTitle("+",for: .normal)
        
        self.setTitleColor(UIColor.white, for: UIControl.State.normal)
        
        self.backgroundColor = UIColor.pinkButtonDmr()
        
        self.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 5, right: 0)
    }
}

class UIButton_PublierAnomalie: UIButton {
    required public init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        self.layer.cornerRadius = 7
        self.layer.borderWidth = 0

        //self.titleLabel?.font = UIFont(name: "Montserrat", size: 20.0)
        self.setTitle(Constants.TitleButton.publier,for: .normal)
        
        self.setTitleColor(UIColor.white, for: UIControl.State.normal)
        
        self.backgroundColor = UIColor.pinkButtonDmr()
        
    }
}

class UIButton_Connexion: UIButton {
    required public init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        self.layer.cornerRadius = 7
        self.layer.borderWidth = 0
        
        
        self.titleLabel?.font = UIFont(name: Constants.fontDmr, size: 20.0)
        self.setTitle(Constants.TitleButton.connexion,for: .normal)
        
        self.setTitleColor(UIColor.white, for: UIControl.State.normal)
        
        self.backgroundColor = UIColor.pinkButtonDmr()
        
    }
}


class UIButton_PrendrePhoto: UIButton {
    required public init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        self.layer.cornerRadius = 0
        //self.layer.borderWidth = 1
        
        let topBorder = CALayer()
        topBorder.borderColor = UIColor.lightGreyDmr().cgColor;
        topBorder.borderWidth = 1;
        topBorder.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 1)
        self.layer.addSublayer(topBorder)
        
        self.titleLabel?.font = UIFont(name: Constants.fontDmr, size: 20.0)
        self.setTitle(Constants.TitleButton.prendrePhoto,for: .normal)
        
        self.setTitleColor(UIColor.pinkButtonDmr(), for: UIControl.State.normal)
        
        self.backgroundColor = UIColor.white
        
    }
}

class UIButton_RechercherPhoto: UIButton {
    required public init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        self.layer.cornerRadius = 0
        //self.layer.borderWidth = 0
        
        let topBorder = CALayer()
        topBorder.borderColor = UIColor.lightGreyDmr().cgColor;
        topBorder.borderWidth = 1;
        topBorder.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 1)
        self.layer.addSublayer(topBorder)
        
        self.titleLabel?.font = UIFont(name: Constants.fontDmr, size: 20.0)
        self.setTitle(Constants.TitleButton.choisirAlbum,for: .normal)
        
        self.setTitleColor(UIColor.pinkButtonDmr(), for: UIControl.State.normal)
        
        self.backgroundColor = UIColor.white
        
    }
}

class UIButton_AnnulerPhoto: UIButton {
    required public init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        self.layer.cornerRadius = 10
        self.layer.borderWidth = 0
        
        self.titleLabel?.font = UIFont(name: Constants.fontDmr, size: 20.0)
        self.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16.0)
        self.setTitle(Constants.AlertBoxTitle.annuler,for: .normal)
        
        self.setTitleColor(UIColor.pinkButtonDmr(), for: UIControl.State.normal)
        
        self.backgroundColor = UIColor.white
        
    }
}


class UIButton_EditAddress: UIButton {
    required public init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        self.layer.cornerRadius = 0
        self.layer.borderWidth = 0
        //self.titleLabel?.font = UIFont(name: "Montserrat", size: 32.0)
        
        self.setTitleColor(UIColor.white, for: UIControl.State.normal)
        self.setTitle("",for: .normal)
        
        //self.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 0)
        let image = UIImage(named: Constants.Image.iconEdit)
        self.setImage(image, for: .normal)
        
    }
}

class UIButton_Congrats: UIButton {
    required public init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        self.layer.cornerRadius = 10
        self.layer.borderWidth = 0
        
        self.setTitleColor(UIColor.white, for: UIControl.State.normal)
        self.setTitle(Constants.TitleButton.feliciter ,for: .normal)
        self.titleLabel?.font = UIFont(name: Constants.fontDmr, size: 20.0)
        self.backgroundColor = UIColor.greenDmr()
        let image = UIImage(named:Constants.Image.thumbsUp)
        self.setImage(image, for: .normal)
        
        
    }
}

class UIButton_Solved: UIButton {
    required public init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
        
        self.layer.cornerRadius = 10
        self.layer.borderWidth = 0
        
        self.setTitleColor(UIColor.white, for: UIControl.State.normal)
        self.setTitle(Constants.TitleButton.declarerCommeResolue,for: .normal)
        self.titleLabel?.font = UIFont(name: Constants.fontDmr, size: 20.0)
        self.backgroundColor = UIColor.pinkDmr()
    }
}

class UIButton_MyParisianAccount: UIButton {
    required public init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
        
        self.layer.cornerRadius = 10
        self.layer.borderWidth = 0
        
        self.setTitleColor(UIColor.white, for: UIControl.State.normal)
        self.setTitle(Constants.TitleButton.monCompte,for: .normal)
        self.backgroundColor = UIColor.pinkDmr()
        let image = UIImage(named:Constants.Image.iconMonCompte)
        self.setImage(image, for: .normal)
        self.semanticContentAttribute = .forceLeftToRight
    }
}


class UIButton_CloseAnomalie: UIButton {
    required public init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        self.layer.cornerRadius = 0.5 * self.bounds.size.width
        self.layer.borderWidth = 0
        self.titleLabel?.font = UIFont(name: Constants.fontDmr, size: 18.0)
        self.setTitle("",for: .normal)
        
        self.setTitleColor(UIColor.white, for: UIControl.State.normal)
        
        self.backgroundColor = UIColor.black
        
        self.setImage(UIImage(named: "close_button"), for: .normal)
    }
}


