// Created by Dan Federman on 4/29/22.
//
// Distributed under the MIT License
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// MARK: - Modifiers

public struct Modifiers: Codable, Hashable, OptionSet {
  public let rawValue: Int

  // general accessors
  public static let `open` = Self(rawValue: 1 << 0)
  public static let `internal` = Self(rawValue: 1 << 1)
  public static let `public` = Self(rawValue: 1 << 2)
  public static let `private` = Self(rawValue: 1 << 3)
  public static let `fileprivate` = Self(rawValue: 1 << 4)
  // set accessors
  public static let privateSet = Self(rawValue: 1 << 5)
  public static let internalSet = Self(rawValue: 1 << 6)
  public static let publicSet = Self(rawValue: 1 << 7)
  // access control
  public static let `instance` = Self(rawValue: 1 << 8)
  public static let `static` = Self(rawValue: 1 << 9)
  // function modifiers
  public static let designated = Self(rawValue: 1 << 10)
  public static let convenience = Self(rawValue: 1 << 11)
  public static let override = Self(rawValue: 1 << 12)
  public static let required = Self(rawValue: 1 << 13)

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
    case "convenience": self = .convenience
    case "override": self = .override
    case "required": self = .required
    default: self = []
    }
  }
}
