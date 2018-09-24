//
//  UIView+DMR.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 28/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    /**
     Set x Position
     
     :param: x CGFloat
     */
    func setX(_ x:CGFloat) {
        var frame:CGRect = self.frame
        frame.origin.x = x
        self.frame = frame
    }
    
    /**
     Set y Position
     
     :param: y CGFloat
     */
    func setY(_ y:CGFloat) {
        var frame:CGRect = self.frame
        frame.origin.y = y
        self.frame = frame
    }
    
    /**
     Set Width
     
     :param: width CGFloat
     */
    func setWidth(_ width:CGFloat) {
        var frame:CGRect = self.frame
        frame.size.width = width
        self.frame = frame
    }
    
    /**
     Set Height
     
     :param: height CGFloat
     */
    func setHeight(_ height:CGFloat) {
        var frame:CGRect = self.frame
        frame.size.height = height
        self.frame = frame
    }
    
    func resize(with:CGFloat, height:CGFloat) {
        setWidth(with)
        setHeight(height)
    }
}
