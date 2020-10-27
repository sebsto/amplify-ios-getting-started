// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "e8824b1b2bf439a3d1429d60eacb3825"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: NoteData.self)
  }
}