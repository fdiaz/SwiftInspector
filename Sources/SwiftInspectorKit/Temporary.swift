// Created by Francisco Diaz on 10/6/19.
//
// Copyright (c) 2020 Francisco Diaz
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

struct Temporary {
  /// Creates a Swift file in a temporary directory
  ///
  /// - Parameter content: A String representing the contents of the Swift file
  /// - Parameter name: The name of the Swift file
  /// - Parameter fileExtension: The name of the file. Defaults to "swift"
  /// - Parameter parentPath: The path to the parent folder where this file will be created
  /// - Returns: The file URL where the created file is stored
  static func makeFile(
    content: String,
    name: String = UUID().uuidString,
    fileExtension: String = "swift",
    atPath parentPath: String = NSTemporaryDirectory()) throws -> URL
  {
    let temporaryDirectoryURL = URL(fileURLWithPath: parentPath,
                                    isDirectory: true)
    let fileName = "\(name).\(fileExtension)"
    let temporaryFileURL =
      temporaryDirectoryURL.appendingPathComponent(fileName)

    let data = Data(content.utf8)
    try data.write(to: temporaryFileURL,
                   options: .atomic)
    
    return temporaryFileURL
  }

  /// Creates a folder inside a temporary directory
  ///
  /// - Parameter name: The name of the directory
  /// - Parameter parentPath: The path to the parent folder where this folder will be created
  /// - Returns: The file URL where the directory was created
  static func makeFolder(name: String = UUID().uuidString, parentPath: String = NSTemporaryDirectory()) throws -> URL {
    let temporaryDirectoryURL = URL(fileURLWithPath: parentPath, isDirectory: true)
    let folderURL = temporaryDirectoryURL.appendingPathComponent(name, isDirectory: true)
    try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

    return folderURL
  }

  /// Removes an item (file or directory) in the specified location
  ///
  /// - Parameter fileURL: The location of the file to remove
  static func removeItem(at fileURL: URL) throws {
    try FileManager.default.removeItem(at: fileURL)
  }
}
