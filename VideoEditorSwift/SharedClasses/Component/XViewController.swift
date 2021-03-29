//
//  ViewControllerX.swift
//  002 - Credit Card Checkout
//
//  Created by Smart Mobile Tech on 28/11/18.
//

import UIKit

@IBDesignable
class XViewController: UIViewController {
    
    @IBInspectable var lightStatusBar: Bool = false
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            if lightStatusBar {
                return UIStatusBarStyle.lightContent
            } else {
                return UIStatusBarStyle.default
            }
        }
    }
}
