//
//  EnhancedLineOperation.swift
//  MultiLineDiff
//
//  Created by Todd Bruss on 5/24/25.
//

import Foundation
import CommonCrypto

#if canImport(CryptoKit)
import CryptoKit
#endif

extension MultiLineDiff {
    
    /// Enhanced algorithm execution with intelligent selection and verification
    internal static func executeEnhancedAlgorithm(
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
    internal static func executeEnhancedToddWithFallback(
        source: String,
        destination: String
    ) -> (DiffResult, DiffAlgorithm) {
        // Try enhanced Todd algorithm
        let toddResult = createEnhancedToddDiff(source: source, destination: destination)
        
        // Verify the Todd result by applying it
        do {
            let appliedResult = try applyDiff(to: source, diff: toddResult)
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
    internal static func createEnhancedBrusDiff(source: String, destination: String) -> DiffResult {
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
    internal static func createEnhancedToddDiff(source: String, destination: String) -> DiffResult {
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
        let lcsOperations = generateMyersLCS(sourceLines: sourceLines, destLines: destLines)
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
    internal static func createSimpleLineDiff(sourceLines: [Substring], destLines: [Substring]) -> DiffResult {
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
    
    /// Swift built-in difference algorithm - uses optimized Myers implementation internally
    @_optimize(speed)
    internal static func generateMyersLCS(sourceLines: [Substring], destLines: [Substring]) -> [EnhancedLineOperation] {
        let M = sourceLines.count
        let N = destLines.count
        
        // Handle edge cases
        if M == 0 || N == 0 {
            return handleEmptyCases(srcCount: M, dstCount: N)
        }
        
        // Use Swift's built-in optimized difference algorithm
        let difference = destLines.difference(from: sourceLines)
        
        // Pre-allocate operations array for better performance
        var operations: [EnhancedLineOperation] = []
        operations.reserveCapacity(M + N)
        
        // Process difference directly without creating intermediate sets
        var sourceIndex = 0
        var destIndex = 0
        var changeIndex = 0
        let sortedChanges = Array(difference).sorted { lhs, rhs in
            let lhsOffset = getOffset(from: lhs)
            let rhsOffset = getOffset(from: rhs)
            return lhsOffset < rhsOffset
        }
        
        // Single pass through both arrays using sorted changes
        while sourceIndex < M || destIndex < N {
            // Check if there's a pending change at current position
            var hasChange = false
            
            while changeIndex < sortedChanges.count {
                let change = sortedChanges[changeIndex]
                
                switch change {
                case .remove(let offset, _, _) where offset == sourceIndex:
                    operations.append(.delete(sourceIndex))
                    sourceIndex += 1
                    changeIndex += 1
                    hasChange = true
                    continue
                    
                case .insert(let offset, _, _) where offset == destIndex:
                    operations.append(.insert(destIndex))
                    destIndex += 1
                    changeIndex += 1
                    hasChange = true
                    continue
                    
                default:
                    break
                }
                break
            }
            
            // If no change, it's a retain (if both indices are valid)
            if !hasChange {
                if sourceIndex < M && destIndex < N {
                    operations.append(.retain(sourceIndex))
                    sourceIndex += 1
                    destIndex += 1
                } else if sourceIndex < M {
                    // Remaining source (delete)
                    operations.append(.delete(sourceIndex))
                    sourceIndex += 1
                } else {
                    // Remaining dest (insert)
                    operations.append(.insert(destIndex))
                    destIndex += 1
                }
            }
        }
        
        return operations
    }
    
    /// Helper to extract offset from CollectionDifference.Change
    @_optimize(speed)
    private static func getOffset(from change: CollectionDifference<Substring>.Change) -> Int {
        switch change {
        case .remove(let offset, _, _), .insert(let offset, _, _):
            return offset
        }
    }
    
    /// Linear scan for very similar texts - O(n) single pass, no nested loops
    @_optimize(speed)
    internal static func generateLinearScanLCS(sourceLines: [Substring], destLines: [Substring]) -> [EnhancedLineOperation] {
        var operations: [EnhancedLineOperation] = []
        var srcIndex = 0
        var dstIndex = 0
        
        // Single while loop - no nesting!
        while srcIndex < sourceLines.count || dstIndex < destLines.count {
            if srcIndex >= sourceLines.count {
                // Insert remaining dest lines
                operations.append(.insert(dstIndex))
                dstIndex += 1
            } else if dstIndex >= destLines.count {
                // Delete remaining source lines
                operations.append(.delete(srcIndex))
                srcIndex += 1
            } else if sourceLines[srcIndex] == destLines[dstIndex] {
                // Lines match - retain
                operations.append(.retain(srcIndex))
                srcIndex += 1
                dstIndex += 1
            } else {
                // Look ahead for next match (limited lookahead to avoid nested loops)
                let lookAhead = min(3, sourceLines.count - srcIndex, destLines.count - dstIndex)
                var foundMatch = false
                
                // Single loop with limited range
                for offset in 1...lookAhead {
                    if srcIndex + offset < sourceLines.count && sourceLines[srcIndex + offset] == destLines[dstIndex] {
                        // Found match in source - delete intervening lines
                        for deleteIndex in srcIndex..<(srcIndex + offset) {
                            operations.append(.delete(deleteIndex))
                        }
                        srcIndex += offset
                        foundMatch = true
                        break
                    } else if dstIndex + offset < destLines.count && sourceLines[srcIndex] == destLines[dstIndex + offset] {
                        // Found match in dest - insert intervening lines
                        for insertIndex in dstIndex..<(dstIndex + offset) {
                            operations.append(.insert(insertIndex))
                        }
                        dstIndex += offset
                        foundMatch = true
                        break
                    }
                }
                
                if !foundMatch {
                    // No nearby match - assume substitution
                    operations.append(.delete(srcIndex))
                    operations.append(.insert(dstIndex))
                    srcIndex += 1
                    dstIndex += 1
                }
            }
        }
        
        return operations
    }
    
    /// Small input optimization - direct comparison without loops
    @_optimize(speed)
    internal static func generateSmallInputLCS(sourceLines: [Substring], destLines: [Substring]) -> [EnhancedLineOperation] {
        let srcCount = sourceLines.count
        let dstCount = destLines.count
        
        // Handle all small cases explicitly (no loops needed)
        switch (srcCount, dstCount) {
        case (1, 1):
            return sourceLines[0] == destLines[0] ? [.retain(0)] : [.delete(0), .insert(0)]
        case (1, 2):
            if sourceLines[0] == destLines[0] {
                return [.retain(0), .insert(1)]
            } else if sourceLines[0] == destLines[1] {
                return [.insert(0), .retain(0)]
            } else {
                return [.delete(0), .insert(0), .insert(1)]
            }
        case (2, 1):
            if sourceLines[0] == destLines[0] {
                return [.retain(0), .delete(1)]
            } else if sourceLines[1] == destLines[0] {
                return [.delete(0), .retain(1)]
            } else {
                return [.delete(0), .delete(1), .insert(0)]
            }
        default:
            // For 2x2, 3x3, etc. - use optimized direct comparison
            return generateDirectComparisonLCS(sourceLines: sourceLines, destLines: destLines)
        }
    }
    
    /// Calculate line similarity without nested loops using set intersection
    @_optimize(speed)
    internal static func calculateLineSimilarity(sourceLines: [Substring], destLines: [Substring]) -> Double {
        guard !sourceLines.isEmpty && !destLines.isEmpty else { return 0.0 }
        
        let sourceSet = Set(sourceLines)
        let destSet = Set(destLines)
        let commonLines = sourceSet.intersection(destSet).count
        let totalLines = sourceSet.count + destSet.count
        
        return Double(commonLines) / Double(totalLines)
    }
    
    // MARK: - Helper Functions (All avoid nested loops)
    
    /// Find LIS using patience sorting - O(n log n) single loop
    @_optimize(speed)
    internal static func findLongestIncreasingSubsequence(_ matches: [(Int, Int)]) -> [(Int, Int)] {
        if matches.isEmpty { return [] }
        
        // Sort by first coordinate, then by second (single sort operation)
        let sortedMatches = matches.sorted { $0.0 < $1.0 || ($0.0 == $1.0 && $0.1 < $1.1) }
        
        var tails: [Int] = []
        var predecessors: [Int] = Array(repeating: -1, count: sortedMatches.count)
        var tailIndices: [Int] = []
        
        // Single loop with binary search
        for (index, match) in sortedMatches.enumerated() {
            let value = match.1
            
            // Binary search for insertion point
            let pos = binarySearchInsertionPoint(tails, value)
            
            if pos == tails.count {
                tails.append(value)
                tailIndices.append(index)
            } else if pos < tails.count {
                tails[pos] = value
                if pos < tailIndices.count {
                    tailIndices[pos] = index
                } else {
                    tailIndices.append(index)
                }
            }
            
            if pos > 0 && pos - 1 < tailIndices.count {
                predecessors[index] = tailIndices[pos - 1]
            }
        }
        
        // Reconstruct LIS (single backtrack loop)
        var result: [(Int, Int)] = []
        if let lastIndex = tailIndices.last {
            var current = lastIndex
            
            while current != -1 && current < sortedMatches.count {
                result.append(sortedMatches[current])
                current = predecessors[current]
            }
        }
        
        return result.reversed()
    }
    
    /// Binary search without loops (recursive or using built-in)
    @_optimize(speed)
    internal static func binarySearchInsertionPoint(_ array: [Int], _ target: Int) -> Int {
        var left = 0
        var right = array.count
        
        // Single while loop for binary search
        while left < right {
            let mid = (left + right) / 2
            if array[mid] < target {
                left = mid + 1
            } else {
                right = mid
            }
        }
        
        return left
    }
    
    /// Convert LIS to operations without nested loops
    @_optimize(speed)
    internal static func convertLISToOperations(lis: [(Int, Int)], sourceCount: Int, destCount: Int) -> [EnhancedLineOperation] {
        var operations: [EnhancedLineOperation] = []
        var srcIndex = 0
        var dstIndex = 0
        var lisIndex = 0
        
        // Single loop through all positions
        while srcIndex < sourceCount || dstIndex < destCount {
            if lisIndex < lis.count && srcIndex == lis[lisIndex].0 && dstIndex == lis[lisIndex].1 {
                // This is a match in the LIS
                operations.append(.retain(srcIndex))
                srcIndex += 1
                dstIndex += 1
                lisIndex += 1
            } else if lisIndex < lis.count && srcIndex < lis[lisIndex].0 {
                // Delete from source until we reach the next LIS match
                operations.append(.delete(srcIndex))
                srcIndex += 1
            } else if lisIndex < lis.count && dstIndex < lis[lisIndex].1 {
                // Insert from dest until we reach the next LIS match
                operations.append(.insert(dstIndex))
                dstIndex += 1
            } else if srcIndex < sourceCount {
                // Delete remaining source
                operations.append(.delete(srcIndex))
                srcIndex += 1
            } else {
                // Insert remaining dest
                operations.append(.insert(dstIndex))
                dstIndex += 1
            }
        }
        
        return operations
    }
    
    /// Handle empty cases without any loops
    internal static func handleEmptyCases(srcCount: Int, dstCount: Int) -> [EnhancedLineOperation] {
        if srcCount == 0 && dstCount == 0 {
            return []
        } else if srcCount == 0 {
            return (0..<dstCount).map { .insert($0) }
        } else {
            return (0..<srcCount).map { .delete($0) }
        }
    }
    
    /// Direct comparison for very small inputs
    @_optimize(speed)
    internal static func generateDirectComparisonLCS(sourceLines: [Substring], destLines: [Substring]) -> [EnhancedLineOperation] {
        // For small inputs, we can enumerate all possibilities without nested loops
        // This is a simplified version that works for inputs up to 3x3
        var operations: [EnhancedLineOperation] = []
        
        // Use a simple greedy approach for small inputs
        var srcIndex = 0
        var dstIndex = 0
        
        while srcIndex < sourceLines.count && dstIndex < destLines.count {
            if sourceLines[srcIndex] == destLines[dstIndex] {
                operations.append(.retain(srcIndex))
                srcIndex += 1
                dstIndex += 1
            } else {
                // Look for the line in the remaining dest lines (limited search)
                var found = false
                let searchLimit = min(3, destLines.count)
                
                for searchIndex in (dstIndex + 1)..<min(dstIndex + searchLimit, destLines.count) {
                    if sourceLines[srcIndex] == destLines[searchIndex] {
                        // Insert the intermediate lines
                        for insertIndex in dstIndex..<searchIndex {
                            operations.append(.insert(insertIndex))
                        }
                        operations.append(.retain(srcIndex))
                        srcIndex += 1
                        dstIndex = searchIndex + 1
                        found = true
                        break
                    }
                }
                
                if !found {
                    operations.append(.delete(srcIndex))
                    srcIndex += 1
                }
            }
        }
        
        // Handle remaining lines
        while srcIndex < sourceLines.count {
            operations.append(.delete(srcIndex))
            srcIndex += 1
        }
        
        while dstIndex < destLines.count {
            operations.append(.insert(dstIndex))
            dstIndex += 1
        }
        
        return operations
    }
    
    /// Simple fallback diff without nested loops
    @_optimize(speed)
    internal static func generateSimpleDiff(sourceLines: [Substring], destLines: [Substring]) -> [EnhancedLineOperation] {
        var operations: [EnhancedLineOperation] = []
        
        // Simple approach: delete all source, insert all dest
        for i in 0..<sourceLines.count {
            operations.append(.delete(i))
        }
        
        for i in 0..<destLines.count {
            operations.append(.insert(i))
        }
        
        return operations
    }
    
    /// Helper to convert line to character count including newline handling
    @_optimize(speed)
    internal static func lineToCharCount(_ line: Substring, _ index: Int, _ total: Int) -> Int {
        line.count + (index == total - 1 ? 0 : 1)
    }
    
    /// Helper to convert line to text including newline handling
    @_optimize(speed)
    internal static func lineToText(_ line: Substring, _ index: Int, _ total: Int) -> String {
        String(line) + (index == total - 1 ? "" : "\n")
    }
    
    /// Enhanced line operation for internal processing
    internal enum EnhancedLineOperation {
        case retain(Int)  // Line index in source
        case delete(Int)  // Line index in source
        case insert(Int)  // Line index in destination
    }
    
    /// Generate enhanced metadata using Swift 6.1 features
    @_optimize(speed)
    internal static func generateEnhancedMetadata(
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
        
        // Store both source and destination content for verification and undo operations
        let sourceContent = source
        let destinationContent = destination
        
        // Auto-detect application type based on metadata characteristics
        let applicationType = DiffMetadata.autoDetectApplicationType(
            sourceStartLine: sourceStartLine,
            precedingContext: precedingContext,
            followingContext: followingContext,
            sourceContent: sourceContent
        )
        
        // Create temporary metadata without hash
        let tempMetadata = DiffMetadata(
            sourceStartLine: sourceStartLine,
            sourceTotalLines: sourceLines.count,
            precedingContext: precedingContext,
            followingContext: followingContext,
            sourceContent: sourceContent,
            destinationContent: destinationContent,
            algorithmUsed: actualAlgorithm,
            diffHash: nil,
            applicationType: applicationType,
            diffGenerationTime: nil
        )
        
        let tempResult = DiffResult(operations: result.operations, metadata: tempMetadata)
        
        // Generate SHA256 hash of the base64 diff
        let diffHash = generateDiffHash(for: tempResult)
        
        // Create final metadata with hash
        let finalMetadata = DiffMetadata(
            sourceStartLine: sourceStartLine,
            sourceTotalLines: sourceLines.count,
            precedingContext: precedingContext,
            followingContext: followingContext,
            sourceContent: sourceContent,
            destinationContent: destinationContent,
            algorithmUsed: actualAlgorithm,
            diffHash: diffHash,
            applicationType: applicationType,
            diffGenerationTime: nil
        )
        
        return DiffResult(operations: result.operations, metadata: finalMetadata)
    }
    
    /// Generate SHA256 hash of the base64 encoded diff for integrity verification
    @_optimize(speed)
    internal static func generateDiffHash(for diff: DiffResult) -> String {
        do {
            // Get base64 representation of the diff
            let base64Diff = try diffToBase64(diff)
            
            // Calculate SHA256 hash of the base64 string
            let data = Data(base64Diff.utf8)
            
            // Use CryptoKit if available (macOS 10.15+), otherwise use CommonCrypto
#if canImport(CryptoKit)
            if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
                let hash = SHA256.hash(data: data)
                return hash.compactMap { String(format: "%02x", $0) }.joined()
            } else {
                return sha256HashUsingCommonCrypto(data: data)
            }
#else
            return sha256HashUsingCommonCrypto(data: data)
#endif
        } catch {
            // Fallback to deterministic hash based on content if base64 fails
            return generateFallbackHash(for: diff)
        }
    }
    
    /// Cross-platform SHA256 implementation using CommonCrypto
    @_optimize(speed)
    internal static func sha256HashUsingCommonCrypto(data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { bytes in
            _ = CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Generate a fallback hash based on diff operations for extreme edge cases
    @_optimize(speed)
    internal static func generateFallbackHash(for diff: DiffResult) -> String {
        var hashComponents: [String] = []
        
        // Include operation signatures
        for operation in diff.operations {
            switch operation {
            case .retain(let count):
                hashComponents.append("r\(count)")
            case .insert(let text):
                hashComponents.append("i\(text.count):\(text.hashValue)")
            case .delete(let count):
                hashComponents.append("d\(count)")
            }
        }
        
        // Create deterministic hash from operation signatures
        let signature = hashComponents.joined(separator: "|")
        let data = Data(signature.utf8)
        return sha256HashUsingCommonCrypto(data: data)
    }
}
