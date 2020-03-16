// Created by Francisco Diaz on 3/14/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import Foundation

extension FileManager {

  /// Finds all the swift files at a given file URL
  /// If the baseURL is a folder, it will traverse all its subdirectories for any .swift file
  ///
  /// - Parameter baseURL: The URL to look for Swift files. It can either be a file or a directory
  /// - Returns: All the files with a .swift extension at the given URL or an empty array if none exist
  public func swiftFiles(at baseURL: URL) -> [URL] {
    guard baseURL.hasDirectoryPath else {
      return baseURL.pathExtension == "swift" ? [baseURL] : []
    }

    var swiftFiles: [URL] = []

    let enumerator = self.enumerator(atPath: baseURL.path)
    while let path = enumerator?.nextObject() as? String {
      let fileURL = URL(string: path, relativeTo: baseURL)
      if let fileURL = fileURL, fileURL.pathExtension == "swift" {
        swiftFiles.append(fileURL.standardizedFileURL)
      }
    }

    return swiftFiles
  }
}
