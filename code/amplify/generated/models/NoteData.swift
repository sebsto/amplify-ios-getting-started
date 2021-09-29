// swiftlint:disable all
import Amplify
import Foundation

public struct NoteData: Model {
  public let id: String
  public var name: String
  public var description: String?
  public var image: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      name: String,
      description: String? = nil,
      image: String? = nil) {
    self.init(id: id,
      name: name,
      description: description,
      image: image,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      name: String,
      description: String? = nil,
      image: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.name = name
      self.description = description
      self.image = image
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}