//
//  EventTableViewCell.swift
//  TurnUp
//
//  Created by Jack Van Boening on 5/3/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import UIKit

class EventTableViewCell: UITableViewCell {

  //MARK: Properties
  @IBOutlet weak var cardView: CardView!
  @IBOutlet weak var eventTitle: UILabel!
  @IBOutlet weak var eventOrg: UILabel!
  @IBOutlet weak var eventDate: UILabel!
  @IBOutlet weak var eventImage: UIImageView!
  @IBOutlet weak var eventButton: UIButton!
  
  override func awakeFromNib() {
      super.awakeFromNib()
      // Initialization code
  }
  
  override var frame: CGRect {
    get {
      return super.frame
    }
    set (newFrame) {
      // Center frame
      var frame = newFrame
      let newWidth = CGFloat(320)
      let space = (frame.width - newWidth) / 2
      frame.size.width = newWidth
      frame.origin.x += space
      
      // Add spacing between cells
      frame.origin.y += 10
      frame.origin.x += 10
      frame.size.height -= 15
      frame.size.width -= 2 * 10
      
      super.frame = frame
    }
  }
}
