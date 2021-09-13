// Created by Dan Federman on 9/11/21.
// Copyright © 2021 Dan Federman
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

import Foundation

/// Indicates that an internal confidence check failed.
/// Posts the `AssertionFailure.notification` if `AssertionFailure.postNotification` is `true`, otherwise calls `Swift.assertionFailure`.
/// Using this method instead of `Swift.assertionFailure` allows for testing that assertions are triggered.
@inlinable public func assertionFailureOrPostNotification(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) {
  if AssertionFailure.postNotification {
    NotificationCenter.default.post(AssertionFailure.notification)
  } else {
    assertionFailure(message(), file: file, line: line)
  }
}

/// A collection of constants that enable testing assertion failures.
public enum AssertionFailure {
  /// The notification that is posted when `assertionFailureOrPostNotification` is called and `postNotification` is `true`.
  public static let notification = Notification(name: Notification.Name(rawValue: "SwiftInspector.AssertionFailure"))
  /// Set to `true` to post notifications in `assertionFailureOrPostNotification` rather than calling through to `Swift.assertionFailure`.
  public static var postNotification = false
}
