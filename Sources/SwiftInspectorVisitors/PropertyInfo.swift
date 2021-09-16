// Created by Michael Bachand on 9/15/21.
// Copyright © 2021 Airbnb Inc. All rights reserved.

// MARK: - PropertyInfo

public struct PropertyInfo: Codable, Hashable, CustomDebugStringConvertible {
  /// The name of the property
  public let name: String
  /// The type of the property if it's present
  public let typeDescription: TypeDescription?
  /// Modifier set for this type
  public let modifiers: Modifier
  /// The paradigm of this property, along with any associated data that cannot be reasonably represented statically.
  public let paradigm: Paradigm

  public var debugDescription: String {
    "\(modifiers.rawValue) \(name) \(typeDescription?.asSource ?? "") \(paradigm)"
  }
}

// MARK: - PropertyInfo.Modifier

extension PropertyInfo {
  public struct Modifier: Codable, Hashable, OptionSet {
    public let rawValue: Int

    // general accessors
    public static let `open` = Modifier(rawValue: 1 << 0)
    public static let `internal` = Modifier(rawValue: 1 << 1)
    public static let `public` = Modifier(rawValue: 1 << 2)
    public static let `private` = Modifier(rawValue: 1 << 3)
    public static let `fileprivate` = Modifier(rawValue: 1 << 4)
    // set accessors
    public static let privateSet = Modifier(rawValue: 1 << 5)
    public static let internalSet = Modifier(rawValue: 1 << 6)
    public static let publicSet = Modifier(rawValue: 1 << 7)
    // access control
    public static let `instance` = Modifier(rawValue: 1 << 8)
    public static let `static` = Modifier(rawValue: 1 << 9)

    public init(rawValue: Int)  {
      self.rawValue = rawValue
    }

    public init(stringValue: String) {
      switch stringValue {
      case "open": self = .open
      case "public": self = .public
      case "private": self = .private
      case "fileprivate": self = .fileprivate
      case "private(set)": self = .privateSet
      case "internal(set)": self = .internalSet
      case "public(set)": self = .publicSet
      case "internal": self = .internal
      case "static": self = .static
      default: self = []
      }
    }
  }
}

// MARK: - PropertyInfo.Paradigm

extension PropertyInfo {
  public enum Paradigm: Codable, Hashable {
    /// A `let` property with no `=`.
    case undefinedConstant
    /// A `let` property with an `=`.
    /// - Parameter initializerDescription: A source-accurate description of the initializer.
    /// - Important: The initializer description does not include the equal sign.
    case definedConstant(_ initializerDescription: String)
    /// A  `var` property with no `=`.
    case undefinedVariable
    /// A `var ` property with an `=`.
    /// - Parameter initializerDescription: A source-accurate description of the initializer.
    /// - Important: The initializer description does not include the equal sign.
    case definedVariable(_ initializerDescription: String)
    /// A computed `var` property.
    /// - Parameter codeBlockDescription: A source-accurate description of the code block which computes the value
    /// - Important: The code block description does not include the opening/closing braces.
    case computedVariable(_ codeBlockDescription: String)

    // MARK: Lifecycle

    public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      let caseValue = try values.decode(Int.self, forKey: .caseValue)
      switch caseValue {
      case Self.undefinedConstantValue:
        self = .undefinedConstant

      case Self.definedConstantValue:
        let initializerDescription = try values.decode(String.self, forKey: .initializerDescription)
        self = .definedConstant(initializerDescription)

      case Self.undefinedVariableValue:
        self = .undefinedVariable

      case Self.definedVariableValue:
        let initializerDescription = try values.decode(String.self, forKey: .initializerDescription)
        self = .definedVariable(initializerDescription)

      case Self.computedVariableValue:
        let codeBlockDesciption = try values.decode(String.self, forKey: .codeBlockDesciption)
        self = .computedVariable(codeBlockDesciption)

      default:
        throw CodingError.unknownCase
      }
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(caseValue, forKey: .caseValue)
      switch self {
      case .undefinedConstant:
        break
      case .definedConstant(let initializerDescription):
        try container.encode(initializerDescription, forKey: .initializerDescription)
      case .undefinedVariable:
        break
      case .definedVariable(let initializerDescription):
        try container.encode(initializerDescription, forKey: .initializerDescription)
      case .computedVariable(let codeBlockDesciption):
        try container.encode(codeBlockDesciption, forKey: .codeBlockDesciption)
      }
    }

    // MARK: Public

    public enum CodingError: Error {
      case unknownCase
    }

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
      /// The value for this key is a numerical value for the case.
      case caseValue
      /// The value for this key is a source-accurate description of the initializer encoded as a string, if one exists for this case.
      case initializerDescription
      /// The value for this key is a source-accurate description of the computation code block encoded as a string, if one exists for this
      /// case.
      case codeBlockDesciption
    }

    private static let undefinedConstantValue = 0
    private static let definedConstantValue = 1
    private static let undefinedVariableValue = 2
    private static let definedVariableValue = 3
    private static let computedVariableValue = 4

    private var caseValue: Int {
      switch self {
      case .undefinedConstant: return Self.undefinedConstantValue
      case .definedConstant: return Self.definedConstantValue
      case .undefinedVariable: return Self.undefinedVariableValue
      case .definedVariable: return Self.definedVariableValue
      case .computedVariable: return Self.computedVariableValue
      }
    }
  }
}
