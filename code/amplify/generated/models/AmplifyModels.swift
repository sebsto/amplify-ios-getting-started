// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "40cfecf3b6382e76d7c59f71913e81e6"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: NoteData.self)
  }
}