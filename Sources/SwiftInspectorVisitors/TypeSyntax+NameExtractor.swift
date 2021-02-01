// Created by dan_federman on 1/30/21.
// Copyright © 2021 Airbnb Inc. All rights reserved.

import SwiftSyntax

extension TypeSyntax {

  /// Returns the the qualified name for the type the receiver represents.
  /// - Warning: Access this property only on a `SimpleTypeIdentifierSyntax` or `MemberTypeIdentifierSyntax`.
  var qualifiedName: String {
    if let typeIdentifier = self.as(SimpleTypeIdentifierSyntax.self) {
      return typeIdentifier.name.text

    } else if let typeIdentifier = self.as(MemberTypeIdentifierSyntax.self) {
      let baseName = typeIdentifier.baseType.qualifiedName
      return "\(baseName).\(typeIdentifier.name.text)"

    } else {
      assertionFailure("TypeSyntax of unexpected type. Defaulting to `description`.")
      // The description is a source-accurate description of this node,
      // so it is a reasonable fallback.
      return description.trimmingCharacters(in: .whitespacesAndNewlines)
    }
  }

}
