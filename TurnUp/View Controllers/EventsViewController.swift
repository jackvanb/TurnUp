/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import FirebaseAuth
import FirebaseFirestore

class EventsViewController: UITableViewController {
  
  private let toolbarLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    label.font = UIFont.systemFont(ofSize: 15)
    return label
  }()
  
  private let eventCellIdentifier = "eventCell"
  private var currentEventAlertController: UIAlertController?
  
  private let db = Firestore.firestore()
  
  private var eventReference: CollectionReference {
    return db.collection("events")
  }
  
  private var events = [Event]()
  private var eventListener: ListenerRegistration?
  
  private let currentUser: User
  
  deinit {
    eventListener?.remove()
  }
  
  init(currentUser: User) {
    self.currentUser = currentUser
    super.init(style: .grouped)
    
    title = "Events"
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    clearsSelectionOnViewWillAppear = true
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: eventCellIdentifier)
    
    toolbarItems = [
      UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
      UIBarButtonItem(customView: toolbarLabel),
      UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
    ]
    toolbarLabel.text = AppSettings.displayName
    
    eventListener = eventReference.addSnapshotListener { querySnapshot, error in
      guard let snapshot = querySnapshot else {
        print("Error listening for event updates: \(error?.localizedDescription ?? "No error")")
        return
      }
      
      snapshot.documentChanges.forEach { change in
        self.handleDocumentChange(change)
      }
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    navigationController?.isToolbarHidden = false
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    navigationController?.isToolbarHidden = true
  }
  
  // MARK: - Actions
  
  @objc private func textFieldDidChange(_ field: UITextField) {
    guard let ac = currentEventAlertController else {
      return
    }
    
    ac.preferredAction?.isEnabled = field.hasText
  }
  
  // MARK: - Helpers
    
  private func addEventToTable(_ event: Event) {
    guard !events.contains(event) else {
      return
    }
    
    events.append(event)
    events.sort()
    
    guard let index = events.index(of: event) else {
      return
    }
    tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
  }
  
  private func updateEventInTable(_ event: Event) {
    guard let index = events.index(of: event) else {
      return
    }
    
    events[index] = event
    tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
  }
  
  private func removeEventFromTable(_ event: Event) {
    guard let index = events.index(of: event) else {
      return
    }
    
    events.remove(at: index)
    tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
  }
  
  private func handleDocumentChange(_ change: DocumentChange) {
    guard let event = Event(document: change.document) else {
      return
    }
    
    switch change.type {
    case .added:
      addEventToTable(event)
      
    case .modified:
      updateEventInTable(event)
      
    case .removed:
      removeEventFromTable(event)
    }
  }
  
}

// MARK: - TableViewDelegate

extension EventsViewController {
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return events.count
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 55
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: eventCellIdentifier, for: indexPath)
    
    cell.accessoryType = .disclosureIndicator
    cell.textLabel?.text = events[indexPath.row].name
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let event = events[indexPath.row]
    let vc = ChatViewController(user: currentUser, event: event)
    navigationController?.pushViewController(vc, animated: true)
  }
  
}
