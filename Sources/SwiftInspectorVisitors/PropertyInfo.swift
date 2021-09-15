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
    "\(modifiers.rawValue) \(name) \(typeDescription?.asSource ?? "")"
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
    case definedConstant(_ initializerDescription: String)
    /// A  `var` property with no `=`.
    case undefinedVariable
    /// A `var ` property with an `=`.
    /// - Parameter initializerDescription: A source-accurate description of the initializer.
    case definedVariable(_ initializerDescription: String)
    /// A computed `var` property.
    /// - Parameter codeBlockDesciption: A source-accurate description of the code block which computes the value.
    case computedVariable(_ codeBlockDesciption: String)

    public init(from decoder: Decoder) throws {
      // TODO implement
      fatalError()
    }

    public func encode(to encoder: Encoder) throws {
      // TODO implement
      fatalError()
    }
  }
}
