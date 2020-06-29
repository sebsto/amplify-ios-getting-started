// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "596f69f6a16e95976dfd027845822ee8"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: NoteData.self)
  }
}