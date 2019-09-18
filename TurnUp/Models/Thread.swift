//
//  Thread.swift
//  TurnUp
//
//  Created by Jack Van Boening on 6/30/19.
//  Copyright © 2019 Jack Van Boening. All rights reserved.
//
import Firebase
import FirebaseFirestore

struct Thread {
  
  let id: String?
  let content: String
  let sentDate: Date
  let sender: Sender
  let voteCount: Int?
  
  var upVoteList: [String]? = []
  var downVoteList: [String]? = []
  
  var threadId: String {
    return id ?? UUID().uuidString
  }
  
  init(user: User, content: String) {
    sender = Sender(id: user.uid, displayName: AppSettings.displayName)
    self.content = content
    sentDate = Date()
    id = nil
    voteCount = 0
  }
  
  init(user: User) {
    sender = Sender(id: user.uid, displayName: AppSettings.displayName)
    content = ""
    sentDate = Date()
    id = nil
    voteCount = 0
  }
  
  init?(document: QueryDocumentSnapshot) {
    let data = document.data()
    
    guard let sentTimestamp = data["created"] as? Timestamp else {
      return nil
    }
    guard let senderID = data["senderID"] as? String else {
      return nil
    }
    guard let senderName = data["senderName"] as? String else {
      return nil
    }
    
    if let count = data["voteCount"] as? Int {
      voteCount = count
    }
    else {
      voteCount = 0
    }
    
    if let list = data["upVoteList"] as? [String] {
      upVoteList = list
    }
    
    if let list = data["downVoteList"] as? [String] {
      downVoteList = list
    }
    
    id = document.documentID
    
    self.sentDate = sentTimestamp.dateValue()
    sender = Sender(id: senderID, displayName: senderName)
    
    if let content = data["content"] as? String {
      self.content = content
    } else {
      return nil
    }
  }
}

extension Thread: DatabaseRepresentation {
  
  var representation: [String : Any] {
    var rep: [String : Any] = [
      "created": sentDate,
      "senderID": sender.id,
      "senderName": sender.displayName,
      "content": content,
    ]
    
    if let count = voteCount {
      rep["voteCount"] = count
    }
    
    if let list = upVoteList {
      rep["upVoteList"] = list
    }
    
    if let list = downVoteList {
      rep["downVoteList"] = list
    }
    
    return rep
  }
  
}

extension Thread: Comparable {
  
  static func == (lhs: Thread, rhs: Thread) -> Bool {
    return lhs.id == rhs.id
  }
  
  static func < (lhs: Thread, rhs: Thread) -> Bool {
    return lhs.sentDate > rhs.sentDate
  }
  
}
