// swiftlint:disable all
import Amplify
import Foundation

extension NoteData {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case description
    case image
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let noteData = NoteData.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "NoteData"
    model.syncPluralName = "NoteData"
    
    model.attributes(
      .index(fields: ["id"], name: nil),
      .primaryKey(fields: [noteData.id])
    )
    
    model.fields(
      .field(noteData.id, is: .required, ofType: .string),
      .field(noteData.name, is: .required, ofType: .string),
      .field(noteData.description, is: .optional, ofType: .string),
      .field(noteData.image, is: .optional, ofType: .string),
      .field(noteData.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(noteData.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<NoteData> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension NoteData: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == NoteData {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var name: FieldPath<String>   {
      string("name") 
    }
  public var description: FieldPath<String>   {
      string("description") 
    }
  public var image: FieldPath<String>   {
      string("image") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}