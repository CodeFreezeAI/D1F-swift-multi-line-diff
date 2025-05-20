// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

// MultiLineDiff - A library for creating and applying diffs to multi-line text
// Supports Unicode/UTF-8 strings and handles multi-line content properly

/// Represents a single diff operation
public enum DiffOperation: Equatable, Codable {
    case retain(Int)      // Keep a number of characters from the source
    case insert(String)   // Insert new content
    case delete(Int)      // Delete a number of characters from the source
    
    // Helper to get a user-friendly description of the operation
    public var description: String {
        switch self {
        case .retain(let count):
            return "retain \(count) character\(count == 1 ? "" : "s")"
        case .insert(let text):
            return "insert \"\(text.prefix(20))\(text.count > 20 ? "..." : "")\""
        case .delete(let count):
            return "delete \(count) character\(count == 1 ? "" : "s")"
        }
    }
}

/// Represents the result of a diff operation
public struct DiffResult: Equatable, Codable {
    /// The sequence of operations that transform the source text into the destination text
    public let operations: [DiffOperation]
    
    /// Creates a new diff result with the given operations
    public init(operations: [DiffOperation]) {
        self.operations = operations
    }
}

/// The main entry point for the MultiLineDiff library
public enum MultiLineDiff {
    
    /// Creates a diff between two strings
    /// - Parameters:
    ///   - source: The original string
    ///   - destination: The modified string
    /// - Returns: A DiffResult containing the operations to transform source into destination
    public static func createDiffBrus(source: String, destination: String) -> DiffResult {
        // Handle empty string cases specially for efficiency
        if source.isEmpty && destination.isEmpty {
            return DiffResult(operations: [])
        }
        
        if source.isEmpty {
            return DiffResult(operations: [.insert(destination)])
        }
        
        if destination.isEmpty {
            return DiffResult(operations: [.delete(source.count)])
        }
        
        // Use a bruss and reliable approach that always works
        var operations: [DiffOperation] = []
        
        // Find common prefix
        var prefixLength = 0
        let minLength = min(source.count, destination.count)
        
        let sourceChars = Array(source)
        let destChars = Array(destination)
        
        while prefixLength < minLength && sourceChars[prefixLength] == destChars[prefixLength] {
            prefixLength += 1
        }
        
        // Find common suffix
        var suffixLength = 0
        while suffixLength < minLength - prefixLength &&
              sourceChars[source.count - suffixLength - 1] == destChars[destination.count - suffixLength - 1] {
            suffixLength += 1
        }
        
        // Add operations
        if prefixLength > 0 {
            operations.append(.retain(prefixLength))
        }
        
        let sourceMiddleStart = prefixLength
        let sourceMiddleEnd = source.count - suffixLength
        let sourceMiddleLength = sourceMiddleEnd - sourceMiddleStart
        
        let destMiddleStart = prefixLength
        let destMiddleEnd = destination.count - suffixLength
        
        if sourceMiddleLength > 0 {
            operations.append(.delete(sourceMiddleLength))
        }
        
        if destMiddleStart < destMiddleEnd {
            let destMiddleString = String(destChars[destMiddleStart..<destMiddleEnd])
            operations.append(.insert(destMiddleString))
        }
        
        if suffixLength > 0 {
            operations.append(.retain(suffixLength))
        }
        
        return DiffResult(operations: operations)
    }
    
    /// Applies a diff to a source string
    /// - Parameters:
    ///   - source: The original string
    ///   - diff: The diff to apply
    /// - Returns: The resulting string after applying the diff
    /// - Throws: An error if the diff cannot be applied correctly
    public static func applyDiff(to source: String, diff: DiffResult) throws -> String {
        var result = ""
        var currentIndex = source.startIndex
        
        for operation in diff.operations {
            switch operation {
            case .retain(let count):
                guard currentIndex < source.endIndex else {
                    throw DiffError.invalidRetain(count: count, remainingLength: 0)
                }
                
                let endIndex = source.index(currentIndex, offsetBy: count, limitedBy: source.endIndex) ?? source.endIndex
                guard source.distance(from: currentIndex, to: endIndex) == count else {
                    throw DiffError.invalidRetain(count: count, remainingLength: source.distance(from: currentIndex, to: source.endIndex))
                }
                
                result.append(contentsOf: source[currentIndex..<endIndex])
                currentIndex = endIndex
                
            case .insert(let text):
                result.append(text)
                
            case .delete(let count):
                guard currentIndex < source.endIndex else {
                    throw DiffError.invalidDelete(count: count, remainingLength: 0)
                }
                
                let endIndex = source.index(currentIndex, offsetBy: count, limitedBy: source.endIndex) ?? source.endIndex
                guard source.distance(from: currentIndex, to: endIndex) == count else {
                    throw DiffError.invalidDelete(count: count, remainingLength: source.distance(from: currentIndex, to: source.endIndex))
                }
                
                currentIndex = endIndex
            }
        }
        
        // Check if we consumed the entire source string
        if currentIndex != source.endIndex {
            throw DiffError.incompleteApplication(unconsumedLength: source.distance(from: currentIndex, to: source.endIndex))
        }
        
        return result
    }
    
    /// Encodes a diff result to JSON data
    /// - Parameters:
    ///   - diff: The diff result to encode
    ///   - prettyPrinted: Whether to format the JSON for human readability
    /// - Returns: The encoded JSON data
    /// - Throws: An error if encoding fails
    public static func encodeDiffToJSON(_ diff: DiffResult, prettyPrinted: Bool = false) throws -> Data {
        let encoder = JSONEncoder()
        if prettyPrinted {
            encoder.outputFormatting = [.sortedKeys]
        }
        return try encoder.encode(diff)
    }
    
    /// Encodes a diff result to a JSON string
    /// - Parameters:
    ///   - diff: The diff result to encode
    ///   - prettyPrinted: Whether to format the JSON for human readability
    /// - Returns: The JSON string representation of the diff
    /// - Throws: An error if encoding fails
    public static func encodeDiffToJSONString(_ diff: DiffResult, prettyPrinted: Bool = false) throws -> String {
        let data = try encodeDiffToJSON(diff, prettyPrinted: prettyPrinted)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw DiffError.encodingFailed
        }
        return jsonString
    }
    
    /// Decodes a diff result from JSON data
    /// - Parameter data: The JSON data to decode
    /// - Returns: The decoded diff result
    /// - Throws: An error if decoding fails
    public static func decodeDiffFromJSON(_ data: Data) throws -> DiffResult {
        let decoder = JSONDecoder()
        return try decoder.decode(DiffResult.self, from: data)
    }
    
    /// Decodes a diff result from a JSON string
    /// - Parameter jsonString: The JSON string to decode
    /// - Returns: The decoded diff result
    /// - Throws: An error if decoding fails
    public static func decodeDiffFromJSONString(_ jsonString: String) throws -> DiffResult {
        guard let data = jsonString.data(using: .utf8) else {
            throw DiffError.decodingFailed
        }
        return try decodeDiffFromJSON(data)
    }
    
    /// Saves a diff result to a file
    /// - Parameters:
    ///   - diff: The diff result to save
    ///   - fileURL: The URL of the file to write to
    ///   - prettyPrinted: Whether to format the JSON for human readability
    /// - Throws: An error if saving fails
    public static func saveDiffToFile(_ diff: DiffResult, fileURL: URL, prettyPrinted: Bool = false) throws {
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
    
    // MARK: - Todd's Diff Algorithm (More Granular)
    
    /// Creates a more granular diff between two strings using Todd's algorithm
    /// - Parameters:
    ///   - source: The original string
    ///   - destination: The modified string
    /// - Returns: A DiffResult containing detailed operations to transform source into destination
    public static func createDiffTodd(source: String, destination: String) -> DiffResult {
        // Handle empty string cases
        if source.isEmpty && destination.isEmpty {
            return DiffResult(operations: [])
        }
        
        if source.isEmpty {
            return DiffResult(operations: [.insert(destination)])
        }
        
        if destination.isEmpty {
            return DiffResult(operations: [.delete(source.count)])
        }
        
        // Split into lines
        let sourceLines = source.split(separator: "\n", omittingEmptySubsequences: false)
        let destLines = destination.split(separator: "\n", omittingEmptySubsequences: false)
        
        // Create a line-by-line nested diff
        let operations = createLineByLineDiffTodd(sourceLines: sourceLines, destLines: destLines)
            
        return DiffResult(operations: operations)
    }
    
    /// Create a nested diff by diffing each line separately
    private static func createLineByLineDiffTodd(sourceLines: [Substring], destLines: [Substring]) -> [DiffOperation] {
        var result: [DiffOperation] = []
        
        // First create operations that represent line-level changes
        let lineOperations = diffLines(sourceLines, destLines)
        
        for op in lineOperations {
            switch op {
            case .retain(let index):
                // Lines are the same, but still diff them character by character for finer granularity
                let sourceLine = sourceLines[index]
                
                // Add newline if not the last line
                let sourceLineWithNewline = index < sourceLines.count - 1 ? sourceLine + "\n" : sourceLine
                
                // For unchanged lines, just retain the entire line
                result.append(.retain(sourceLineWithNewline.count))
                
            case .delete(let index):
                // Line was deleted, add a delete operation
                let sourceLine = sourceLines[index]
                let sourceLineWithNewline = index < sourceLines.count - 1 ? sourceLine + "\n" : sourceLine
                result.append(.delete(sourceLineWithNewline.count))
                
            case .insert(let index):
                // Line was inserted, add an insert operation
                let destLine = destLines[index]
                let destLineWithNewline = index < destLines.count - 1 ? destLine + "\n" : destLine
                result.append(.insert(String(destLineWithNewline)))
            }
        }
        
        return result
    }
    
    /// Utility to calculate diff operations between two arrays of lines
    private static func diffLines<T: Equatable>(_ source: [T], _ dest: [T]) -> [LineOperation] {
        var operations: [LineOperation] = []
        
        // Use a bruss Longest Common Subsequence algorithm
        let lcs = longestCommonSubsequence(source, dest)
        
        var sourceIndex = 0
        var destIndex = 0
        var lcsIndex = 0
        
        while sourceIndex < source.count || destIndex < dest.count {
            // If we have a common element
            if lcsIndex < lcs.count && 
               sourceIndex < source.count && 
               destIndex < dest.count && 
               source[sourceIndex] == lcs[lcsIndex] && 
               dest[destIndex] == lcs[lcsIndex] {
                operations.append(.retain(sourceIndex))
                sourceIndex += 1
                destIndex += 1
                lcsIndex += 1
            }
            // If dest has an extra element
            else if destIndex < dest.count && (lcsIndex >= lcs.count || 
                    source.count <= sourceIndex || dest[destIndex] != lcs[lcsIndex]) {
                operations.append(.insert(destIndex))
                destIndex += 1
            }
            // If source has an element to be deleted
            else {
                operations.append(.delete(sourceIndex))
                sourceIndex += 1
            }
        }
        
        return operations
    }
    
    /// Calculate the longest common subsequence of two arrays
    private static func longestCommonSubsequence<T: Equatable>(_ a: [T], _ b: [T]) -> [T] {
        if a.isEmpty || b.isEmpty { return [] }
        
        // Create LCS table
        var table = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
        
        // Fill the table
        for i in 1...a.count {
            for j in 1...b.count {
                if a[i-1] == b[j-1] {
                    table[i][j] = table[i-1][j-1] + 1
                } else {
                    table[i][j] = max(table[i-1][j], table[i][j-1])
                }
            }
        }
        
        // Reconstruct the LCS
        var result: [T] = []
        var i = a.count
        var j = b.count
        
        while i > 0 && j > 0 {
            if a[i-1] == b[j-1] {
                result.insert(a[i-1], at: 0)
                i -= 1
                j -= 1
            } else if table[i-1][j] > table[i][j-1] {
                i -= 1
            } else {
                j -= 1
            }
        }
        
        return result
    }
    
    /// Represents an edit in line-level diffing
    private enum LineOperation {
        case retain(Int) // Line index in source
        case insert(Int) // Line index in destination
        case delete(Int) // Line index in source
    }
    
    /// Applies a diff created by Todd'ss' algorithm to a source string
    /// - Parameters:
    ///   - source: The original string
    ///   - diff: The diff to apply
    /// - Returns: The resulting string after applying the diff
    /// - Throws: An error if the diff cannot be applied correctly
    public static func applyDiffTodd(to source: String, diff: DiffResult) throws -> String {
        // The application process is the same as the regular applyDiff function
        return try applyDiff(to: source, diff: diff)
    }
    

 
}

/// Errors that can occur during diff operations
public enum DiffError: Error, CustomStringConvertible {
    case invalidRetain(count: Int, remainingLength: Int)
    case invalidDelete(count: Int, remainingLength: Int)
    case incompleteApplication(unconsumedLength: Int)
    case encodingFailed
    case decodingFailed
    
    public var description: String {
        switch self {
        case .invalidRetain(let count, let remaining):
            return "Cannot retain \(count) characters, only \(remaining) remaining"
        case .invalidDelete(let count, let remaining):
            return "Cannot delete \(count) characters, only \(remaining) remaining"
        case .incompleteApplication(let unconsumed):
            return "Diff application did not consume entire source string (\(unconsumed) characters remaining)"
        case .encodingFailed:
            return "Failed to encode diff to JSON"
        case .decodingFailed:
            return "Failed to decode diff from JSON"
        }
    }
}
