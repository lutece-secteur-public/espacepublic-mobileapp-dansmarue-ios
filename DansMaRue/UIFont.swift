//
//  UIFont.swift
//  DansMaRue
//
//  Created by alaeddine.oueslati on 19/06/2023.
//  Copyright © 2023 VilleDeParis. All rights reserved.
//

import Foundation
import UIKit

extension UIFont {
    /// Scaled and styled version of any custom Font
    ///
    /// - Parameters:
    ///   - name: Name of the Font
    ///   - textSize: text szie i.e 10, 15, 20, ...
    /// - Returns: The scaled custom Font version with the given size
    static func scaledFont(name: String, textSize size: CGFloat) -> UIFont {
        guard let customFont = UIFont(name: name, size: size) else {
            fatalError("Failed to load the \(name) font.")
        }
        return UIFontMetrics.default.scaledFont(for: customFont)
    }
}
