// Created by dan_federman on 1/30/21.
// Copyright © 2021 Airbnb Inc. All rights reserved.

import SwiftSyntax

extension TypeSyntax {

  /// Returns the the qualified name for the type the receiver represents.
  /// - Warning: Access this property only on a `SimpleTypeIdentifierSyntax`, or `MemberTypeIdentifierSyntax`, or `CompositionTypeElementListSyntax`.
  var qualifiedNames: [String] {
    if let typeIdentifier = self.as(SimpleTypeIdentifierSyntax.self) {
      return [typeIdentifier.name.text]

    } else if let typeIdentifier = self.as(MemberTypeIdentifierSyntax.self) {
      let baseNames = typeIdentifier.baseType.qualifiedNames
      return baseNames.map { "\($0).\(typeIdentifier.name.text)" }

    } else if let typeIdentifiers = self.as(CompositionTypeSyntax.self) {
      return typeIdentifiers.elements.flatMap { $0.type.qualifiedNames }

    } else if let typeIdentifier = self.as(OptionalTypeSyntax.self) {
      return typeIdentifier.wrappedType.qualifiedNames.flatMap { ["\($0)?"] }

    } else {
      assertionFailure("TypeSyntax of unexpected type. Defaulting to `description`.")
      // The description is a source-accurate description of this node,
      // so it is a reasonable fallback.
      return [description.trimmingCharacters(in: .whitespacesAndNewlines)]
    }
  }

}
