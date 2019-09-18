//
//  ThreadVoteButton.swift
//  TurnUp
//
//  Created by Jack Van Boening on 8/12/19.
//  Copyright © 2019 Jack Van Boening. All rights reserved.
//

import UIKit

class ThreadVoteButton: UIButton {
  var id : String?
  var isUpVote : Bool?
  
  override open var isSelected: Bool {
    didSet {
      self.tintColor = isSelected ? UIColor.secondary : UIColor.lightGray
    }
  }
  
}
