//
//  Date+Additions.swift
//  TurnUp
//
//  Created by Jack Van Boening on 5/10/19.
//  Copyright © 2019 Jack Van Boening. All rights reserved.
//
import UIKit

extension Date {
  
  func asString() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMM d"
    return dateFormatter.string(from: self)
  }
}
