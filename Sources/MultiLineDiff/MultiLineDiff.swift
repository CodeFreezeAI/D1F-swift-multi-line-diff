// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import CommonCrypto

#if canImport(CryptoKit)
import CryptoKit
#endif

// MultiLineDiff - A library for creating and applying diffs to multi-line text
// Supports Unicode/UTF-8 strings and handles multi-line content properly

/// Represents a single diff operation with three core transformation types
/// 
/// DiffOperation is the fundamental building block for describing text transformations.
/// It supports three primary operations: retain, insert, and delete.
///
/// - `retain`: Keeps existing characters from the source text
/// - `insert`: Adds new content not present in the source
/// - `delete`: Removes characters from the source text
///
/// # Performance Characteristics
/// - Constant-time operation creation O(1)
/// - Memory-efficient value type
/// - Supports Unicode and multi-line text
///
/// # Example
/// ```swift
/// let diff: [DiffOperation] = [
///     .retain(5),        // Keep first 5 characters
///     .delete(3),        // Remove next 3 characters
///     .insert("Swift")   // Insert "Swift"
/// ]
/// ```

/// The main entry point for the MultiLineDiff library
@frozen public enum MultiLineDiff {
    /// Creates a diff between two strings using advanced diffing algorithms
    ///
    /// This method provides a flexible and powerful way to generate diff operations
    /// that transform one text into another. It supports two primary algorithms:
    /// Brus (fast, O(n)) and Todd (semantic, O(n log n)).
    ///
    /// # Algorithms
    /// - `.brus`: Optimized for simple, character-level changes
    ///   - Fastest performance
    ///   - Best for minimal text modifications
    ///   - O(n) time complexity
    ///
    /// - `.todd`: Semantic diff with deeper analysis
    ///   - More intelligent change detection
    ///   - Preserves structural context
    ///   - O(n log n) time complexity
    ///
    /// # Features
    /// - Unicode/UTF-8 support
    /// - Metadata generation with source verification
    /// - Flexible line number tracking
    /// - Automatic truncated source detection
    ///
    /// # Example
    /// ```swift
    /// let source = "Hello, world!"
    /// let destination = "Hello, Swift!"
    ///
    /// // Default Todd algorithm with source verification
    /// let diff = MultiLineDiff.createDiff(
    ///     source: source,
    ///     destination: destination
    /// )
    ///
    /// // Intelligently apply diff (auto-detects full vs truncated source)
    /// let result = try MultiLineDiff.applyDiffIntelligently(to: someSource, diff: diff)
    /// ```
    ///
    /// - Parameters:
    ///   - source: The original text to transform from
    ///   - destination: The target text to transform to
    ///   - algorithm: Diff generation strategy (defaults to semantic Todd algorithm)
    ///   - includeMetadata: Whether to generate additional context information
    ///   - sourceStartLine: Optional starting line number for precise tracking
    ///   - destStartLine: Optional destination starting line number
    ///
    /// - Returns: A `DiffResult` containing transformation operations with source verification metadata
    public static func createDiff(
        source: String,
        destination: String,
        algorithm: DiffAlgorithm = .todd,
        includeMetadata: Bool = true,
        sourceStartLine: Int? = nil,
        destStartLine: Int? = nil
    ) -> DiffResult {
        // Execute the requested algorithm directly - no override
        let (result, actualAlgorithmUsed) = executeEnhancedAlgorithm(
            algorithm: algorithm,
            source: source,
            destination: destination
        )
        
        // If metadata isn't needed, return the result as is
        guard includeMetadata else {
            return result
        }
        
        // Generate enhanced metadata for the diff (includes source content for verification)
        return generateEnhancedMetadata(
            result: result,
            source: source,
            destination: destination,
            actualAlgorithm: actualAlgorithmUsed,
            sourceStartLine: sourceStartLine,
            destStartLine: destStartLine
        )
    }
    
    /// Creates a diff with explicit source content storage for intelligent application
    ///
    /// This method is specifically designed for scenarios where you want to ensure
    /// the diff contains the original source for verification during application.
    ///
    /// # Example
    /// ```swift
    /// let truncatedSection = "Section content..."
    /// let modifiedSection = "Modified section content..."
    ///
    /// // Create diff with source stored for verification
    /// let diff = MultiLineDiff.createVerifiableDiff(
    ///     source: truncatedSection,
    ///     destination: modifiedSection
    /// )
    ///
    /// // Later, intelligently apply to either full document or truncated section
    /// let result = try MultiLineDiff.applyDiffIntelligently(to: fullDocument, diff: diff)
    /// ```
    ///
    /// - Parameters:
    ///   - source: The original text to transform from
    ///   - destination: The target text to transform to
    ///   - algorithm: Diff generation strategy (defaults to semantic Todd algorithm)
    ///   - sourceStartLine: Optional starting line number for precise tracking
    ///
    /// - Returns: A `DiffResult` with source content stored for automatic verification
    public static func createSmartDiff(
        source: String,
        destination: String,
        algorithm: DiffAlgorithm = .todd,
        sourceStartLine: Int? = nil
    ) -> DiffResult {
        return createDiff(
            source: source,
            destination: destination,
            algorithm: algorithm,
            includeMetadata: true,
            sourceStartLine: sourceStartLine
        )
    }

    /// Enhanced diff application using Swift 6.1 features
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
        // Handle empty operations case explicitly
        if diff.operations.isEmpty {
            return source
        }
        
        // Handle very direct operation case first
        if diff.operations.count == 2,
           case .delete(let delCount) = diff.operations[0],
           case .insert(let insertText) = diff.operations[1],
           delCount == source.count {
            // Simple delete-all-and-insert operation
            return insertText
        }
        
        // Use enhanced string processing for diff application
        return try applyDiffWithEnhancedProcessing(
            source: source,
            operations: diff.operations,
            metadata: diff.metadata,
            allowTruncatedSource: allowTruncatedSource
        )
    }
    
    /// Intelligent diff application that automatically determines handling based on metadata and source verification
    /// - Parameters:
    ///   - source: The original string (could be full or truncated)
    ///   - diff: The diff to apply
    /// - Returns: The resulting string after applying the diff
    /// - Throws: An error if the diff cannot be applied correctly
    public static func applySmartDiff(
        to source: String,
        diff: DiffResult
    ) throws -> String {
        // Auto-determine whether to allow truncated source based on metadata and string comparison
        let allowTruncated: Bool
        
        // First, check if we can verify with stored source content
        if let storedSource = diff.metadata?.sourceContent {
            allowTruncated = DiffMetadata.requiresTruncatedHandling(
                providedSource: source,
                storedSource: storedSource
            )
        } else if let applicationType = diff.metadata?.applicationType {
            // Fall back to explicit application type
            allowTruncated = (applicationType == .requiresTruncatedSource)
        } else {
            // Fall back to legacy heuristics if no explicit type or stored source
            allowTruncated = (diff.metadata?.sourceStartLine ?? 0) > 0 || 
                           diff.metadata?.precedingContext != nil
        }
        
        return try applyDiff(to: source, diff: diff, allowTruncatedSource: allowTruncated)
    }
    
    /// Enhanced diff application with Swift 6.1 optimizations
    @_optimize(speed)
    public static func applyDiffWithEnhancedProcessing(
        source: String,
        operations: [DiffOperation],
        metadata: DiffMetadata?,
        allowTruncatedSource: Bool
    ) throws -> String {
        // Check if this is a section diff that needs special handling using explicit metadata
        if allowTruncatedSource, 
           let metadata = metadata,
           metadata.applicationType == .requiresTruncatedSource {
            
            // Try to find and apply the diff to a specific section
            if let sectionResult = try applySectionDiff(
                fullSource: source,
                operations: operations,
                metadata: metadata
            ) {
                return sectionResult
            }
        }
        
        // Fall back to standard diff application
        var result = String()
        var currentIndex = source.startIndex
        
        // Enhanced operation processing
        for operation in operations {
            switch operation {
            case .retain(let count):
                try handleRetainOperation(
                    source: source,
                    currentIndex: &currentIndex,
                            count: count, 
                    result: &result,
                    allowTruncated: allowTruncatedSource
                        )
                
            case .insert(let text):
                // Simply append inserted text
                result.append(text)
                
            case .delete(let count):
                try handleDeleteOperation(
                    source: source,
                    currentIndex: &currentIndex,
                            count: count, 
                    allowTruncated: allowTruncatedSource
                )
            }
        }
        
        // Check for remaining content
        if currentIndex < source.endIndex && !allowTruncatedSource {
                throw DiffError.incompleteApplication(
                    unconsumedLength: source.distance(from: currentIndex, to: source.endIndex)
                )
        }
        
        return result
    }
    
    /// Apply a section diff to a full document by finding the appropriate section using both preceding and following context
    public static func applySectionDiff(
        fullSource: String,
        operations: [DiffOperation],
        metadata: DiffMetadata
    ) throws -> String? {
        guard let precedingContext = metadata.precedingContext,
              !precedingContext.isEmpty else {
            return nil
        }
        
        let fullLines = fullSource.efficientLines
        let followingContext = metadata.followingContext
        let sourceLineCount = metadata.sourceTotalLines ?? 3
        
        // Enhanced section matching using both preceding and following context
        var bestMatchIndex: Int?
        var bestMatchConfidence = 0.0
        
        // Search through the document looking for the best matching section
        for startIndex in 0..<fullLines.count {
            let endIndex = Swift.min(fullLines.count, startIndex + sourceLineCount)
            
            // Extract potential section
            let sectionLines = Array(fullLines[startIndex..<endIndex])
            let sectionText = sectionLines.joined(separator: "\n")
            
            // Calculate confidence score based on both contexts
            let confidence = calculateSectionMatchConfidence(
                sectionText: sectionText,
                precedingContext: precedingContext,
                followingContext: followingContext,
                fullLines: fullLines,
                sectionStartIndex: startIndex,
                sectionEndIndex: endIndex
            )
            
            // Update best match if this section has higher confidence
            if confidence > bestMatchConfidence {
                bestMatchConfidence = confidence
                bestMatchIndex = startIndex
            }
            
            // If we find a very high confidence match, use it immediately
            if confidence > 0.85 {
                break
            }
        }
        
        // Require minimum confidence to proceed
        guard let startIndex = bestMatchIndex, bestMatchConfidence > 0.3 else {
            return nil // Couldn't find a sufficiently confident match
        }
        
        let endIndex = Swift.min(fullLines.count, startIndex + sourceLineCount)
        
        // Extract the section to be modified
        let sectionLines = Array(fullLines[startIndex..<endIndex])
        let sectionText = sectionLines.joined(separator: "\n")
        
        // Apply the diff to the section
        let modifiedSection = try applyDiffWithEnhancedProcessing(
            source: sectionText,
            operations: operations,
            metadata: nil,
            allowTruncatedSource: true
        )
        
        // Reconstruct the full document with the modified section
        var resultLines = Array(fullLines)
        let modifiedLines = modifiedSection.split(separator: "\n", omittingEmptySubsequences: false)
        
        // Replace the original section lines with modified lines
        resultLines.replaceSubrange(startIndex..<endIndex, with: modifiedLines)
        
        return resultLines.map(String.init).joined(separator: "\n")
    }
    
    /// Calculate confidence score for section matching using both preceding and following context
    public static func calculateSectionMatchConfidence(
        sectionText: String,
        precedingContext: String,
        followingContext: String?,
        fullLines: [Substring],
        sectionStartIndex: Int,
        sectionEndIndex: Int
    ) -> Double {
        var confidence = 0.0
        
        // Check preceding context match
        let precedingScore = calculateContextMatchScore(
            context: precedingContext,
            target: sectionText,
            isPrefix: true
        )
        confidence += precedingScore * 0.6 // Weight preceding context more heavily
        
        // Check following context match if available
        if let followingContext = followingContext, !followingContext.isEmpty {
            let followingScore = calculateContextMatchScore(
                context: followingContext,
                target: sectionText,
                isPrefix: false
            )
            confidence += followingScore * 0.4 // Following context gets moderate weight
        }
        
        // Additional scoring based on position and surrounding content
        let positionScore = calculatePositionalContextScore(
            fullLines: fullLines,
            sectionStartIndex: sectionStartIndex,
            sectionEndIndex: sectionEndIndex,
            precedingContext: precedingContext,
            followingContext: followingContext
        )
        confidence += positionScore * 0.2
        
        return Swift.min(confidence, 1.0)
    }
    
    /// Calculate how well a context matches a target string
    public static func calculateContextMatchScore(
        context: String,
        target: String,
        isPrefix: Bool
    ) -> Double {
        let contextTrimmed = context.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetTrimmed = target.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Exact match gets highest score
        if targetTrimmed.contains(contextTrimmed) || contextTrimmed.contains(targetTrimmed) {
            return 1.0
        }
        
        // Check for partial matches at the beginning or end
        if isPrefix {
            if targetTrimmed.hasPrefix(contextTrimmed) || contextTrimmed.hasPrefix(targetTrimmed) {
                return 0.8
            }
        } else {
            if targetTrimmed.hasSuffix(contextTrimmed) || contextTrimmed.hasSuffix(targetTrimmed) {
                return 0.8
            }
        }
        
        // Calculate similarity based on common words/tokens
        let contextWords = Set(contextTrimmed.split(separator: " "))
        let targetWords = Set(targetTrimmed.split(separator: " "))
        
        guard !contextWords.isEmpty && !targetWords.isEmpty else { return 0.0 }
        
        let commonWords = contextWords.intersection(targetWords)
        let similarity = Double(commonWords.count) / Double(max(contextWords.count, targetWords.count))
        
        return similarity * 0.6 // Partial word matching gets moderate score
    }
    
    /// Calculate positional context score by examining surrounding lines
    public static func calculatePositionalContextScore(
        fullLines: [Substring],
        sectionStartIndex: Int,
        sectionEndIndex: Int,
        precedingContext: String,
        followingContext: String?
    ) -> Double {
        var score = 0.0
        
        // Check lines immediately before the section
        if sectionStartIndex > 0 {
            let linesBefore = Array(fullLines[max(0, sectionStartIndex - 2)..<sectionStartIndex])
            let contextBefore = linesBefore.joined(separator: "\n")
            
            if contextBefore.contains(precedingContext.trimmingCharacters(in: .whitespacesAndNewlines)) {
                score += 0.5
            }
        }
        
        // Check lines immediately after the section
        if let followingContext = followingContext, 
           !followingContext.isEmpty,
           sectionEndIndex < fullLines.count {
            let linesAfter = Array(fullLines[sectionEndIndex..<min(fullLines.count, sectionEndIndex + 2)])
            let contextAfter = linesAfter.joined(separator: "\n")
            
            if contextAfter.contains(followingContext.trimmingCharacters(in: .whitespacesAndNewlines)) {
                score += 0.5
            }
        }
        
        return score
    }
    
    /// Enhanced retain operation handling
    @_optimize(speed)
    public static func handleRetainOperation(
        source: String,
        currentIndex: inout String.Index,
        count: Int,
        result: inout String,
        allowTruncated: Bool
    ) throws {
        guard currentIndex < source.endIndex else {
            if allowTruncated {
                return // Skip retain if truncated source
                } else {
                throw DiffError.invalidRetain(count: count, remainingLength: 0)
            }
        }
        
        // Enhanced index calculation using Swift 6.1 features
        let endIndex = source.index(currentIndex, offsetBy: count, limitedBy: source.endIndex) ?? source.endIndex
        let actualRetainLength = source.distance(from: currentIndex, to: endIndex)
        
        if actualRetainLength != count && !allowTruncated {
            throw DiffError.invalidRetain(
                count: count,
                remainingLength: source.distance(from: currentIndex, to: source.endIndex)
            )
        }
        
        // Efficient substring append
        result.append(contentsOf: source[currentIndex..<endIndex])
        currentIndex = endIndex
    }
    
    /// Enhanced delete operation handling
    @_optimize(speed)
    public static func handleDeleteOperation(
        source: String,
        currentIndex: inout String.Index,
        count: Int,
        allowTruncated: Bool
    ) throws {
        guard currentIndex < source.endIndex else {
            if allowTruncated {
                return // Skip delete if truncated source
            } else {
                throw DiffError.invalidDelete(count: count, remainingLength: 0)
            }
        }
        
        // Enhanced index calculation
        let endIndex = source.index(currentIndex, offsetBy: count, limitedBy: source.endIndex) ?? source.endIndex
        let actualDeleteLength = source.distance(from: currentIndex, to: endIndex)
        
        if actualDeleteLength != count && !allowTruncated {
            throw DiffError.invalidDelete(
                count: count,
                remainingLength: source.distance(from: currentIndex, to: source.endIndex)
            )
        }
        
        currentIndex = endIndex
    }
    
    /// Creates a base64 encoded diff between two strings
    /// - Parameters:
    ///   - source: The original string
    ///   - destination: The modified string
    ///   - algorithm: The diff algorithm to use (default: Todd)
    ///   - includeMetadata: Whether to include metadata in the diff result
    ///   - sourceStartLine: The line number where the source string starts (0-indexed)
    ///   - destStartLine: The line number where the destination string starts (0-indexed)
    /// - Returns: A base64 encoded string representing the diff operations
    /// - Throws: An error if encoding fails
    public static func createBase64Diff(
        source: String,
        destination: String,
        algorithm: DiffAlgorithm = .todd,
        includeMetadata: Bool = true,
        sourceStartLine: Int? = nil,
        destStartLine: Int? = nil
    ) throws -> String {
        // Create diff with the explicitly requested algorithm
        let diff = createDiff(
            source: source,
            destination: destination,
            algorithm: algorithm,
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
    
    /// Intelligently applies a base64 encoded diff to a source string with automatic detection
    /// - Parameters:
    ///   - source: The original string (could be full or truncated)
    ///   - base64Diff: The base64 encoded diff to apply
    /// - Returns: The resulting string after applying the diff
    /// - Throws: An error if decoding or applying the diff fails
    public static func applyBase64SmartDiff(
        to source: String,
        base64Diff: String
    ) throws -> String {
        let diff = try diffFromBase64(base64Diff)
        return try applySmartDiff(to: source, diff: diff)
    }
    
    /// Creates a diff in the specified encoding
    /// - Parameters:
    ///   - source: The original text
    ///   - destination: The modified text
    ///   - algorithm: Diff generation strategy (defaults to semantic Todd algorithm)
    ///   - encoding: The desired encoding format for the diff
    ///   - includeMetadata: Whether to generate additional context information
    ///   - sourceStartLine: Optional starting line number for precise tracking
    ///   - destStartLine: Optional destination starting line number
    /// - Returns: The diff in the specified encoding
    /// - Throws: An error if encoding fails
    public static func createEncodedDiff(
        source: String,
        destination: String,
        algorithm: DiffAlgorithm = .todd,
        encoding: DiffEncoding = .base64,
        includeMetadata: Bool = true,
        sourceStartLine: Int? = nil,
        destStartLine: Int? = nil
    ) throws -> Any {
        // Create the base diff result
        let diff = createDiff(
            source: source,
            destination: destination,
            algorithm: algorithm,
            includeMetadata: includeMetadata,
            sourceStartLine: sourceStartLine,
            destStartLine: destStartLine
        )
        
        // Encode based on the specified format
        switch encoding {
        case .base64:
            return try diffToBase64(diff)
        case .jsonString:
            return try encodeDiffToJSONString(diff)
        case .jsonData:
            let jsonString = try encodeDiffToJSONString(diff)
            return jsonString.data(using: .utf8) ?? Data()
        }
    }

    /// Applies an encoded diff to a source string
    /// - Parameters:
    ///   - source: The original string
    ///   - encodedDiff: The encoded diff to apply
    ///   - encoding: The encoding type of the diff
    ///   - allowTruncatedSource: Whether to allow applying diff to truncated source string
    /// - Returns: The resulting string after applying the diff
    /// - Throws: An error if decoding or applying the diff fails
    public static func applyEncodedDiff(
        to source: String,
        encodedDiff: Any,
        encoding: DiffEncoding,
        allowTruncatedSource: Bool = false
    ) throws -> String {
        // Decode based on the specified format
        let diff: DiffResult
        switch encoding {
        case .base64:
            guard let base64String = encodedDiff as? String else {
                throw DiffError.decodingFailed
            }
            diff = try diffFromBase64(base64String)
        case .jsonString:
            guard let jsonString = encodedDiff as? String else {
                throw DiffError.decodingFailed
            }
            diff = try decodeDiffFromJSONString(jsonString)
        case .jsonData:
            guard let jsonData = encodedDiff as? Data,
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw DiffError.decodingFailed
            }
            diff = try decodeDiffFromJSONString(jsonString)
        }
        
        // Apply the decoded diff
        return try applyDiff(to: source, diff: diff, allowTruncatedSource: allowTruncatedSource)
    }
    
    /// Intelligently applies an encoded diff to a source string with automatic detection
    /// - Parameters:
    ///   - source: The original string (could be full or truncated)
    ///   - encodedDiff: The encoded diff to apply
    ///   - encoding: The encoding type of the diff
    /// - Returns: The resulting string after applying the diff
    /// - Throws: An error if decoding or applying the diff fails
    public static func applyEncodedSmartDiff(
        to source: String,
        encodedDiff: Any,
        encoding: DiffEncoding
    ) throws -> String {
        // Decode based on the specified format
        let diff: DiffResult
        switch encoding {
        case .base64:
            guard let base64String = encodedDiff as? String else {
                throw DiffError.decodingFailed
            }
            diff = try diffFromBase64(base64String)
        case .jsonString:
            guard let jsonString = encodedDiff as? String else {
                throw DiffError.decodingFailed
            }
            diff = try decodeDiffFromJSONString(jsonString)
        case .jsonData:
            guard let jsonData = encodedDiff as? Data,
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw DiffError.decodingFailed
            }
            diff = try decodeDiffFromJSONString(jsonString)
        }
        
        // Apply the decoded diff intelligently
        return try applySmartDiff(to: source, diff: diff)
    }
    
    // MARK: - public Implementation
    
    /// Handle empty string cases for both diff algorithms
    public static func handleEmptyStrings(source: String, destination: String) -> DiffResult? {
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
    
    // MARK: - Enhanced Algorithm Selection & Utility Methods
    
    /// Enhanced method to check if Brus algorithm is suitable using Swift 6.1 optimizations
    @_optimize(speed)
    public static func isBrusSuitable(source: String, destination: String) -> Bool {
        return DiffAlgorithmCore.AlgorithmSelector.selectOptimalAlgorithm(source: source, destination: destination) == .brus
    }
    
    /// Enhanced algorithm selection suggestion using Swift 6.1 features
    @_optimize(speed)
    public static func suggestDiffAlgorithm(source: String, destination: String) -> String {
        switch DiffAlgorithmCore.AlgorithmSelector.selectOptimalAlgorithm(source: source, destination: destination) {
        case .brus: return "Brus"
        case .todd: return "Todd"
        }
    }
    
    /// Verifies a diff by applying it and checking against stored destination content
    /// Returns true if the diff produces the expected result
    public static func verifyDiff(_ diff: DiffResult) -> Bool {
        guard let metadata = diff.metadata else {
            return false // Cannot verify without metadata
        }
        
        return DiffMetadata.verifyDiffChecksum(
            diff: diff,
            storedSource: metadata.sourceContent,
            storedDestination: metadata.destinationContent
        )
    }
    
    /// Creates an undo diff that reverses the original transformation
    /// Returns nil if the diff doesn't contain the necessary metadata for undo
    public static func createUndoDiff(from diff: DiffResult) -> DiffResult? {
        return DiffMetadata.createUndoDiff(from: diff)
    }
    
    /// Applies a diff and verifies the result matches the expected destination
    /// Throws an error if verification fails
    public static func applyDiffWithVerify(
        to source: String,
        diff: DiffResult,
        allowTruncatedSource: Bool = false
    ) throws -> String {
        let result = try applyDiff(to: source, diff: diff, allowTruncatedSource: allowTruncatedSource)
        
        // Smart verification: only verify if we're applying to the same type of source
        if let metadata = diff.metadata,
           let expectedDestination = metadata.destinationContent,
           let storedSource = metadata.sourceContent {
            
            // Only verify if we're applying to the same source that created the diff
            // or if we're applying to a truncated source that matches the stored source
            let shouldVerify = (source == storedSource) || 
                              (storedSource.contains(source) && storedSource != source)
            
            if shouldVerify && result != expectedDestination {
                throw DiffError.verificationFailed(
                    expected: expectedDestination,
                    actual: result
                )
            }
        }
        
        return result
    }
    
    /// Intelligently applies a diff with automatic verification
    /// Combines intelligent application with checksum verification
    public static func applySmartDiffWithVerify(
        to source: String,
        diff: DiffResult
    ) throws -> String {
        let result = try applySmartDiff(to: source, diff: diff)
        
        // Smart verification: only verify if we're applying to the same type of source
        if let metadata = diff.metadata,
           let expectedDestination = metadata.destinationContent,
           let storedSource = metadata.sourceContent {
            
            // Only verify if we're applying to the same source that created the diff
            // or if we're applying to a truncated source that matches the stored source
            let shouldVerify = (source == storedSource) || 
                              (storedSource.contains(source) && storedSource != source)
            
            if shouldVerify && result != expectedDestination {
                throw DiffError.verificationFailed(
                    expected: expectedDestination,
                    actual: result
                )
            }
        }
        
        return result
    }
}

/// Errors that can occur during diff operations
@frozen public enum DiffError: Error, CustomStringConvertible {
    case invalidRetain(count: Int, remainingLength: Int)
    case invalidDelete(count: Int, remainingLength: Int)
    case incompleteApplication(unconsumedLength: Int)
    case encodingFailed
    case decodingFailed
    case verificationFailed(expected: String, actual: String)
    
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
        case .verificationFailed(let expected, let actual):
            "Diff verification failed: expected \(expected.count) characters, got \(actual.count) characters"
        }
    }
}

