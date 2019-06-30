//
//  UIImageView+Additions.swift
//  TurnUp
//
//  Created by Jack Van Boening on 5/24/19.
//  Copyright © 2019 Jack Van Boening. All rights reserved.
//

import UIKit

extension UIImageView {

  func roundCorners(corners:UIRectCorner, radius: CGFloat)
  {
    let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
    let mask = CAShapeLayer()
    mask.path = path.cgPath
    self.layer.mask = mask
  }

}
