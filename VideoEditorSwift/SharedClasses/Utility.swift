//
//  Utility.swift
//  VideoUtilityApp
//
//  Created by Smart Mobile Tech on 28/11/18.
//

import Foundation
import UIKit

public func showAlert(message: String, title:String = "Alert", buttonTitle:String = "OK", buttonClicked:((UIAlertAction) -> Void)?){
    let objAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    objAlert.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: buttonClicked))
    UIApplication.shared.keyWindow?.rootViewController?.present(objAlert, animated: true, completion: nil)
}

extension UIColor {
    public convenience init?(hexString: String) {
        let r, g, b, a: CGFloat
        
        if hexString.hasPrefix("#") {
            let start = hexString.index(hexString.startIndex, offsetBy: 1)
            let hexColor = String(hexString[start...])
            
            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255
                    
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        
        return nil
    }
}
