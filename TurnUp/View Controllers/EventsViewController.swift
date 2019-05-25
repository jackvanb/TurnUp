/// Copyright (c) 2018 Jack Van Boening LLC
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
import FirebaseStorage
import FirebaseUI
import BTNavigationDropdownMenu

class EventsViewController: UITableViewController {
  
  private let toolbarLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    label.font = UIFont.systemFont(ofSize: 15)
    label.textColor = UIColor.primary
    return label
  }()
  
  private let eventCellIdentifier = "eventCell"
  private let eventCellHeight = 300
  private let eventCellPadding = 20
  private var currentEventAlertController: UIAlertController?
  
  private let db = Firestore.firestore()
  private let storage = Storage.storage()
  
  private var eventReference: CollectionReference

  private var events = [Event]()
  private var eventListener: ListenerRegistration?
  private let defaultImage: UIImage = UIImage(named: "tu-logo")!
  
  private let colleges = ["UCLA", "USC"]
  private var currentCollege : String

  
  private let currentUser: User
  
  deinit {
    eventListener?.remove()
  }
  
  init(currentUser: User) {
    self.currentUser = currentUser
    self.currentCollege = colleges[0]
    self.eventReference = db.collection(currentCollege)
    super.init(style: .grouped)
    
    title = "Events"

  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationController?.navigationBar.barTintColor = UIColor.offWhite
    navigationController?.toolbar.barTintColor = UIColor.offWhite
    
    // Drop Down Menu
    let menuView = BTNavigationDropdownMenu(navigationController: self.navigationController, containerView: self.navigationController!.view, title: BTTitle.index(0), items: colleges)

    menuView.didSelectItemAtIndexHandler = { (indexPath: Int) -> Void in
      self.currentCollege = self.colleges[indexPath]
      self.updateEventListener(self.colleges[indexPath])
    }
    
    menuView.arrowTintColor = UIColor.primary
    menuView.cellBackgroundColor = UIColor.offWhite
    menuView.cellTextLabelColor = UIColor.primary
    menuView.menuTitleColor = UIColor.primary
    menuView.cellSelectionColor = UIColor.secondary
    let dropDown = UIBarButtonItem(customView: menuView)
    navigationItem.rightBarButtonItem = dropDown

    tableView.register(UINib(nibName: "EventTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: eventCellIdentifier)
    tableView.separatorStyle = .none
    
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
  
  @objc func buttonClicked(sender: EventTableButton) {
    let button = sender

    guard let eventID = button.id else {
      return
    }
    
    // Update eventCount
    if !button.isSelected {
      updateGoingList(eventID: eventID, isGoing: true)
    }
    else {
      updateGoingList(eventID: eventID, isGoing: false)
    }
    
  }
  
  // MARK: - Helpers
  
  private func updateEventListener(_ college: String) {
    eventReference = db.collection(college)
    events.removeAll()
    tableView.reloadData()
    
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
    UIView.performWithoutAnimation {
      tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }
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
  
  private func updateGoingList(eventID: String, isGoing: Bool) -> Void {
    
    let eventRef = eventReference.document(eventID)
    
    db.runTransaction({ (transaction, errorPointer) -> Any? in
      let eventDocument: DocumentSnapshot
      do {
        try eventDocument = transaction.getDocument(eventRef)
      } catch let fetchError as NSError {
        errorPointer?.pointee = fetchError
        return nil
      }
      
      guard let oldCount = eventDocument.data()?["count"] as? Int else {
        let error = NSError(
          domain: "AppErrorDomain",
          code: -1,
          userInfo: [
            NSLocalizedDescriptionKey: "Unable to retrieve count from snapshot \(eventDocument)"
          ]
        )
        errorPointer?.pointee = error
        return nil
      }
      
      if (isGoing) {
        let newCount = oldCount + 1
        
        transaction.updateData(["count": newCount], forDocument: eventRef)
        transaction.updateData(["goingList": FieldValue.arrayUnion([self.currentUser.uid])],
                               forDocument: eventRef)
        return newCount
      }
      else {
        let newCount = oldCount - 1
        
        guard newCount >= 0 else {
          let error = NSError(
            domain: "AppErrorDomain",
            code: -2,
            userInfo: [NSLocalizedDescriptionKey: "Count \(newCount) is negative"]
          )
          errorPointer?.pointee = error
          return nil
        }
        
        transaction.updateData(["count": newCount], forDocument: eventRef)
        transaction.updateData(["goingList": FieldValue.arrayRemove([self.currentUser.uid])],
                               forDocument: eventRef)
        return newCount
      }
    }) { (object, error) in
      if let error = error {
        print("Error updating count: \(error)")
      }
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
    return CGFloat(eventCellHeight + eventCellPadding)
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: eventCellIdentifier, for: indexPath) as! EventTableViewCell
    
    // Download Event Image
    if events[indexPath.row].downloadURL != nil {
      let ref = storage.reference(forURL: events[indexPath.row].downloadURL!.absoluteString)
      cell.eventImage.sd_setImage(with: ref, placeholderImage: defaultImage)
    }
    else {
      cell.eventImage.image = defaultImage
    }
    
    // Fill Image View
    cell.eventImage.contentMode = .scaleAspectFill
    
    // Event Button State
    if let going = events[indexPath.row].goingList?.contains(self.currentUser.uid) {
      cell.eventButton.isSelected = going
    }
    else {
      cell.eventButton.isSelected = false
    }
    
    // Background Color
    cell.backgroundColor = UIColor.clear
    cell.eventButton.setBackgroundColor(color: UIColor.clear, forState: UIControl.State.normal)
    cell.eventButton.setBackgroundColor(color: UIColor.secondary, forState: UIControl.State.selected)

    
    // Evvent Button Target
    if let eventID = events[indexPath.row].id {
      cell.eventButton.id = eventID
    }
    cell.eventButton.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
    
    // Load Data
    cell.eventTitle?.text = events[indexPath.row].name
    cell.eventOrg?.text = events[indexPath.row].organization
    cell.eventDate?.text = events[indexPath.row].date.asString()
    cell.eventAddress?.text = events[indexPath.row].address
    cell.eventCount?.text = String(events[indexPath.row].count)
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let event = events[indexPath.row]
    let college = currentCollege
    let vc = ChatViewController(user: currentUser, event: event, college: college)
    navigationController?.pushViewController(vc, animated: true)
  }
  
}
