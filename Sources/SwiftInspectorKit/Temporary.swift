// Created by Francisco Diaz on 10/6/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Foundation

struct Temporary {
  /// Creates a Swift file in a temporary directory
  ///
  /// - Parameter content: A String representing the contents of the Swift file
  /// - Returns: The file URL where the created file is stored
  static func makeSwiftFile(withContent content: String) throws -> URL {
    let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(),
                                    isDirectory: true)
    let fileName = UUID().uuidString + ".swift"
    let temporaryFileURL =
      temporaryDirectoryURL.appendingPathComponent(fileName)

    let data = Data(content.utf8)
    try data.write(to: temporaryFileURL,
                   options: .atomic)
    
    return temporaryFileURL
  }

  /// Removes a file in the specified location
  ///
  /// - Parameter fileURL: The location of the file to remove
  static func removeFile(at fileURL: URL) throws {
    try FileManager.default.removeItem(at: fileURL)
  }
}
