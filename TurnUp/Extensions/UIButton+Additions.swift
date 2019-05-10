//
//  UIButton+Additions.swift
//  TurnUp
//
//  Created by Jack Van Boening on 5/7/19.
//  Copyright © 2019 Jack Van Boening. All rights reserved.
//

import UIKit

@IBDesignable extension UIButton {
  
  @IBInspectable var borderWidth: CGFloat {
    set {
      layer.borderWidth = newValue
    }
    get {
      return layer.borderWidth
    }
  }
  
  @IBInspectable var cornerRadius: CGFloat {
    set {
      layer.cornerRadius = newValue
    }
    get {
      return layer.cornerRadius
    }
  }
  
  @IBInspectable var borderColor: UIColor? {
    set {
      guard let uiColor = newValue else { return }
      layer.borderColor = uiColor.cgColor
    }
    get {
      guard let color = layer.borderColor else { return nil }
      return UIColor(cgColor: color)
    }
  }
  
  func setBackgroundColor(color: UIColor, forState: UIControl.State) {
    self.clipsToBounds = true  // add this to maintain corner radius
    UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
    
    if let context = UIGraphicsGetCurrentContext() {
      
      context.setFillColor(color.cgColor)
      context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
      
      let colorImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      self.setBackgroundImage(colorImage, for: forState)
    }
  }
}
