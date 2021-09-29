// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "a7106e5817ec405650b38ad2a831669a"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: NoteData.self)
  }
}