//
//  ThreadViewController.swift
//  TurnUp
//
//  Created by Jack Van Boening on 6/30/19.
//  Copyright © 2019 Jack Van Boening. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseUI

private let db = Firestore.firestore()
private let storage = Storage.storage()
private var threadReference: CollectionReference?

class ThreadViewController: UITableViewController {
  
  private var currentThreadAlertController: UIAlertController?
  
  private let threadCellIdentifier = "threadCell"
  
  private var threads = [Thread]()
  private var threadListener: ListenerRegistration?
  
  private let user: User
  private let event: Event
  private let college : String
  
  deinit {
    threadListener?.remove()
  }
  
  init(user: User, event: Event, college: String) {
    self.user = user
    self.event = event
    self.college = college
    super.init(style: .grouped)
    
    title = event.name
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    guard let id = event.id else {
      navigationController?.popViewController(animated: true)
      return
    }
    
    threadReference = db.collection([college, id, "thread"].joined(separator: "/"))
    
    tableView.register(UINib(nibName: "ThreadTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: threadCellIdentifier)
    
    threadListener = threadReference?.addSnapshotListener { querySnapshot, error in
      guard let snapshot = querySnapshot else {
        print("Error listening for event updates: \(error?.localizedDescription ?? "No error")")
        return
      }
      
      snapshot.documentChanges.forEach { change in
        self.handleDocumentChange(change)
        
      }
    }

    self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(addButtonPressed))
    tableView.estimatedRowHeight = 200
    tableView.rowHeight = UITableView.automaticDimension
  }
  
  // MARK: - Actions

  @objc private func addButtonPressed() {
    let ac = UIAlertController(title: "New Message", message: nil, preferredStyle: .alert)
    ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    ac.addTextField { field in
      field.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
      field.enablesReturnKeyAutomatically = true
      field.clearButtonMode = .whileEditing
      field.placeholder = "What's up..."
      field.returnKeyType = .done
      field.tintColor = .primary
    }
    
    let createAction = UIAlertAction(title: "Send", style: .default, handler: { _ in
      self.createThread()
    })
    createAction.isEnabled = false
    ac.addAction(createAction)
    ac.preferredAction = createAction
    
    present(ac, animated: true) {
      ac.textFields?.first?.becomeFirstResponder()
    }
    currentThreadAlertController = ac
  }
  
  @objc private func textFieldDidChange(_ field: UITextField) {
    guard let ac = currentThreadAlertController else {
      return
    }
    
    ac.preferredAction?.isEnabled = field.hasText
  }
  
  @objc func buttonClicked(sender: ThreadVoteButton) {
    let button = sender
    
    // Already Selected
    if button.isSelected {
      return
    }
    
    guard let threadID = button.id else {
      return
    }
    
    guard let isUpVote = button.isUpVote else {
      return
    }
    
    // Update vote count
    if isUpVote {
      updateVoteCount(threadID: threadID, isUpVote: true)
    }
    else {
      updateVoteCount(threadID: threadID, isUpVote: false)
    }
    
  }
    
  // MARK: - Helpers
  
  private func getThreadById(id: String) -> Thread? {
    return threads.filter({ $0.id == id }).first
  }
  
  private func createThread() {
    guard let ac = currentThreadAlertController else {
      return
    }
    
    guard let message = ac.textFields?.first?.text else {
      return
    }
    
    let channel = Thread(user: user, content: message)
    threadReference?.addDocument(data: channel.representation) { error in
      if let e = error {
        print("Error saving thread: \(e.localizedDescription)")
      }
    }
  }
    
  private func updateThreadListener() {
    threads.removeAll()
    tableView.reloadData()
    
    threadListener = threadReference?.addSnapshotListener { querySnapshot, error in
      guard let snapshot = querySnapshot else {
        print("Error listening for event updates: \(error?.localizedDescription ?? "No error")")
        return
      }
      
      snapshot.documentChanges.forEach { change in
        self.handleDocumentChange(change)
      }
    }
  }
  
  private func addThreadToTable(_ thread: Thread) {
    guard !threads.contains(thread) else {
      return
    }
    
    threads.append(thread)
    threads.sort()
    
    guard let index = threads.index(of: thread) else {
      return
    }
    tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
  }
  
  private func updateThreadInTable(_ thread: Thread) {
    guard let index = threads.index(of: thread) else {
      return
    }
    
    threads[index] = thread
    UIView.performWithoutAnimation {
      tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }
  }
  
  private func removeThreadFromTable(_ thread: Thread) {
    guard let index = threads.index(of: thread) else {
      return
    }
    
    threads.remove(at: index)
    tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
  }
  
  private func handleDocumentChange(_ change: DocumentChange) {
    guard let thread = Thread(document: change.document) else {
      return
    }
    
    switch change.type {
    case .added:
      addThreadToTable(thread)
      
    case .modified:
      updateThreadInTable(thread)
      
    case .removed:
      removeThreadFromTable(thread)
    }
  }
  
  private func updateVoteCount(threadID: String, isUpVote: Bool) -> Void {
    
    let threadRef = threadReference!.document(threadID)
    
    db.runTransaction({ (transaction, errorPointer) -> Any? in
      let threadDocument: DocumentSnapshot
      do {
        try threadDocument = transaction.getDocument(threadRef)
      } catch let fetchError as NSError {
        errorPointer?.pointee = fetchError
        return nil
      }
      
      guard let oldCount = threadDocument.data()?["voteCount"] as? Int else {
        let error = NSError(
          domain: "AppErrorDomain",
          code: -1,
          userInfo: [
            NSLocalizedDescriptionKey: "Unable to retrieve count from snapshot \(threadDocument)"
          ]
        )
        errorPointer?.pointee = error
        return nil
      }
      
      let thread = self.getThreadById(id: threadID)
      
      if (isUpVote) {
        
        let newCount =  (thread?.downVoteList?.contains(self.user.uid) ?? false) ? oldCount + 2 : oldCount + 1
        
        transaction.updateData(["voteCount": newCount], forDocument: threadRef)
        transaction.updateData(["upVoteList": FieldValue.arrayUnion([self.user.uid])],
                               forDocument: threadRef)
        transaction.updateData(["downVoteList": FieldValue.arrayRemove([self.user.uid])],
                               forDocument: threadRef)
        return newCount
      }
      else {
        
        let newCount =  (thread?.upVoteList?.contains(self.user.uid) ?? false) ? oldCount - 2 : oldCount - 1
        
        transaction.updateData(["voteCount": newCount], forDocument: threadRef)
        transaction.updateData(["downVoteList": FieldValue.arrayUnion([self.user.uid])],
                               forDocument: threadRef)
        transaction.updateData(["upVoteList": FieldValue.arrayRemove([self.user.uid])],
                               forDocument: threadRef)
        return newCount
      }
    }) { (object, error) in
      if let error = error {
        print("Error updating vote count: \(error)")
      }
    }
  }

}

// MARK: - TableViewDelegate

extension ThreadViewController {
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return threads.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: threadCellIdentifier, for: indexPath) as! ThreadTableViewCell
    
    // Up/Down Vote Button Target
    if let threadID = threads[indexPath.row].id {
      cell.threadUpVote.id = threadID
      cell.threadUpVote.isUpVote = true
      cell.threadDownVote.id = threadID
      cell.threadDownVote.isUpVote = false
    }
    cell.threadUpVote.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
    cell.threadDownVote.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
    
    // Vote Button State
    cell.threadUpVote.isSelected = threads[indexPath.row].upVoteList?.contains(self.user.uid) ?? false
    cell.threadDownVote.isSelected = threads[indexPath.row].downVoteList?.contains(self.user.uid) ?? false
    
    // Load Data
    cell.threadMessage.text = threads[indexPath.row].content
    cell.threadAuthor.text = threads[indexPath.row].sender.displayName
    cell.threadDate.text = threads[indexPath.row].sentDate.timeAgoSinceDate()
    cell.threadCount.text = String(threads[indexPath.row].voteCount!)
    
    return cell
  }
}

