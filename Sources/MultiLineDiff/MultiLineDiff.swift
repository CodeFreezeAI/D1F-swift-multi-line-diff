// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

// MultiLineDiff - A library for creating and applying diffs to multi-line text
// Supports Unicode/UTF-8 strings and handles multi-line content properly

/// Represents a single diff operation
@frozen public enum DiffOperation: Sendable, Equatable, Codable {
    case retain(Int)      // Keep a number of characters from the source
    case insert(String)   // Insert new content
    case delete(Int)      // Delete a number of characters from the source
    
    @_optimize(speed)
    public var description: String {
        switch self {
        case .retain(let count): "retain \(count) character\(count.isPlural ? "s" : "")"
        case .insert(let text): "insert \"\(text.truncated(to: 20))\""
        case .delete(let count): "delete \(count) character\(count.isPlural ? "s" : "")"
        }
    }
    
    /// Custom Codable implementation to preserve operation type
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        switch (
            container.contains(.retain),
            container.contains(.insert),
            container.contains(.delete)
        ) {
        case (true, false, false):
            let retainValue = try container.decode(Int.self, forKey: .retain)
            self = .retain(retainValue)
        
        case (false, true, false):
            let insertValue = try container.decode(String.self, forKey: .insert)
            self = .insert(insertValue)
        
        case (false, false, true):
            let deleteValue = try container.decode(Int.self, forKey: .delete)
            self = .delete(deleteValue)
        
        default:
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath, 
                    debugDescription: "Cannot decode DiffOperation: Invalid or multiple keys"
                )
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .retain(let count):
            try container.encode(count, forKey: .retain)
        case .insert(let text):
            try container.encode(text, forKey: .insert)
        case .delete(let count):
            try container.encode(count, forKey: .delete)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case retain, insert, delete
    }
}

private extension Int {
    var isPlural: Bool { self != 1 }
}

private extension String {
    func truncated(to length: Int) -> String {
        count > length ? prefix(length) + "..." : self
    }
}

/// Represents the result of a diff operation
@frozen public struct DiffResult: Equatable, Codable {
    /// The sequence of operations that transform the source text into the destination text
    public let operations: [DiffOperation]
}

/// Represents the available diff algorithms
@frozen public enum DiffAlgorithm {
    /// Simple, fast diff algorithm with O(n) time complexity
    case brus
    /// Detailed, semantic diff algorithm with O(n log n) time complexity
    case todd
}

/// The main entry point for the MultiLineDiff library
@frozen public enum MultiLineDiff {
    /// Creates a diff between two strings using the specified algorithm
    /// - Parameters:
    ///   - source: The original string
    ///   - destination: The modified string
    ///   - algorithm: The algorithm to use (defaults to .brus)
    /// - Returns: A DiffResult containing the operations to transform source into destination
    public static func createDiff(
        source: String,
        destination: String,
        algorithm: DiffAlgorithm = .todd
    ) -> DiffResult {
        switch algorithm {
        case .brus:
            return createDiffBrus(source: source, destination: destination)
        case .todd:
            return createDiffTodd(source: source, destination: destination)
        }
    }
    
    /// Creates a diff between two strings
    /// - Parameters:
    ///   - source: The original string
    ///   - destination: The modified string
    /// - Returns: A DiffResult containing the operations to transform source into destination
    private static func createDiffBrus(source: String, destination: String) -> DiffResult {
        // Handle empty string scenarios first
        if let emptyResult = handleEmptyStrings(source: source, destination: destination) {
            return emptyResult
        }
        
        let regions = CommonRegions(source: source, destination: destination)
        var operations = [DiffOperation]()
        operations.reserveCapacity(3) // Most common case: prefix, middle, suffix
        
        // Construct operations based on region characteristics
        switch (regions.prefixLength, regions.sourceMiddleLength, regions.destMiddleStart, regions.destMiddleEnd, regions.suffixLength) {
        case let (prefixLen, middleLen, destStart, destEnd, suffixLen) 
            where prefixLen > 0 || middleLen > 0 || (destStart < destEnd) || suffixLen > 0:
            
            // Add prefix retain operation if applicable
            if prefixLen > 0 {
                operations.append(.retain(prefixLen))
            }
            
            // Add delete operation for source middle if applicable
            if middleLen > 0 {
                operations.append(.delete(middleLen))
            }
            
            // Add insert operation for destination middle if applicable
            if destStart < destEnd {
                let destChars = Array(destination)
                let destMiddleString = String(destChars[destStart..<destEnd])
                operations.append(.insert(destMiddleString))
            }
            
            // Add suffix retain operation if applicable
            if suffixLen > 0 {
                operations.append(.retain(suffixLen))
            }
            
        default:
            // This case should never be reached due to previous empty string handling
            // but included for exhaustiveness
            return .init(operations: [])
        }
        
        return DiffResult(operations: operations)
    }
    
    /// Creates a more granular diff between two strings using Todd's algorithm
    /// - Parameters:
    ///   - source: The original string
    ///   - destination: The modified string
    /// - Returns: A DiffResult containing detailed operations to transform source into destination
    private static func createDiffTodd(source: String, destination: String) -> DiffResult {
        // Early handling of empty or simple cases using pattern matching
        switch (source.isEmpty, destination.isEmpty) {
        case (true, true):
            return .init(operations: [])
        case (true, false):
            return .init(operations: [.insert(destination)])
        case (false, true):
            return .init(operations: [.delete(source.count)])
        case (false, false):
            break  // Continue with diff calculation
        }
        
        // Determine the most appropriate diff strategy
        let strategy = determineDiffStrategy(source: source, destination: destination)
        
        // Select algorithm based on strategy
        switch strategy {
        case .brus:
            return createDiffBrus(source: source, destination: destination)
        case .todd:
            break  // Continue with Todd algorithm
        }
        
        // For very simple cases, use Brus algorithm
        if source.count <= 1 || destination.count <= 1 {
            return createDiffBrus(source: source, destination: destination)
        }
        
        // For pure whitespace changes, use Brus algorithm
        if source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
           destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return createDiffBrus(source: source, destination: destination)
        }
        
        let sourceLines = source.split(separator: "\n", omittingEmptySubsequences: false)
        let destLines = destination.split(separator: "\n", omittingEmptySubsequences: false)
        
        let comparison = SequenceComparisonResult(source: sourceLines, destination: destLines)
        
        // Track the last operation type to combine consecutive operations
        var result = [DiffOperation]()
        var lastOpType: DiffOperationType? = nil
        var currentRetainCount = 0
        var currentDeleteCount = 0
        var currentInsertText = ""
        
        // Helper to flush accumulated operations
        func flushOperations() {
            if currentRetainCount > 0 {
                result.append(.retain(currentRetainCount))
                currentRetainCount = 0
            }
            if currentDeleteCount > 0 {
                result.append(.delete(currentDeleteCount))
                currentDeleteCount = 0
            }
            if !currentInsertText.isEmpty {
                result.append(.insert(currentInsertText))
                currentInsertText = ""
            }
        }
        
        // Process operations sequentially
        for op in comparison.operations {
            switch op {
            case .retain(let index):
                let line = sourceLines[index]
                let isLastLine = index == sourceLines.count - 1
                
                if lastOpType != .retain {
                    flushOperations()
                }
                
                currentRetainCount += line.count
                if !isLastLine {
                    currentRetainCount += 1 // Add newline
                }
                lastOpType = .retain
                
            case .delete(let index):
                let line = sourceLines[index]
                let isLastLine = index == sourceLines.count - 1
                
                if lastOpType != .delete {
                    flushOperations()
                }
                
                currentDeleteCount += line.count
                if !isLastLine {
                    currentDeleteCount += 1 // Add newline
                }
                lastOpType = .delete
                
            case .insert(let index):
                let line = destLines[index]
                let isLastLine = index == destLines.count - 1
                
                if lastOpType != .insert {
                    flushOperations()
                }
                
                currentInsertText += String(line)
                if !isLastLine {
                    currentInsertText += "\n"
                }
                lastOpType = .insert
            }
        }
        
        // Final flush of operations
        flushOperations()
        
        // Handle trailing newlines
        switch (source.hasSuffix("\n"), destination.hasSuffix("\n")) {
        case (false, true):
            result.append(.insert("\n"))
        case (true, false):
            result.append(.delete(1))
        default:
            break
        }
        
        return DiffResult(operations: result)
    }
    
    /// Applies a diff to a source string
    /// - Parameters:
    ///   - source: The original string
    ///   - diff: The diff to apply
    /// - Returns: The resulting string after applying the diff
    /// - Throws: An error if the diff cannot be applied correctly
    public static func applyDiff(to source: String, diff: DiffResult) throws -> String {
        var result = String()
        var currentIndex = source.startIndex
        
        for operation in diff.operations {
            switch operation {
            case .retain(let count):
                // Validate and apply retain operation
                guard currentIndex < source.endIndex else {
                    throw DiffError.invalidRetain(count: count, remainingLength: 0)
                }
                
                let endIndex = source.index(currentIndex, offsetBy: count, 
                                         limitedBy: source.endIndex) ?? source.endIndex
                
                // Validate retain count
                let retainLength = source.distance(from: currentIndex, to: endIndex)
                guard retainLength == count else {
                    throw DiffError.invalidRetain(
                        count: count, 
                        remainingLength: source.distance(from: currentIndex, to: source.endIndex)
                    )
                }
                
                result.append(contentsOf: source[currentIndex..<endIndex])
                currentIndex = endIndex
                
            case .insert(let text):
                // Simply append inserted text
                result.append(text)
                
            case .delete(let count):
                // Validate and skip deletion
                guard currentIndex < source.endIndex else {
                    throw DiffError.invalidDelete(count: count, remainingLength: 0)
                }
                
                let endIndex = source.index(currentIndex, offsetBy: count, 
                                         limitedBy: source.endIndex) ?? source.endIndex
                
                // Validate delete count
                let deleteLength = source.distance(from: currentIndex, to: endIndex)
                guard deleteLength == count else {
                    throw DiffError.invalidDelete(
                        count: count, 
                        remainingLength: source.distance(from: currentIndex, to: source.endIndex)
                    )
                }
                
                currentIndex = endIndex
            }
        }
        
        // Ensure entire source is consumed
        guard currentIndex == source.endIndex else {
            throw DiffError.incompleteApplication(
                unconsumedLength: source.distance(from: currentIndex, to: source.endIndex)
            )
        }
        
        return result
    }
    
    /// Creates a base64 encoded diff between two strings
    /// - Parameters:
    ///   - source: The original string
    ///   - destination: The modified string
    ///   - useToddAlgorithm: Whether to use Todd's more granular algorithm (default: false)
    /// - Returns: A base64 encoded string representing the diff operations
    /// - Throws: An error if encoding fails
    public static func createBase64Diff(source: String, destination: String, useToddAlgorithm: Bool = false) throws -> String {
        let diff = createDiff(
            source: source,
            destination: destination,
            algorithm: useToddAlgorithm ? .todd : .brus
        )
        return try diffToBase64(diff)
    }
    
    /// Applies a base64 encoded diff to a source string
    /// - Parameters:
    ///   - source: The original string
    ///   - base64Diff: The base64 encoded diff to apply
    ///   - useToddAlgorithm: Whether this is a Todd algorithm diff (default: false)
    /// - Returns: The resulting string after applying the diff
    /// - Throws: An error if decoding or applying the diff fails
    public static func applyBase64Diff(to source: String, base64Diff: String, useToddAlgorithm: Bool = false) throws -> String {
        let diff = try diffFromBase64(base64Diff)
        return try applyDiff(to: source, diff: diff)
    }
    
    // MARK: - Private Implementation
    
    /// Handle empty string cases for both diff algorithms
    private static func handleEmptyStrings(source: String, destination: String) -> DiffResult? {
        switch (source.isEmpty, destination.isEmpty) {
        case (true, true): 
            return .init(operations: [])
        case (true, false): 
            return .init(operations: [.insert(destination)])
        case (false, true): 
            return .init(operations: [.delete(source.count)])
        case (false, false): 
            return nil
        }
    }
    
    /// Efficient string buffer for line handling
    private final class StringBuffer {
        private var buffer: String
        
        init(capacity: Int = 256) {
            buffer = String()
            buffer.reserveCapacity(capacity)
        }
        
        func append(_ line: Substring, isLastLine: Bool) {
            buffer.append(contentsOf: line)
            guard !isLastLine else { return }
            buffer.append("\n")
        }
        
        var result: String { buffer }
    }
    
    /// Represents common regions between two strings
    private struct CommonRegions {
        let prefixLength, suffixLength: Int
        let sourceMiddleStart, sourceMiddleEnd, sourceMiddleLength: Int
        let destMiddleStart, destMiddleEnd: Int
        
        init(source: String, destination: String) {
            let (sourceChars, destChars) = source.withContiguousStorageIfAvailable { sourceBuffer in
                destination.withContiguousStorageIfAvailable { destBuffer in
                    (Array(sourceBuffer), Array(destBuffer))
                } ?? (Array(destination), Array(source))
            } ?? (Array(source), Array(destination))
            
            let minLength = min(source.count, destination.count)
            
            // Find common prefix and suffix
            var prefix = 0
            while prefix < minLength, sourceChars[prefix] == destChars[prefix] {
                prefix += 1
            }
            prefixLength = prefix
            
            var suffix = 0
            while suffix < minLength - prefix,
                  sourceChars[source.count - suffix - 1] == destChars[destination.count - suffix - 1] {
                suffix += 1
            }
            suffixLength = suffix
            
            sourceMiddleStart = prefix
            sourceMiddleEnd = source.count - suffix
            sourceMiddleLength = sourceMiddleEnd - sourceMiddleStart
            destMiddleStart = prefix
            destMiddleEnd = destination.count - suffix
        }
    }
    
    /// Helper to create a line-level diff operation
    private static func createLineDiff(line: Substring, index: Int, totalLines: Int, isSource: Bool) -> DiffResult {
        let buffer = StringBuffer(capacity: line.count + 1)
        buffer.append(line, isLastLine: index == totalLines - 1)
        let content = buffer.result
        
        if isSource {
            // For source lines, we need to handle the newline separately
            if content.hasSuffix("\n") {
                return DiffResult(operations: [
                    .delete(content.count - 1),  // Delete content without newline
                    .delete(1)                   // Delete newline separately
                ])
            }
            return DiffResult(operations: [.delete(content.count)])
        } else {
            // For destination lines, we need to handle the newline separately
            if content.hasSuffix("\n") {
                return DiffResult(operations: [
                    .insert(String(content.dropLast())),  // Insert content without newline
                    .insert("\n")                         // Insert newline separately
                ])
            }
            return DiffResult(operations: [.insert(content)])
        }
    }
    
    /// Result of comparing two sequences
    private struct SequenceComparisonResult<T: Equatable> {
        let operations: [LineOperation]
        
        init(source: [T], destination: [T]) {
            // Handle empty cases first
            if source.isEmpty && destination.isEmpty {
                self.operations = []
                return
            }
            if source.isEmpty {
                self.operations = destination.indices.map { LineOperation.insert($0) }
                return
            }
            if destination.isEmpty {
                self.operations = source.indices.map { LineOperation.delete($0) }
                return
            }
            
            // Calculate LCS table
            var table = Array(repeating: Array(repeating: 0, count: destination.count + 1), 
                            count: source.count + 1)
            
            // Fill the LCS table
            for i in 1...source.count {
                for j in 1...destination.count {
                    if source[i-1] == destination[j-1] {
                        table[i][j] = table[i-1][j-1] + 1
                    } else {
                        table[i][j] = max(table[i-1][j], table[i][j-1])
                    }
                }
            }
            
            // Generate operations by backtracking through the table
            var operations = [LineOperation]()
            var i = source.count
            var j = destination.count
            
            while i > 0 || j > 0 {
                if i > 0 && j > 0 && source[i-1] == destination[j-1] {
                    operations.append(.retain(i-1))
                    i -= 1
                    j -= 1
                } else if j > 0 && (i == 0 || table[i][j-1] >= table[i-1][j]) {
                    operations.append(.insert(j-1))
                    j -= 1
                } else if i > 0 && (j == 0 || table[i][j-1] < table[i-1][j]) {
                    operations.append(.delete(i-1))
                    i -= 1
                }
            }
            
            self.operations = operations.reversed()
        }
    }
    
    /// Represents an edit in line-level diffing
    private enum LineOperation {
        case retain(Int)
        case insert(Int)
        case delete(Int)
    }
    
    private enum DiffOperationType {
        case retain, delete, insert
    }
    
    /// Represents the strategy for diff calculation
    private enum DiffStrategy {
        case brus   // Use simple, fast diff algorithm
        case todd   // Use detailed, semantic diff algorithm
    }
    
    /// Determines the most appropriate diff strategy
    private static func determineDiffStrategy(source: String, destination: String) -> DiffStrategy {
        switch (source.count, destination.count, 
                source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
        // Extremely short strings
        case (0...2, 0...2, _, _):
            return .brus
        
        // Pure whitespace changes
        case (_, _, true, true):
            return .brus
        
        // Nearly identical strings with minimal differences
        case (let sourceCount, let destCount, _, _) 
            where sourceCount == destCount && 
                  source.prefix(sourceCount - 1) == destination.prefix(destCount - 1):
            return .brus
        
        // Minimal line count differences
        case (_, _, _, _) 
            where abs(source.split(separator: "\n").count - 
                      destination.split(separator: "\n").count) <= 2:
            return .brus
        
        // Complex transformations default to Todd algorithm
        default:
            return .todd
        }
    }
    
    /// Optimized method to check if Brus algorithm is suitable
    public static func isBrusSuitable(source: String, destination: String) -> Bool {
        return determineDiffStrategy(source: source, destination: destination) == .brus
    }
    
    /// Optional method to suggest algorithm selection
    public static func suggestDiffAlgorithm(source: String, destination: String) -> String {
        switch determineDiffStrategy(source: source, destination: destination) {
        case .brus: return "Brus"
        case .todd: return "Todd"
        }
    }
}

/// Errors that can occur during diff operations
@frozen public enum DiffError: Error, CustomStringConvertible {
    case invalidRetain(count: Int, remainingLength: Int)
    case invalidDelete(count: Int, remainingLength: Int)
    case incompleteApplication(unconsumedLength: Int)
    case encodingFailed
    case decodingFailed
    
    public var description: String {
        switch self {
        case .invalidRetain(let count, let remaining):
            "Cannot retain \(count) characters, only \(remaining) remaining"
        case .invalidDelete(let count, let remaining):
            "Cannot delete \(count) characters, only \(remaining) remaining"
        case .incompleteApplication(let unconsumed):
            "Diff application did not consume entire source string (\(unconsumed) characters remaining)"
        case .encodingFailed:
            "Failed to encode diff to JSON"
        case .decodingFailed:
            "Failed to decode diff from JSON"
        }
    }
}
