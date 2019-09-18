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
  
  func timeAgoSinceDate() -> String {
    
    let fromDate = self
    let toDate = Date()
    
    if let interval = Calendar.current.dateComponents([.year], from: fromDate, to: toDate).year, interval > 0  {
      
      return "\(interval)" + "yr"
    }
    
    if let interval = Calendar.current.dateComponents([.month], from: fromDate, to: toDate).month, interval > 0  {
      
      return "\(interval)" + "mo"
    }
    
    if let interval = Calendar.current.dateComponents([.day], from: fromDate, to: toDate).day, interval > 0  {
      
      return "\(interval)" + "dy"
    }
    
    if let interval = Calendar.current.dateComponents([.hour], from: fromDate, to: toDate).hour, interval > 0 {
      
      return "\(interval)" + "hr"
    }
    
    if let interval = Calendar.current.dateComponents([.minute], from: fromDate, to: toDate).minute, interval > 0 {
      
      return "\(interval)" + "m"
    }
    
    return "a moment ago"
  }
}
