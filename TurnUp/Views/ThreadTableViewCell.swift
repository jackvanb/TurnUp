//
//  ThreadTableViewCell.swift
//  TurnUp
//
//  Created by Jack Van Boening on 6/30/19.
//  Copyright © 2019 Jack Van Boening. All rights reserved.
//

import UIKit

class ThreadTableViewCell: UITableViewCell {

  @IBOutlet weak var threadMessage: UILabel!
  @IBOutlet weak var threadAuthor: UILabel!
  @IBOutlet weak var threadDate: UILabel!
  @IBOutlet weak var threadUpVote: ThreadVoteButton!
  @IBOutlet weak var threadDownVote: ThreadVoteButton!
  @IBOutlet weak var threadCount: UILabel!
  
  override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
