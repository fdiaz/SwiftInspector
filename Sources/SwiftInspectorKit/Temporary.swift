// Created by Francisco Diaz on 10/6/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Foundation

struct Temporary {
  /// Creates a Swift file in a temporary directory
  ///
  /// - Parameter content: A String representing the contents of the Swift file
  /// - Returns: The file URL where the created file is stored
  static func makeSwiftFile(content: String) throws -> URL {
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

  /// Creates a folder iniside a temporary directory
  ///
  /// - Parameter name: The name of the directory
  /// - Returns: The file URL where the directory was created
  static func makeFolder(name: String = UUID().uuidString) throws -> URL {
    let temporaryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    let pathURL = temporaryURL.appendingPathComponent(name, isDirectory: true)
    try FileManager.default.createDirectory(at: pathURL, withIntermediateDirectories: true)

    return pathURL
  }

  /// Removes an item (file or directory) in the specified location
  ///
  /// - Parameter fileURL: The location of the file to remove
  static func removeItem(at fileURL: URL) throws {
    try FileManager.default.removeItem(at: fileURL)
  }
}
