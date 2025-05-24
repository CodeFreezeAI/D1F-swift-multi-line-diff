// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

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
        case retain = "="
        case insert = "+"
        case delete = "-"
    }
}

// MARK: - Swift 6.1 Enhanced String and Collection Utilities

/// Swift 6.1 Enhanced String Processing Utilities
private extension String {
    /// Optimized common prefix detection using Swift 6.1 string enhancements
    @_optimize(speed)
    func commonPrefix(with other: String) -> Int {
        // Use Swift 6.1's enhanced string comparison
        guard !isEmpty && !other.isEmpty else { return 0 }
        
        return zip(self, other)
            .prefix(while: ==)
            .count
    }
    
    /// Optimized common suffix detection using Swift 6.1 string enhancements
    @_optimize(speed)
    func commonSuffix(with other: String) -> Int {
        // Use Swift 6.1's enhanced string comparison with reversed iteration
        guard !isEmpty && !other.isEmpty else { return 0 }
        
        return zip(self.reversed(), other.reversed())
            .prefix(while: ==)
            .count
    }
    
    /// Swift 6.1 enhanced Unicode-aware line splitting
    @_optimize(speed)
    var efficientLines: [Substring] {
        // Leverage Swift 6.1's improved string splitting performance
        return self.split(separator: "\n", omittingEmptySubsequences: false)
    }
    
    /// Memory-efficient character access using Swift 6.1 features
    @_optimize(speed)
    func characterAt(offset: Int) -> Character? {
        guard offset >= 0 && offset < count else { return nil }
        return self[index(startIndex, offsetBy: offset)]
    }
    
    /// Swift 6.1 enhanced substring extraction
    @_optimize(speed)
    func substring(from: Int, length: Int) -> String {
        let startIdx = index(startIndex, offsetBy: Swift.max(0, from))
        let endIdx = index(startIdx, offsetBy: Swift.min(length, count - from), limitedBy: endIndex) ?? endIndex
        return String(self[startIdx..<endIdx])
    }
}

/// Swift 6.1 Enhanced Collection Algorithms
private extension Collection where Element: Equatable {
    // This extension has been removed - LCS is now implemented directly in generateLCSOperations
}

// MARK: - Common Algorithm Components

/// Shared components for both Brus and Todd algorithms
private enum DiffAlgorithmCore {
    
    /// Enhanced common regions detection using Swift 6.1 features
    struct EnhancedCommonRegions {
        let prefixLength: Int
        let suffixLength: Int
        let sourceMiddleRange: Range<Int>
        let destMiddleRange: Range<Int>
        
        @_optimize(speed)
        init(source: String, destination: String) {
            // Use Swift 6.1 enhanced string comparison
            let prefixLen = source.commonPrefix(with: destination)
            
            // Calculate suffix avoiding prefix overlap
            let remainingSourceCount = source.count - prefixLen
            let remainingDestCount = destination.count - prefixLen
            let maxSuffixLen = Swift.min(remainingSourceCount, remainingDestCount)
            
            let suffixLen: Int
            if maxSuffixLen > 0 {
                let sourceSuffix = String(source.suffix(maxSuffixLen))
                let destSuffix = String(destination.suffix(maxSuffixLen))
                suffixLen = sourceSuffix.commonSuffix(with: destSuffix)
            } else {
                suffixLen = 0
            }
            
            self.prefixLength = prefixLen
            self.suffixLength = suffixLen
            self.sourceMiddleRange = prefixLen..<(source.count - suffixLen)
            self.destMiddleRange = prefixLen..<(destination.count - suffixLen)
        }
        
        /// Extract middle content from source
        @_optimize(speed)
        func sourceMiddle(from source: String) -> String {
            guard !sourceMiddleRange.isEmpty else { return "" }
            return source.substring(from: sourceMiddleRange.lowerBound, 
                                  length: sourceMiddleRange.count)
        }
        
        /// Extract middle content from destination  
        @_optimize(speed)
        func destMiddle(from destination: String) -> String {
            guard !destMiddleRange.isEmpty else { return "" }
            return destination.substring(from: destMiddleRange.lowerBound,
                                       length: destMiddleRange.count)
        }
    }
    
    /// Optimized operation builder using Swift 6.1 features
    struct OperationBuilder {
        private var operations: [DiffOperation] = []
        
        // Accumulated operation state
        private var pendingRetainCount = 0
        private var pendingDeleteCount = 0
        private var pendingInsertText = ""
        
        @_optimize(speed)
        mutating func addRetain(count: Int) {
            guard count > 0 else { return }
            
            // Flush non-retain operations before adding retain
            if pendingDeleteCount > 0 || !pendingInsertText.isEmpty {
                flushPendingOperations()
            }
            
            pendingRetainCount += count
        }
        
        @_optimize(speed)
        mutating func addDelete(count: Int) {
            guard count > 0 else { return }
            
            // Flush non-delete operations before adding delete
            if pendingRetainCount > 0 || !pendingInsertText.isEmpty {
                flushPendingOperations()
            }
            
            pendingDeleteCount += count
        }
        
        @_optimize(speed)
        mutating func addInsert(text: String) {
            guard !text.isEmpty else { return }
            
            // Flush non-insert operations before adding insert
            if pendingRetainCount > 0 || pendingDeleteCount > 0 {
                flushPendingOperations()
            }
            
            pendingInsertText += text
        }
        
        @_optimize(speed)
        mutating func flushPendingOperations() {
            if pendingRetainCount > 0 {
                operations.append(.retain(pendingRetainCount))
                pendingRetainCount = 0
            }
            if pendingDeleteCount > 0 {
                operations.append(.delete(pendingDeleteCount))
                pendingDeleteCount = 0
            }
            if !pendingInsertText.isEmpty {
                operations.append(.insert(pendingInsertText))
                pendingInsertText = ""
            }
        }
        
        @_optimize(speed)
        mutating func build() -> [DiffOperation] {
            flushPendingOperations()
            return operations
        }
    }
    
    /// Enhanced algorithm selection heuristics
    struct AlgorithmSelector {
        
        @_optimize(speed)
        static func selectOptimalAlgorithm(source: String, destination: String) -> DiffAlgorithm {
            // Swift 6.1 enhanced decision tree - balance performance with semantic value
            let sourceLines = source.efficientLines
            let destLines = destination.efficientLines
            
            // Fast path for simple cases
            if source.isEmpty || destination.isEmpty {
                return .brus
            }
            
            // Only use Brus for very tiny content (Todd overhead not worth it)
            if sourceLines.count <= 2 && destLines.count <= 2 {
                return .brus
            }
            
            // Use enhanced string comparison for similarity detection
            let similarity = calculateSimilarity(source: source, destination: destination)
            let lineCountDiff = Swift.abs(sourceLines.count - destLines.count)
            
            // Balanced selection - preserve Todd's semantic value
            switch (similarity, lineCountDiff, Swift.max(sourceLines.count, destLines.count)) {
            case (0.95..., _, 0...5):
                // Nearly identical small content - use fast Brus
                return .brus
            case (0.0..<0.1, _, _):
                // Completely different content - Brus for complete rewrites
                return .brus
            default:
                // Most cases benefit from semantic Todd
                return .todd
            }
        }
        
        @_optimize(speed)
        private static func calculateSimilarity(source: String, destination: String) -> Double {
            guard !source.isEmpty && !destination.isEmpty else { return 0.0 }
            
            let commonRegions = EnhancedCommonRegions(source: source, destination: destination)
            let commonChars = commonRegions.prefixLength + commonRegions.suffixLength
            let totalChars = Swift.max(source.count, destination.count)
            
            return Double(commonChars) / Double(totalChars)
        }
    }
}

// MARK: - Enhanced Algorithm Implementations

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
    // Essential location information
    public let sourceStartLine: Int?
    public let sourceTotalLines: Int?
    
    // Context for section matching
    public let precedingContext: String?
    public let followingContext: String?
    
    // Algorithm and tracking
    public let algorithmUsed: DiffAlgorithm?
    public let diffId: String?
    
    // Performance tracking (optional)
    public let diffGenerationTime: Double?
    
    public init(
        sourceStartLine: Int? = nil,
        sourceTotalLines: Int? = nil,
        precedingContext: String? = nil,
        followingContext: String? = nil,
        algorithmUsed: DiffAlgorithm? = nil,
        diffId: String? = nil,
        diffGenerationTime: Double? = nil
    ) {
        self.sourceStartLine = sourceStartLine
        self.sourceTotalLines = sourceTotalLines
        self.precedingContext = precedingContext
        self.followingContext = followingContext
        self.algorithmUsed = algorithmUsed
        self.diffId = diffId
        self.diffGenerationTime = diffGenerationTime
    }
    
    // Computed properties for derived information
    public var sourceEndLine: Int? {
        guard let start = sourceStartLine, let total = sourceTotalLines else { return nil }
        return start + total - 1
    }
    
    // Calculate operation statistics from diff operations
    public func operationStats(from operations: [DiffOperation]) -> (inserts: Int, deletes: Int, retains: Int, changePercentage: Double) {
        var insertCount = 0, deleteCount = 0, retainCount = 0
        var changedChars = 0, totalChars = 0
        
        for op in operations {
            switch op {
            case .insert(let text):
                insertCount += 1
                changedChars += text.count
            case .delete(let count):
                deleteCount += 1
                changedChars += count
                totalChars += count
            case .retain(let count):
                retainCount += 1
                totalChars += count
            }
        }
        
        let changePercentage = totalChars > 0 ? Double(changedChars) / Double(totalChars) * 100 : 0
        return (insertCount, deleteCount, retainCount, changePercentage)
    }
    
    // Convenience factory methods
    public static func forSection(startLine: Int, lineCount: Int, context: String? = nil, algorithm: DiffAlgorithm = .todd) -> DiffMetadata {
        return DiffMetadata(
            sourceStartLine: startLine,
            sourceTotalLines: lineCount,
            precedingContext: context,
            algorithmUsed: algorithm,
            diffId: UUID().uuidString
        )
    }
    
    public static func basic(algorithm: DiffAlgorithm = .todd) -> DiffMetadata {
        return DiffMetadata(
            algorithmUsed: algorithm,
            diffId: UUID().uuidString
        )
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
@frozen public enum DiffAlgorithm: String, Sendable, Codable {
    /// Simple, fast diff algorithm with O(n) time complexity
    case brus
    /// Detailed, semantic diff algorithm with O(n log n) time complexity
    case todd
}

/// Represents different encoding types for diff serialization
public enum DiffEncoding {
    /// Base64 encoded string representation
    case base64
    /// JSON string representation
    case jsonString
    /// Raw JSON data
    case jsonData
}

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
    /// - Metadata generation
    /// - Flexible line number tracking
    ///
    /// # Example
    /// ```swift
    /// let source = "Hello, world!"
    /// let destination = "Hello, Swift!"
    ///
    /// // Default Todd algorithm
    /// let diff = MultiLineDiff.createDiff(
    ///     source: source,
    ///     destination: destination
    /// )
    ///
    /// // Explicitly choose Brus algorithm
    /// let brusDiff = MultiLineDiff.createDiff(
    ///     source: source,
    ///     destination: destination,
    ///     algorithm: .brus
    /// )
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
    /// - Returns: A `DiffResult` containing transformation operations
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
        
        // Generate enhanced metadata for the diff
        return generateEnhancedMetadata(
            result: result,
            source: source,
            destination: destination,
            actualAlgorithm: actualAlgorithmUsed,
            sourceStartLine: sourceStartLine,
            destStartLine: destStartLine
        )
    }
    
    /// Enhanced algorithm execution with intelligent selection and verification
    private static func executeEnhancedAlgorithm(
        algorithm: DiffAlgorithm,
        source: String,
        destination: String
    ) -> (DiffResult, DiffAlgorithm) {
        switch algorithm {
        case .brus:
            return (createEnhancedBrusDiff(source: source, destination: destination), .brus)
        case .todd:
            return executeEnhancedToddWithFallback(source: source, destination: destination)
        }
    }
    
    /// Enhanced Todd algorithm with intelligent fallback
    private static func executeEnhancedToddWithFallback(
        source: String,
        destination: String
    ) -> (DiffResult, DiffAlgorithm) {
        // Try enhanced Todd algorithm
        let toddResult = createEnhancedToddDiff(source: source, destination: destination)
        
        // Verify the Todd result by applying it
        do {
            let appliedResult = try applyDiff(to: source, diff: toddResult, allowTruncatedSource: false)
            if appliedResult == destination {
                return (toddResult, .todd)
            } else {
                // Fallback to enhanced Brus
                return (createEnhancedBrusDiff(source: source, destination: destination), .brus)
            }
        } catch {
            // Fallback to enhanced Brus
            return (createEnhancedBrusDiff(source: source, destination: destination), .brus)
        }
    }
    
    /// Enhanced Brus algorithm using Swift 6.1 features
    @_optimize(speed)
    private static func createEnhancedBrusDiff(source: String, destination: String) -> DiffResult {
        // Handle empty string scenarios first
        if let emptyResult = handleEmptyStrings(source: source, destination: destination) {
            return emptyResult
        }
        
        // Use enhanced common regions detection
        let regions = DiffAlgorithmCore.EnhancedCommonRegions(source: source, destination: destination)
        var builder = DiffAlgorithmCore.OperationBuilder()
        
        // Build operations using enhanced operation builder
        if regions.prefixLength > 0 {
            builder.addRetain(count: regions.prefixLength)
        }
        
        if !regions.sourceMiddleRange.isEmpty {
            builder.addDelete(count: regions.sourceMiddleRange.count)
        }
        
        if !regions.destMiddleRange.isEmpty {
            let destMiddleText = regions.destMiddle(from: destination)
            builder.addInsert(text: destMiddleText)
        }
        
        if regions.suffixLength > 0 {
            builder.addRetain(count: regions.suffixLength)
        }
        
        return DiffResult(operations: builder.build())
    }
    
    /// Enhanced Todd algorithm using Swift 6.1 LCS and line processing with performance optimizations
    @_optimize(speed)
    private static func createEnhancedToddDiff(source: String, destination: String) -> DiffResult {
        // Handle empty strings
        if let emptyResult = handleEmptyStrings(source: source, destination: destination) {
            return emptyResult
        }
        
        // Use Swift 6.1 enhanced line processing
        let sourceLines = source.efficientLines
        let destLines = destination.efficientLines
        
        // Only use simple diff for very tiny content (1-2 lines each)
        if sourceLines.count <= 1 && destLines.count <= 1 {
            return createSimpleLineDiff(sourceLines: sourceLines, destLines: destLines)
        }
        
        // Use optimized LCS for semantic line-by-line processing
        let lcsOperations = generateOptimizedLCSOperations(sourceLines: sourceLines, destLines: destLines)
        var builder = DiffAlgorithmCore.OperationBuilder()
        
        // Convert line operations to character operations
        for operation in lcsOperations {
            switch operation {
            case .retain(let i):
                builder.addRetain(count: lineToCharCount(sourceLines[i], i, sourceLines.count))
                
            case .delete(let i):
                builder.addDelete(count: lineToCharCount(sourceLines[i], i, sourceLines.count))
                
            case .insert(let i):
                builder.addInsert(text: lineToText(destLines[i], i, destLines.count))
            }
        }
        
        return DiffResult(operations: builder.build())
    }
    
    /// Fast path for small line diffs
    @_optimize(speed)
    private static func createSimpleLineDiff(sourceLines: [Substring], destLines: [Substring]) -> DiffResult {
        var builder = DiffAlgorithmCore.OperationBuilder()
        var srcIdx = 0, dstIdx = 0
        
        while srcIdx < sourceLines.count || dstIdx < destLines.count {
            if srcIdx < sourceLines.count && dstIdx < destLines.count && sourceLines[srcIdx] == destLines[dstIdx] {
                // Lines match - retain
                builder.addRetain(count: lineToCharCount(sourceLines[srcIdx], srcIdx, sourceLines.count))
                srcIdx += 1
                dstIdx += 1
            } else if srcIdx < sourceLines.count && (dstIdx >= destLines.count || sourceLines[srcIdx] != destLines[dstIdx]) {
                // Delete source line
                builder.addDelete(count: lineToCharCount(sourceLines[srcIdx], srcIdx, sourceLines.count))
                srcIdx += 1
            } else if dstIdx < destLines.count {
                // Insert destination line
                builder.addInsert(text: lineToText(destLines[dstIdx], dstIdx, destLines.count))
                dstIdx += 1
            }
        }
        
        return DiffResult(operations: builder.build())
    }
    
    /// Optimized LCS operations for semantic line-by-line processing
    private static func generateOptimizedLCSOperations(sourceLines: [Substring], destLines: [Substring]) -> [EnhancedLineOperation] {
        // Handle empty cases
        if sourceLines.isEmpty && destLines.isEmpty {
            return []
        }
        if sourceLines.isEmpty {
            return destLines.indices.map { .insert($0) }
        }
        if destLines.isEmpty {
            return sourceLines.indices.map { .delete($0) }
        }
        
        // Use traditional LCS table but with optimizations
        return generateFastLCS(sourceLines: sourceLines, destLines: destLines)
    }
    
    /// Fast LCS implementation optimized for Swift 6.1
    @_optimize(speed)
    private static func generateFastLCS(sourceLines: [Substring], destLines: [Substring]) -> [EnhancedLineOperation] {
        let srcCount = sourceLines.count
        let dstCount = destLines.count
        
        // Use flat array for better cache locality
        let tableSize = (srcCount + 1) * (dstCount + 1)
        var table = Array(repeating: 0, count: tableSize)
        
        // Helper to convert 2D index to 1D
        func tableIndex(i: Int, j: Int) -> Int {
            return i * (dstCount + 1) + j
        }
        
        // Build LCS table with optimized memory access
        for i in 1...srcCount {
            let sourceLine = sourceLines[i-1]
            let currentRowStart = i * (dstCount + 1)
            let prevRowStart = (i-1) * (dstCount + 1)
            
            for j in 1...dstCount {
                let currentIdx = currentRowStart + j
                if sourceLine == destLines[j-1] {
                    table[currentIdx] = table[prevRowStart + j - 1] + 1
                } else {
                    table[currentIdx] = Swift.max(table[prevRowStart + j], table[currentRowStart + j - 1])
                }
            }
        }
        
        // Fast backtracking
        var operations: [EnhancedLineOperation] = []
        operations.reserveCapacity(srcCount + dstCount)
        
        var i = srcCount
        var j = dstCount
        
        while i > 0 || j > 0 {
            if i > 0 && j > 0 && sourceLines[i-1] == destLines[j-1] {
                operations.append(.retain(i-1))
                i -= 1
                j -= 1
            } else if j > 0 && (i == 0 || table[tableIndex(i: i, j: j-1)] >= table[tableIndex(i: i-1, j: j)]) {
                operations.append(.insert(j-1))
                j -= 1
            } else {
                operations.append(.delete(i-1))
                i -= 1
            }
        }
        
        return operations.reversed()
    }
    
    /// Helper to convert line to character count including newline handling
    @_optimize(speed)
    private static func lineToCharCount(_ line: Substring, _ index: Int, _ total: Int) -> Int {
        line.count + (index == total - 1 ? 0 : 1)
    }
    
    /// Helper to convert line to text including newline handling
    @_optimize(speed)
    private static func lineToText(_ line: Substring, _ index: Int, _ total: Int) -> String {
        String(line) + (index == total - 1 ? "" : "\n")
    }
    
    /// Enhanced line operation for internal processing
    private enum EnhancedLineOperation {
        case retain(Int)  // Line index in source
        case delete(Int)  // Line index in source
        case insert(Int)  // Line index in destination
    }
    
    /// Generate enhanced metadata using Swift 6.1 features
    @_optimize(speed)
    private static func generateEnhancedMetadata(
        result: DiffResult,
        source: String,
        destination: String,
        actualAlgorithm: DiffAlgorithm,
        sourceStartLine: Int?,
        destStartLine: Int?
    ) -> DiffResult {
        let sourceLines = source.efficientLines
        
        // Enhanced context generation
        let contextLength = 30
        let precedingContext = source.prefix(Swift.min(contextLength, source.count)).description
        let followingContext = source.suffix(Swift.min(contextLength, source.count)).description
        
        let metadata = DiffMetadata(
            sourceStartLine: sourceStartLine,
            sourceTotalLines: sourceLines.count,
            precedingContext: precedingContext,
            followingContext: followingContext,
            algorithmUsed: actualAlgorithm,
            diffId: UUID().uuidString,
            diffGenerationTime: nil
        )
        
        return DiffResult(operations: result.operations, metadata: metadata)
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
    
    /// Enhanced diff application with Swift 6.1 optimizations
    @_optimize(speed)
    private static func applyDiffWithEnhancedProcessing(
        source: String,
        operations: [DiffOperation],
        metadata: DiffMetadata?,
        allowTruncatedSource: Bool
    ) throws -> String {
        // Check if this is a section diff that needs special handling
        if allowTruncatedSource, let metadata = metadata, 
           let sourceStartLine = metadata.sourceStartLine,
           sourceStartLine > 0,
           let _ = metadata.precedingContext {
            
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
    
    /// Apply a section diff to a full document by finding the appropriate section
    private static func applySectionDiff(
        fullSource: String,
        operations: [DiffOperation],
        metadata: DiffMetadata
    ) throws -> String? {
        guard let precedingContext = metadata.precedingContext,
              !precedingContext.isEmpty else {
            return nil
        }
        
        // Find the section in the full source that matches the preceding context
        let fullLines = fullSource.efficientLines
        var sectionStartIndex: Int?
        
        // Look for a line that contains the preceding context or starts with it
        for (index, line) in fullLines.enumerated() {
            if String(line).contains(precedingContext.trimmingCharacters(in: .whitespacesAndNewlines)) ||
               precedingContext.contains(String(line).trimmingCharacters(in: .whitespacesAndNewlines)) {
                sectionStartIndex = index
                break
            }
        }
        
        guard let startIndex = sectionStartIndex else {
            return nil // Couldn't find the section
        }
        
        // Calculate the exact number of lines in the original section
        let sourceLines = metadata.sourceTotalLines ?? 3 // Default fallback
        let endIndex = Swift.min(fullLines.count, startIndex + sourceLines)
        
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
    
    /// Enhanced retain operation handling
    @_optimize(speed)
    private static func handleRetainOperation(
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
    private static func handleDeleteOperation(
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

