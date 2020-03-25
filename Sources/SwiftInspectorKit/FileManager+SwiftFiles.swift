// Created by Francisco Diaz on 3/14/20.
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

    guard let enumerator = self.enumerator(
      at: baseURL,
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles])
      else
    {
      return  []
    }

    for case let fileURL as URL in enumerator {
      if fileURL.pathExtension == "swift" {
        swiftFiles.append(fileURL.standardizedFileURL)
      }
    }

    return swiftFiles
  }
}
