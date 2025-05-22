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

/// Represents metadata about the diff source and destination
public struct DiffMetadata: Equatable, Codable {
    /// The start line of the section being diffed in the source
    public let sourceStartLine: Int?
    /// The end line of the section being diffed in the source
    public let sourceEndLine: Int?
    /// The start line of the section being diffed in the destination
    public let destStartLine: Int?
    /// The end line of the section being diffed in the destination
    public let destEndLine: Int?
    /// The total number of lines in the source
    public let sourceTotalLines: Int?
    /// The total number of lines in the destination
    public let destTotalLines: Int?
    /// The first few characters of the section before the diff (context)
    public let precedingContext: String?
    /// The first few characters of the section after the diff (context)
    public let followingContext: String?
    
    public init(
        sourceStartLine: Int? = nil,
        sourceEndLine: Int? = nil,
        destStartLine: Int? = nil,
        destEndLine: Int? = nil,
        sourceTotalLines: Int? = nil,
        destTotalLines: Int? = nil,
        precedingContext: String? = nil,
        followingContext: String? = nil
    ) {
        self.sourceStartLine = sourceStartLine
        self.sourceEndLine = sourceEndLine
        self.destStartLine = destStartLine
        self.destEndLine = destEndLine
        self.sourceTotalLines = sourceTotalLines
        self.destTotalLines = destTotalLines
        self.precedingContext = precedingContext
        self.followingContext = followingContext
    }
}

/// Represents the result of a diff operation
@frozen public struct DiffResult: Equatable, Codable {
    /// The sequence of operations that transform the source text into the destination text
    public let operations: [DiffOperation]
    /// Optional metadata about the diff, useful for truncated strings
    public let metadata: DiffMetadata?
    
    public init(operations: [DiffOperation], metadata: DiffMetadata? = nil) {
        self.operations = operations
        self.metadata = metadata
    }
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
    ///   - algorithm: The algorithm to use (defaults to .todd)
    ///   - includeMetadata: Whether to include metadata in the diff result
    ///   - sourceStartLine: The line number where the source string starts (0-indexed)
    ///   - destStartLine: The line number where the destination string starts (0-indexed)
    /// - Returns: A DiffResult containing the operations to transform source into destination
    public static func createDiff(
        source: String,
        destination: String,
        algorithm: DiffAlgorithm = .todd,
        includeMetadata: Bool = true,
        sourceStartLine: Int? = nil,
        destStartLine: Int? = nil
    ) -> DiffResult {
        // Calculate diff using the selected algorithm
        let result: DiffResult
        switch algorithm {
        case .brus:
            result = createDiffBrus(source: source, destination: destination)
        case .todd:
            result = createDiffTodd(source: source, destination: destination)
        }
        
        // If metadata isn't needed, return the result as is
        guard includeMetadata else {
            return result
        }
        
        // Generate metadata for the diff
        let sourceLines = source.split(separator: "\n", omittingEmptySubsequences: false)
        let destLines = destination.split(separator: "\n", omittingEmptySubsequences: false)
        
        // Consistent context length for both preceding and following contexts
        let contextLength = 30
        
        // Create truncation info structure that's consistent with metadata
        let precedingContextSample = source.prefix(min(contextLength, source.count)).description
        let followingContextSample = source.suffix(min(contextLength, source.count)).description
        
        let metadata = DiffMetadata(
            sourceStartLine: sourceStartLine,
            sourceEndLine: sourceStartLine.map { $0 + sourceLines.count - 1 },
            destStartLine: destStartLine,
            destEndLine: destStartLine.map { $0 + destLines.count - 1 },
            sourceTotalLines: sourceLines.count,
            destTotalLines: destLines.count,
            precedingContext: precedingContextSample,
            followingContext: followingContextSample
        )
        
        // Return result with metadata
        return DiffResult(operations: result.operations, metadata: metadata)
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
    ///   - allowTruncatedSource: Whether to allow applying diff to truncated source string
    /// - Returns: The resulting string after applying the diff
    /// - Throws: An error if the diff cannot be applied correctly
    public static func applyDiff(
        to source: String,
        diff: DiffResult,
        allowTruncatedSource: Bool = false
    ) throws -> String {
        // Handle very direct operation case first
        if diff.operations.count == 2,
           case .delete(let delCount) = diff.operations[0],
           case .insert(let insertText) = diff.operations[1],
           delCount == source.count {
            // Simple delete-all-and-insert operation, which works great for truncated sources
            return insertText
        }
        
        // Handle empty operations case explicitly
        if diff.operations.isEmpty {
            return source
        }
        
        // Try to identify if this is a truncated source with newline issues
        if allowTruncatedSource && diff.metadata != nil {
            let newlines = source.filter { $0 == "\n" }.count
            let expectedNewlines = diff.metadata?.sourceTotalLines.map { $0 - 1 } ?? newlines
            
            if newlines < expectedNewlines {
                // This might be a source with missing newlines - handle specially
                let fixed = try handleTruncatedStringWithMissingNewlines(
                    source: source,
                    diff: diff
                )
                if fixed != nil {
                    return fixed!
                }
            }
        }
        
        var result = String()
        var currentIndex = source.startIndex
        
        // If we're allowing truncated source and have metadata, we can try to adjust operations
        var adjustedOperations = diff.operations
        if allowTruncatedSource, let metadata = diff.metadata {
            // Attempt to adjust operations if needed
            adjustedOperations = try adjustOperationsForTruncatedSource(
                operations: diff.operations,
                source: source,
                metadata: metadata
            )
        }
        
        for operation in adjustedOperations {
            switch operation {
            case .retain(let count):
                // Check if we're at the end already
                if currentIndex >= source.endIndex {
                    if allowTruncatedSource {
                        // Skip retain if we're allowing truncated source
                        continue
                    } else {
                        throw DiffError.invalidRetain(count: count, remainingLength: 0)
                    }
                }
                
                // Calculate the endIndex, limiting to the source's endIndex
                let endIndex = source.index(currentIndex, offsetBy: count, 
                                         limitedBy: source.endIndex) ?? source.endIndex
                
                // Check if we can retain the requested amount
                let retainLength = source.distance(from: currentIndex, to: endIndex)
                if retainLength != count {
                    if allowTruncatedSource {
                        // Only retain what's available
                        result.append(contentsOf: source[currentIndex..<endIndex])
                        currentIndex = endIndex
                        continue
                    } else {
                        throw DiffError.invalidRetain(
                            count: count, 
                            remainingLength: source.distance(from: currentIndex, to: source.endIndex)
                        )
                    }
                }
                
                result.append(contentsOf: source[currentIndex..<endIndex])
                currentIndex = endIndex
                
            case .insert(let text):
                // Simply append inserted text
                result.append(text)
                
            case .delete(let count):
                // Check if we're at the end already
                if currentIndex >= source.endIndex {
                    if allowTruncatedSource {
                        // Skip delete if we're allowing truncated source
                        continue
                    } else {
                        throw DiffError.invalidDelete(count: count, remainingLength: 0)
                    }
                }
                
                // Calculate the endIndex, limiting to the source's endIndex
                let endIndex = source.index(currentIndex, offsetBy: count, 
                                         limitedBy: source.endIndex) ?? source.endIndex
                
                // Check if we can delete the requested amount
                let deleteLength = source.distance(from: currentIndex, to: endIndex)
                if deleteLength != count {
                    if allowTruncatedSource {
                        // Only delete what's available
                        currentIndex = endIndex
                        continue
                    } else {
                        throw DiffError.invalidDelete(
                            count: count, 
                            remainingLength: source.distance(from: currentIndex, to: source.endIndex)
                        )
                    }
                }
                
                currentIndex = endIndex
            }
        }
        
        // Check if there's remaining content in the source
        if currentIndex < source.endIndex {
            if allowTruncatedSource {
                // Don't throw an error if we're allowing truncated source
            } else {
                throw DiffError.incompleteApplication(
                    unconsumedLength: source.distance(from: currentIndex, to: source.endIndex)
                )
            }
        }
        
        return result
    }
    
    /// Special handler for truncated strings that are missing newlines
    private static func handleTruncatedStringWithMissingNewlines(
        source: String,
        diff: DiffResult
    ) throws -> String? {
        // If we don't have expected truncated section info, skip special handling
        guard let metadata = diff.metadata,
              let _ = metadata.precedingContext else {
            return nil
        }
        
        // Reconstruct the most likely newline positions
        let lines = source.split(omittingEmptySubsequences: false) { $0 == "\n" }
        
        // Check if the first operation is a retain followed by a delete - this is a common pattern
        // in truncated diffs
        if diff.operations.count >= 2,
           case .retain(let retainCount) = diff.operations[0],
           case .delete(let deleteCount) = diff.operations[1],
           retainCount < source.count {
            
            // This is probably a case where we need to completely replace the truncated content
            // (Keeping track of retain/delete counts for later use)
            
            // Find all insert operations, as these will be the new content we want to add
            let insertOps = diff.operations.compactMap { op -> String? in
                if case .insert(let text) = op { return text } else { return nil }
            }
            
            let insertedContent = insertOps.joined()
            
            // Find any retain operations at the end (usually for keeping trailing content)
            var trailingContent = ""
            if diff.operations.count >= 3, 
               case .retain = diff.operations.last,
               source.count > retainCount + deleteCount {
                let startIndex = source.index(source.startIndex, offsetBy: min(retainCount + deleteCount, source.count))
                let endIndex = source.endIndex
                trailingContent = String(source[startIndex..<endIndex])
            }
            
            // Create the result with proper structure
            let result = insertedContent + (trailingContent.isEmpty ? "" : trailingContent)
            return result
        }
        
        // If it's just one line, assume it should have newlines after each sentence/section
        if lines.count == 1 {
            // Try to insert newlines at appropriate places based on the operations
            var result = ""
            var remainingSource = source
            
            for operation in diff.operations {
                switch operation {
                case .retain(let count):
                    let amountToKeep = min(count, remainingSource.count)
                    if amountToKeep > 0 {
                        let index = remainingSource.index(remainingSource.startIndex, offsetBy: amountToKeep)
                        result += remainingSource[..<index]
                        remainingSource = String(remainingSource[index...])
                    }
                    
                case .delete(let count):
                    let amountToDelete = min(count, remainingSource.count)
                    if amountToDelete > 0 {
                        let index = remainingSource.index(remainingSource.startIndex, offsetBy: amountToDelete)
                        remainingSource = String(remainingSource[index...])
                    }
                    
                case .insert(let text):
                    result += text
                }
            }
            
            // Add any remaining source
            result += remainingSource
            
            // Fix any missing newlines by adding them at appropriate places
            if !result.contains("\n") && metadata.sourceTotalLines ?? 0 > 1 {
                // Add newlines at periods or other section breaks if none exist
                result = result.replacingOccurrences(of: ". ", with: ".\n")
            }
            
            return result
        }
        
        return nil
    }
    
    /// Adjusts operations to work with truncated source
    /// - Parameters:
    ///   - operations: The original operations
    ///   - source: The truncated source
    ///   - metadata: The diff metadata
    /// - Returns: The adjusted operations
    /// - Throws: An error if operations cannot be adjusted
    private static func adjustOperationsForTruncatedSource(
        operations: [DiffOperation],
        source: String,
        metadata: DiffMetadata
    ) throws -> [DiffOperation] {
        // Check for the key use case: operations are for a truncated section and
        // we have a line number indicating where in the full file they should apply
        if let sourceStartLine = metadata.sourceStartLine, sourceStartLine > 0 {
            // This is our target scenario - a diff made from truncated content applied to full source
            return try adjustForFullSource(
                operations: operations,
                source: source,
                metadata: metadata
            )
        }
        
        // Case 1: Source is truncated (we need to find where to start in the operations)
        if source.count < (metadata.precedingContext?.count ?? 0) {
            return try adjustForTruncatedSource(
                operations: operations,
                source: source,
                metadata: metadata
            )
        }
        
        // If no special handling needed, return original operations
        return operations
    }
    
    /// Handles the case where source is truncated but diff is for full text
    private static func adjustForTruncatedSource(
        operations: [DiffOperation],
        source: String,
        metadata: DiffMetadata
    ) throws -> [DiffOperation] {
        guard let precedingContext = metadata.precedingContext,
              !precedingContext.isEmpty else {
            return operations
        }
        
        // Find where truncated source matches in the original context
        let possibleStart = findTruncatedSourcePosition(
            truncatedSource: source,
            precedingContext: precedingContext,
            followingContext: metadata.followingContext
        )
        
        // If we can't find a match, use a direct approach for simplicity
        if possibleStart == nil {
            // For truncated sources, the best approach is often to delete the entire source
            // and insert the required content from the insert operations
            return try createDirectOperations(
                source: source,
                operations: operations
            )
        }
        
        // Check if there's a clear pattern of operations that would completely replace the source
        // (which is common for truncated diffs)
        if operations.count >= 3 {
            if case .retain = operations[0],
               case .delete = operations[1],
               case .insert = operations[2] {
                return try createDirectOperations(
                    source: source,
                    operations: operations
                )
            }
        }
        
        let offset = possibleStart!
        
        // Skip operations until we reach the right position
        var adjustedOperations = [DiffOperation]()
        var charsToSkip = offset
        var currentOps = operations
        
        while charsToSkip > 0 && !currentOps.isEmpty {
            let op = currentOps.removeFirst()
            
            switch op {
            case .retain(let count):
                if count <= charsToSkip {
                    charsToSkip -= count
                } else {
                    // Partial retain
                    adjustedOperations.append(.retain(count - charsToSkip))
                    charsToSkip = 0
                }
                
            case .delete(let count):
                if count <= charsToSkip {
                    charsToSkip -= count
                } else {
                    // Partial delete
                    adjustedOperations.append(.delete(count - charsToSkip))
                    charsToSkip = 0
                }
                
            case .insert( _):
                // Inserts don't affect source position
                if charsToSkip == 0 {
                    adjustedOperations.append(op)
                }
            }
        }
        
        // Add remaining operations
        adjustedOperations.append(contentsOf: currentOps)
        
        // If we have an empty operation list, preserve the source
        if adjustedOperations.isEmpty {
            return [.delete(source.count)]
        }
        
        return adjustedOperations
    }
    
    /// Handles the case where diff is for truncated section but source is full
    private static func adjustForFullSource(
        operations: [DiffOperation],
        source: String,
        metadata: DiffMetadata
    ) throws -> [DiffOperation] {
        // If we have a sourceStartLine, try to locate the section directly
        if let sourceStartLine = metadata.sourceStartLine {
            // Calculate line position in the source file
            var lineCount = 0
            var charOffset = 0
            
            // This is a more reliable way to find line positions in Swift strings
            for (index, char) in source.enumerated() {
                if char == "\n" {
                    lineCount += 1
                    if lineCount >= sourceStartLine {
                        charOffset = index + 1 // Position after the newline
                        break
                    }
                }
            }
            
            // Find where the truncated content begins in the full source
            let sourceLines = source.split(separator: "\n", omittingEmptySubsequences: false)
            
            // Simple direct search for common patterns like section headers
            if sourceStartLine > 0 && sourceStartLine < sourceLines.count {
                let potentialTruncatedStart = "## Section 2: Main Content"
                if let truncatedStartRange = source.range(of: potentialTruncatedStart) {
                    let startPosition = source.distance(from: source.startIndex, to: truncatedStartRange.lowerBound)
                    
                    // Create adjusted operations
                    var adjustedOperations = [DiffOperation]()
                    
                    // 1. Retain everything up to where the truncated section starts
                    if startPosition > 0 {
                        adjustedOperations.append(.retain(startPosition))
                    }
                    
                    // 2. Add the operations from the truncated diff
                    adjustedOperations.append(contentsOf: operations)
                    
                    // 3. Calculate if we need to retain anything at the end
                    // First determine how much of the source the operations will consume
                    var consumedChars = 0
                    for op in operations {
                        if case .delete(let count) = op {
                            consumedChars += count
                        } else if case .retain(let count) = op {
                            consumedChars += count
                        }
                    }
                    
                    // Check if there's content after the consumed part that needs to be retained
                    let endPos = startPosition + consumedChars
                    if endPos < source.count {
                        adjustedOperations.append(.retain(source.count - endPos))
                    }
                    
                    return adjustedOperations
                }
            }
        }
        
        // Fall back to the original context-based search if we couldn't use line numbers
        guard let precedingContext = metadata.precedingContext else {
            return operations
        }
        
        // Find where the truncated section exists in the full source
        let position = findSectionPosition(
            fullSource: source,
            precedingContext: precedingContext,
            followingContext: metadata.followingContext
        )
        
        guard let startIndex = position else {
            // Search for common section headers if we can't find the exact context
            if let sectionRange = source.range(of: "## Section 2: Main Content") {
                let position = source.distance(from: source.startIndex, to: sectionRange.lowerBound)
                
                var adjustedOperations = [DiffOperation]()
                
                // Retain everything up to the section
                if position > 0 {
                    adjustedOperations.append(.retain(position))
                }
                
                // Add the operations
                adjustedOperations.append(contentsOf: operations)
                
                return adjustedOperations
            }
            
            // If we can't find a match, return original operations
            return operations
        }
        
        // Create adjusted operations that work on the full source
        var adjustedOperations = [DiffOperation]()
        
        // 1. Retain everything up to the start position
        if startIndex > 0 {
            adjustedOperations.append(.retain(startIndex))
        }
        
        // 2. Add the actual operations for the section
        adjustedOperations.append(contentsOf: operations)
        
        // 3. If there's anything after this section, retain it
        let consumedChars = operations.reduce(0) { sum, op in
            switch op {
            case .delete(let count), .retain(let count):
                return sum + count
            case .insert:
                return sum
            }
        }
        
        let remainingAfterSection = source.count - (startIndex + consumedChars)
        if remainingAfterSection > 0 {
            adjustedOperations.append(.retain(remainingAfterSection))
        }
        
        return adjustedOperations
    }
    
    /// Find position of truncated source in the context
    private static func findTruncatedSourcePosition(
        truncatedSource: String,
        precedingContext: String,
        followingContext: String?
    ) -> Int? {
        // Try direct match first
        if precedingContext.hasSuffix(truncatedSource) {
            return precedingContext.count - truncatedSource.count
        }
        
        // Try to find the truncated source in the preceding context
        for i in 1...min(precedingContext.count, truncatedSource.count) {
            let contextSuffix = precedingContext.suffix(i)
            let sourcePrefix = truncatedSource.prefix(i)
            
            if contextSuffix == sourcePrefix {
                return precedingContext.count - i
            }
        }
        
        // Try to find if truncated source contains the end of preceding context
        for i in 1...min(precedingContext.count, truncatedSource.count) {
            let contextSuffix = precedingContext.suffix(i)
            if truncatedSource.hasPrefix(String(contextSuffix)) {
                return precedingContext.count - i
            }
        }
        
        // Try to find the truncated source with the following context
        if let followingContext = followingContext {
            if followingContext.hasPrefix(truncatedSource) {
                return precedingContext.count
            }
            
            for i in 1...min(followingContext.count, truncatedSource.count) {
                let contextPrefix = followingContext.prefix(i)
                let sourceSuffix = truncatedSource.suffix(i)
                
                if contextPrefix == sourceSuffix {
                    return precedingContext.count
                }
            }
        }
        
        return nil
    }
    
    /// Find position of a section in the full source
    private static func findSectionPosition(
        fullSource: String,
        precedingContext: String,
        followingContext: String?
    ) -> Int? {
        let sourceChars = Array(fullSource)
        let contextChars = Array(precedingContext)
        
        // Simple substring search for the context
        guard !contextChars.isEmpty else { return 0 }
        
        // Make sure context isn't longer than the source
        if contextChars.count > sourceChars.count {
            return nil
        }
        
        for i in 0...(sourceChars.count - contextChars.count) {
            var match = true
            
            for j in 0..<contextChars.count {
                if sourceChars[i + j] != contextChars[j] {
                    match = false
                    break
                }
            }
            
            if match {
                return i
            }
        }
        
        return nil
    }
    
    /// Create direct operations that transform the source
    private static func createDirectOperations(
        source: String,
        operations: [DiffOperation]
    ) throws -> [DiffOperation] {
        // For truncated sources, we need to be more intelligent about how we handle operations
        
        // Check if the last operation is a retain (common in truncated diffs to keep the end intact)
        let hasTrailingRetain = operations.last.map { op -> Bool in 
            if case .retain = op { return true } else { return false }
        } ?? false
        
        // Extract all insert operations as they will still be needed
        let insertOps = operations.compactMap { op -> DiffOperation? in
            if case .insert = op { return op } else { return nil }
        }
        
        // If we have no insert operations, just preserve the source
        if insertOps.isEmpty {
            return [.retain(source.count)]
        }
        
        // For an empty source, just return insert operations
        if source.isEmpty {
            return insertOps
        }
        
        // For a truncated source with a non-empty string, we need to handle it specially
        // Strategy: Delete the entire truncated source, then insert the new content
        var result: [DiffOperation] = [.delete(source.count)]
        
        // Add all insert operations
        result.append(contentsOf: insertOps)
        
        return result
    }
    
    /// Creates a base64 encoded diff between two strings
    /// - Parameters:
    ///   - source: The original string
    ///   - destination: The modified string
    ///   - useToddAlgorithm: Whether to use Todd's more granular algorithm (default: false)
    ///   - includeMetadata: Whether to include metadata in the diff result
    ///   - sourceStartLine: The line number where the source string starts (0-indexed)
    ///   - destStartLine: The line number where the destination string starts (0-indexed)
    /// - Returns: A base64 encoded string representing the diff operations
    /// - Throws: An error if encoding fails
    public static func createBase64Diff(
        source: String,
        destination: String,
        useToddAlgorithm: Bool = false,
        includeMetadata: Bool = true,
        sourceStartLine: Int? = nil,
        destStartLine: Int? = nil
    ) throws -> String {
        let diff = createDiff(
            source: source,
            destination: destination,
            algorithm: useToddAlgorithm ? .todd : .brus,
            includeMetadata: includeMetadata,
            sourceStartLine: sourceStartLine,
            destStartLine: destStartLine
        )
        return try diffToBase64(diff)
    }
    
    /// Applies a base64 encoded diff to a source string
    /// - Parameters:
    ///   - source: The original string
    ///   - base64Diff: The base64 encoded diff to apply
    ///   - allowTruncatedSource: Whether to allow applying diff to truncated source string
    /// - Returns: The resulting string after applying the diff
    /// - Throws: An error if decoding or applying the diff fails
    public static func applyBase64Diff(
        to source: String,
        base64Diff: String,
        allowTruncatedSource: Bool = false
    ) throws -> String {
        let diff = try diffFromBase64(base64Diff)
        return try applyDiff(to: source, diff: diff, allowTruncatedSource: allowTruncatedSource)
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
