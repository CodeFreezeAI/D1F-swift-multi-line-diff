//
//  File.swift
//  MultiLineDiff
//
//  Created by Todd Bruss on 5/20/25.
//

import Foundation

extension MultiLineDiff {
    /// Saves a diff result to a file
    /// - Parameters:
    ///   - diff: The diff result to save
    ///   - fileURL: The URL of the file to write to
    ///   - prettyPrinted: Whether to format the JSON for human readability
    /// - Throws: An error if saving fails
    ///
    public static func saveDiffToFile(_ diff: DiffResult, fileURL: URL, prettyPrinted: Bool = true) throws {
        let data = try encodeDiffToJSON(diff, prettyPrinted: prettyPrinted)
        try data.write(to: fileURL)
    }

    /// Loads a diff result from a file
    /// - Parameter fileURL: The URL of the file to read from
    /// - Returns: The loaded diff result
    /// - Throws: An error if loading fails
    public static func loadDiffFromFile(fileURL: URL) throws -> DiffResult {
        let data = try Data(contentsOf: fileURL)
        return try decodeDiffFromJSON(data)
    }
}
