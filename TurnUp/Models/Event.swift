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

import FirebaseFirestore

struct Event {
  
  let id: String?
  let name: String
  let organization: String
  let date: String
  
  var downloadURL: URL? = nil
  
  init(name: String, organization: String, date: String) {
    id = nil
    self.name = name
    self.organization = organization
    self.date = date
  }
  
  init?(document: QueryDocumentSnapshot) {
    let data = document.data()
    
    guard let name = data["name"] as? String else {
      return nil
    }
    
    guard let organization = data["organization"] as? String else {
      return nil
    }
    
    guard let date = data["date"] as? String else {
      return nil
    }
    
    if let urlString = data["url"] as? String, let url = URL(string: urlString) {
      downloadURL = url
    }
    
    id = document.documentID
    self.name = name
    self.organization = organization
    self.date = date
  }
  
}

extension Event: DatabaseRepresentation {
  
  var representation: [String : Any] {
    var rep = ["name": name, "organization": organization, "date" : date]
    
    if let id = id {
      rep["id"] = id
    }
    
    if let url = downloadURL {
      rep["url"] = url.absoluteString
    }
    
    return rep
  }
  
}

extension Event: Comparable {
  
  static func == (lhs: Event, rhs: Event) -> Bool {
    return lhs.id == rhs.id
  }
  
  static func < (lhs: Event, rhs: Event) -> Bool {
    return lhs.name < rhs.name
  }

}
