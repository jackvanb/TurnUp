//
//  SubtitleTableViewCell.swift
//  TurnUp
//
//  Created by Jack Van Boening on 4/28/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import UIKit

class SubtitleTableViewCell: UITableViewCell {
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
