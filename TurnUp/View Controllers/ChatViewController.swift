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
import Firebase
import MessageKit
import FirebaseFirestore

private let db = Firestore.firestore()
private var reference: CollectionReference?

final class ChatViewController: MessagesViewController {
  
  private var messages: [Message] = []
  private var messageListener: ListenerRegistration?
  
  private let user: User
  private let event: Event
  private let college : String
  
  init(user: User, event: Event, college: String) {
    self.user = user
    self.event = event
    self.college = college
    super.init(nibName: nil, bundle: nil)
    
    title = event.name
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  deinit {
    messageListener?.remove()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    guard let id = event.id else {
      navigationController?.popViewController(animated: true)
      return
    }
    
    reference = db.collection([college, id, "thread"].joined(separator: "/"))
    
    navigationItem.largeTitleDisplayMode = .never
    
    maintainPositionOnKeyboardFrameChanged = true
    messageInputBar.inputTextView.tintColor = .primary
    messageInputBar.backgroundView.backgroundColor = .offWhite
    messageInputBar.sendButton.setTitleColor(.primary, for: .normal)
    
    messageInputBar.delegate = self
    messagesCollectionView.messagesDataSource = self
    messagesCollectionView.messagesLayoutDelegate = self
    messagesCollectionView.messagesDisplayDelegate = self
    
    // Change to Firestore DB
    messageListener = reference?.addSnapshotListener { querySnapshot, error in
      guard let snapshot = querySnapshot else {
        print("Error listening for event updates: \(error?.localizedDescription ?? "No error")")
        return
      }
      
      snapshot.documentChanges.forEach { change in
        self.handleDocumentChange(change)
      }
    }
  }
  
  // MARK: - Helpers
  
  private func save(_ message: Message) {
    reference?.addDocument(data: message.representation) { error in
      if let e = error {
        print("Error sending message: \(e.localizedDescription)")
        return
      }
      
      self.messagesCollectionView.scrollToBottom()
    }
  }
  
  private func insertNewMessage(_ message: Message) {
    guard !messages.contains(message) else {
      return
    }
    
    messages.append(message)
    messages.sort()
    
    let isLatestMessage = messages.index(of: message) == (messages.count - 1)
    let shouldScrollToBottom = messagesCollectionView.isAtBottom && isLatestMessage
    
    messagesCollectionView.reloadData()
    
    if shouldScrollToBottom {
      DispatchQueue.main.async {
        self.messagesCollectionView.scrollToBottom(animated: true)
      }
    }
  }
  
  private func handleDocumentChange(_ change: DocumentChange) {
    guard let message = Message(document: change.document) else {
      return
    }
    
    switch change.type {
    case .added:
      insertNewMessage(message)
      
    default:
      break
    }
  }
  
}

// MARK: - MessagesDisplayDelegate

extension ChatViewController: MessagesDisplayDelegate {
  
  func backgroundColor(for message: MessageType, at indexPath: IndexPath,
                       in messagesCollectionView: MessagesCollectionView) -> UIColor {
    
    // 1
    return isFromCurrentSender(message: message) ? .secondary : .incomingMessage
  }
  
  func shouldDisplayHeader(for message: MessageType, at indexPath: IndexPath,
                           in messagesCollectionView: MessagesCollectionView) -> Bool {
    
    // 2
    return false
  }
  
  func messageStyle(for message: MessageType, at indexPath: IndexPath,
                    in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
    
    let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
    
    // 3
    return .bubbleTail(corner, .curved)
  }
}

// MARK: - MessagesLayoutDelegate

extension ChatViewController: MessagesLayoutDelegate {
  
  func avatarSize(for message: MessageType, at indexPath: IndexPath,
                  in messagesCollectionView: MessagesCollectionView) -> CGSize {
    
    // 1
    return .zero
  }
  
  func footerViewSize(for message: MessageType, at indexPath: IndexPath,
                      in messagesCollectionView: MessagesCollectionView) -> CGSize {
    
    // 2
    return CGSize(width: 0, height: 8)
  }
  
  func heightForLocation(message: MessageType, at indexPath: IndexPath,
                         with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
    
    // 3
    return 0
  }
}

// MARK: - MessagesDataSource

extension ChatViewController: MessagesDataSource {
  
  // 1
  func currentSender() -> Sender {
    return Sender(id: user.uid, displayName: AppSettings.displayName)
  }
  
  // 2
  func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
    return messages.count
  }
  
  // 3
  func messageForItem(at indexPath: IndexPath,
                      in messagesCollectionView: MessagesCollectionView) -> MessageType {
    
    return messages[indexPath.section]
  }
  
  // 4
  func cellTopLabelAttributedText(for message: MessageType,
                                  at indexPath: IndexPath) -> NSAttributedString? {
    
    let name = message.sender.displayName
    return NSAttributedString(
      string: name,
      attributes: [
        .font: UIFont.preferredFont(forTextStyle: .caption1),
        .foregroundColor: UIColor(white: 0.3, alpha: 1)
      ]
    )
  }
}

// MARK: - MessageInputBarDelegate

extension ChatViewController: MessageInputBarDelegate {
  
  func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
    
    // 1
    let message = Message(user: user, content: text)
    
    // 2
    save(message)
    
    // 3
    inputBar.inputTextView.text = ""
  }
  
}

// MARK: - UIImagePickerControllerDelegate

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
}
