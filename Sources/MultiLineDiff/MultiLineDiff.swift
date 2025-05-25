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
    /// - `.zoom`: Optimized for simple, character-level changes
    ///   - Fastest performance
    ///   - Best for minimal text modifications
    ///   - O(n) time complexity
    ///
    /// - `.megatron`: Semantic diff with deeper analysis
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
            /// // Default Megatron algorithm with source verification
    /// let diff = MultiLineDiff.createDiff(
    ///     source: source,
    ///     destination: destination
    /// )
    ///
    /// // Apply diff (automatically detects full vs truncated source)
    /// let result = try MultiLineDiff.applyDiff(to: someSource, diff: diff)
    /// ```
    ///
    /// - Parameters:
    ///   - source: The original text to transform from
    ///   - destination: The target text to transform to
    ///   - algorithm: Diff generation strategy (defaults to semantic Megatron algorithm)
    ///   - includeMetadata: Whether to generate additional context information
    ///   - sourceStartLine: Optional starting line number for precise tracking
    ///   - destStartLine: Optional destination starting line number
    ///
    /// - Returns: A `DiffResult` containing transformation operations with source verification metadata
    public static func createDiff(
        source: String,
        destination: String,
        algorithm: DiffAlgorithm = .megatron,
        includeMetadata: Bool = true,
        sourceStartLine: Int? = nil,
        destStartLine: Int? = nil
    ) -> DiffResult {
        
        let result : DiffResult
        
        switch algorithm {
        case .megatron:
            result = createEnhancedToddDiff(source: source, destination: destination)
        case .zoom:
            result = createEnhancedBrusDiff(source: source, destination: destination)
        case .flash:
            result = createDiffUsingSwiftNativeMethods(source: source, destination: destination)
        case .starscream:
            result = createDiffUsingSwiftNativeLinesMethods(source: source, destination: destination)
        case .optimus:
            result = createDiffUsingSwiftNativeLinesWithDifferenceMethods(source: source, destination: destination)
        }

        // If metadata isn't needed, return the result as is
        guard includeMetadata else {
            return result
        }
        
        // Generate enhanced metadata for the diff (includes source content for verification)
        return generateEnhancedMetadata(
            result: result,
            source: source,
            destination: destination,
            actualAlgorithm: algorithm,
            sourceStartLine: sourceStartLine,
            destStartLine: destStartLine
        )
    }
    
    // MARK: - Base64 and Encoding Methods
    
    /// Creates a base64 encoded diff between two strings
    /// - Parameters:
    ///   - source: The original string
    ///   - destination: The modified string
    ///   - algorithm: The diff algorithm to use (default: Megatron)
    ///   - includeMetadata: Whether to include metadata in the diff result
    ///   - sourceStartLine: The line number where the source string starts (0-indexed)
    ///   - destStartLine: The line number where the destination string starts (0-indexed)
    /// - Returns: A base64 encoded string representing the diff operations
    /// - Throws: An error if encoding fails
    public static func createBase64Diff(
        source: String,
        destination: String,
        algorithm: DiffAlgorithm = .megatron,
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
        
    /// Enhanced diff application using Swift 6.1 features
    /// - Parameters:
    ///   - source: The original string
    ///   - diff: The diff to apply
    ///   - allowTruncatedSource: Whether to allow applying diff to truncated source string
    /// - Returns: The resulting string after applying the diff
    /// - Throws: An error if the diff cannot be applied correctly
    public static func applyDiff(
        to source: String,
        diff: DiffResult
    ) throws -> String {
        // Handle empty operations case explicitly
        if diff.operations.isEmpty {
            return source
        }
    
        let allowTruncated = shouldAllowTruncatedSource(for: source, diff: diff)

        // Use enhanced string processing for diff application
        let result = try applyDiffWithEnhancedProcessing(
            source: source,
            operations: diff.operations,
            metadata: diff.metadata,
            allowTruncatedSource: allowTruncated
        )
        
        try performSmartVerification(source: source, result: result, diff: diff)
        return result
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
        return try applyDiff(to: source, diff: diff)
    }
    
    /// Creates a diff in the specified encoding
    /// - Parameters:
    ///   - source: The original text
    ///   - destination: The modified text
    ///   - algorithm: Diff generation strategy (defaults to semantic Megatron algorithm)
    ///   - encoding: The desired encoding format for the diff
    ///   - includeMetadata: Whether to generate additional context information
    ///   - sourceStartLine: Optional starting line number for precise tracking
    ///   - destStartLine: Optional destination starting line number
    /// - Returns: The diff in the specified encoding
    /// - Throws: An error if encoding fails
    public static func createEncodedDiff(
        source: String,
        destination: String,
        algorithm: DiffAlgorithm = .megatron,
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
    
    /// Enhanced diff application with Swift 6.1 optimizations
    @_optimize(speed)
    private static func applyDiffWithEnhancedProcessing(
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
        
        // Apply operations to source string
        return try processOperationsOnSource(
            source: source,
            operations: operations,
            allowTruncatedSource: allowTruncatedSource
        )
    }
    
    /// Apply a section diff to a full document by finding the appropriate section using both preceding and following context
    private static func applySectionDiff(
        fullSource: String,
        operations: [DiffOperation],
        metadata: DiffMetadata
    ) throws -> String? {
        guard let precedingContext = metadata.precedingContext,
              !precedingContext.isEmpty else {
            return nil
        }
        
        let fullLines = fullSource.efficientLines
        let sourceLineCount = metadata.sourceTotalLines ?? 3
        
        // Find the best matching section
        guard let sectionRange = findBestMatchingSection(
            fullLines: fullLines,
            metadata: metadata,
            sourceLineCount: sourceLineCount
        ) else {
            return nil
        }
        
        // Apply diff to the matched section and reconstruct document
        return try reconstructDocumentWithModifiedSection(
            fullLines: fullLines,
            sectionRange: sectionRange,
            operations: operations
        )
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
        let diff = try decodeEncodedDiff(encodedDiff: encodedDiff, encoding: encoding)
        return try applyDiff(to: source, diff: diff)
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
        let diff = try decodeEncodedDiff(encodedDiff: encodedDiff, encoding: encoding)
        return try applyDiff(to: source, diff: diff)
    }
}
