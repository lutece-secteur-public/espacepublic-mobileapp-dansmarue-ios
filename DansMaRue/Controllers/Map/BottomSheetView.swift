//
//  BottomSheetView.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 14/02/2018.
//  Copyright © 2018 VilleDeParis. All rights reserved.
//

import UIKit

class BottomSheetView: UIView {
    
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !clipsToBounds && !isHidden && alpha > 0 {
            for member in subviews.reversed() {
                let subPoint = member.convert(point, from: self)
                if let result = member.hitTest(subPoint, with: event) {
                    return result
                }
            }
        }
        return nil
    }

}
