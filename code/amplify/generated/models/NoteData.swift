// swiftlint:disable all
import Amplify
import Foundation

public struct NoteData: Model {
  public let id: String
  public var name: String
  public var description: String?
  public var image: String?
  
  public init(id: String = UUID().uuidString,
      name: String,
      description: String? = nil,
      image: String? = nil) {
      self.id = id
      self.name = name
      self.description = description
      self.image = image
  }
}