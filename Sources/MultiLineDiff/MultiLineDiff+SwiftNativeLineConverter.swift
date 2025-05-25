//
//  MultiLineDiff+SwiftNativeLineConverter.swift
//  MultiLineDiff
//
//  Created by Todd Bruss on 5/24/25.
//

extension MultiLineDiff {
    
    /// Line-based Swift Native converter using commonPrefix/commonSuffix on lines
    @_optimize(speed)
    internal static func createDiffUsingSwiftNativeLines(
        source: String,
        destination: String
    ) -> DiffResult {
        
        // Fast paths
        if source == destination {
            return source.isEmpty ? DiffResult(operations: []) : DiffResult(operations: [.retain(source.count)])
        }
        
        if source.isEmpty {
            return DiffResult(operations: destination.isEmpty ? [] : [.insert(destination)])
        }
        
        if destination.isEmpty {
            return DiffResult(operations: [.delete(source.count)])
        }
        
        // Split into lines (preserving line endings)
        let sourceLines = source.efficientLines
        let destLines = destination.efficientLines
        
        // Find common prefix lines
        let commonPrefixCount = findCommonPrefixCount(sourceLines, destLines)
        let sourceAfterPrefix = Array(sourceLines.dropFirst(commonPrefixCount))
        let destAfterPrefix = Array(destLines.dropFirst(commonPrefixCount))
        
        // Find common suffix lines
        let commonSuffixCount = findCommonSuffixCount(sourceAfterPrefix, destAfterPrefix)
        
        // Calculate middle sections
        let sourceMiddleLines = Array(sourceAfterPrefix.dropLast(commonSuffixCount))
        let destMiddleLines = Array(destAfterPrefix.dropLast(commonSuffixCount))
        
        // Build operations based on lines - SIMPLE DELETE/INSERT APPROACH
        var operations: [DiffOperation] = []
        
        // Retain common prefix lines
        if commonPrefixCount > 0 {
            let prefixCharCount = sourceLines.prefix(commonPrefixCount).map { $0.count }.reduce(0, +)
            operations.append(.retain(prefixCharCount))
        }
        
        // Handle middle section with smart line-by-line operations
        if !sourceMiddleLines.isEmpty || !destMiddleLines.isEmpty {
            // Use a simple line matching approach that creates reasonable operation counts
            let middleOperations = createSmartLineOperations(
                sourceLines: sourceMiddleLines,
                destLines: destMiddleLines
            )
            operations.append(contentsOf: middleOperations)
        }
        
        // Retain common suffix lines
        if commonSuffixCount > 0 {
            let suffixCharCount = sourceAfterPrefix.suffix(commonSuffixCount).map { $0.count }.reduce(0, +)
            operations.append(.retain(suffixCharCount))
        }
        
        return DiffResult(operations: consolidateLineOperations(operations))
    }
    
    /// Create smart line operations that balance speed and detail
    @_optimize(speed)
    private static func createSmartLineOperations(
        sourceLines: [Substring],
        destLines: [Substring]
    ) -> [DiffOperation] {
        
        // Handle empty cases
        if sourceLines.isEmpty {
            if destLines.isEmpty {
                return []
            } else {
                let insertText = destLines.map { String($0) }.joined()
                return [.insert(insertText)]
            }
        }
        
        if destLines.isEmpty {
            let deleteCount = sourceLines.map { $0.count }.reduce(0, +)
            return [.delete(deleteCount)]
        }
        
        // Group lines into chunks for processing (balance between granularity and efficiency)
        let chunkSize = max(1, min(sourceLines.count, destLines.count) / 100) // Aim for ~100-200 operations
        var operations: [DiffOperation] = []
        var sourceIndex = 0
        var destIndex = 0
        
        while sourceIndex < sourceLines.count || destIndex < destLines.count {
            let sourceChunkEnd = min(sourceIndex + chunkSize, sourceLines.count)
            let destChunkEnd = min(destIndex + chunkSize, destLines.count)
            
            let sourceChunk = Array(sourceLines[sourceIndex..<sourceChunkEnd])
            let destChunk = Array(destLines[destIndex..<destChunkEnd])
            
            // Check if chunks are identical
            if sourceChunk.count == destChunk.count && sourceChunk.elementsEqual(destChunk) {
                // Retain the entire chunk
                let chunkCharCount = sourceChunk.map { $0.count }.reduce(0, +)
                operations.append(.retain(chunkCharCount))
                sourceIndex = sourceChunkEnd
                destIndex = destChunkEnd
            } else {
                // Replace the chunk
                if !sourceChunk.isEmpty {
                    let deleteCount = sourceChunk.map { $0.count }.reduce(0, +)
                    operations.append(.delete(deleteCount))
                }
                
                if !destChunk.isEmpty {
                    let insertText = destChunk.map { String($0) }.joined()
                    operations.append(.insert(insertText))
                }
                
                sourceIndex = sourceChunkEnd
                destIndex = destChunkEnd
            }
        }
        
        return operations
    }
    
    /// Fast and detailed line-based approach with fine-grained operations
    @_optimize(speed)
    internal static func createDiffUsingSwiftNativeLinesWithDifference(
        source: String,
        destination: String
    ) -> DiffResult {
        
        // Fast paths
        if source == destination {
            return source.isEmpty ? DiffResult(operations: []) : DiffResult(operations: [.retain(source.count)])
        }
        
        if source.isEmpty {
            return DiffResult(operations: destination.isEmpty ? [] : [.insert(destination)])
        }
        
        if destination.isEmpty {
            return DiffResult(operations: [.delete(source.count)])
        }
        
        // Split into lines (preserving line endings)
        let sourceLines = source.efficientLines
        let destLines = destination.efficientLines
        
        // Find common prefix lines (like .line algorithm)
        let commonPrefixCount = findCommonPrefixCount(sourceLines, destLines)
        let sourceAfterPrefix = Array(sourceLines.dropFirst(commonPrefixCount))
        let destAfterPrefix = Array(destLines.dropFirst(commonPrefixCount))
        
        // Find common suffix lines
        let commonSuffixCount = findCommonSuffixCount(sourceAfterPrefix, destAfterPrefix)
        
        // Calculate middle sections
        let sourceMiddleLines = Array(sourceAfterPrefix.dropLast(commonSuffixCount))
        let destMiddleLines = Array(destAfterPrefix.dropLast(commonSuffixCount))
        
        // Build operations with detailed line-by-line processing
        var operations: [DiffOperation] = []
        
        // Retain common prefix lines
        if commonPrefixCount > 0 {
            let prefixCharCount = sourceLines.prefix(commonPrefixCount).map { $0.count }.reduce(0, +)
            operations.append(.retain(prefixCharCount))
        }
        
        // Handle middle section with detailed line operations
        if !sourceMiddleLines.isEmpty || !destMiddleLines.isEmpty {
            let middleOperations = createDetailedLineOperations(
                sourceLines: sourceMiddleLines,
                destLines: destMiddleLines
            )
            operations.append(contentsOf: middleOperations)
        }
        
        // Retain common suffix lines
        if commonSuffixCount > 0 {
            let suffixCharCount = sourceAfterPrefix.suffix(commonSuffixCount).map { $0.count }.reduce(0, +)
            operations.append(.retain(suffixCharCount))
        }
        
        return DiffResult(operations: consolidateLineOperations(operations))
    }
    
    /// Create detailed line operations with fine-grained processing
    @_optimize(speed)
    private static func createDetailedLineOperations(
        sourceLines: [Substring],
        destLines: [Substring]
    ) -> [DiffOperation] {
        
        // Handle empty cases
        if sourceLines.isEmpty {
            if destLines.isEmpty {
                return []
            } else {
                let insertText = destLines.map { String($0) }.joined()
                return [.insert(insertText)]
            }
        }
        
        if destLines.isEmpty {
            let deleteCount = sourceLines.map { $0.count }.reduce(0, +)
            return [.delete(deleteCount)]
        }
        
        // Use medium chunks for balanced operations (aim for 300-800 operations)
        let chunkSize = max(1, min(sourceLines.count, destLines.count) / 20) // Medium chunks = balanced detail
        var operations: [DiffOperation] = []
        var sourceIndex = 0
        var destIndex = 0
        
        while sourceIndex < sourceLines.count || destIndex < destLines.count {
            let sourceChunkEnd = min(sourceIndex + chunkSize, sourceLines.count)
            let destChunkEnd = min(destIndex + chunkSize, destLines.count)
            
            let sourceChunk = Array(sourceLines[sourceIndex..<sourceChunkEnd])
            let destChunk = Array(destLines[destIndex..<destChunkEnd])
            
            // Check if chunks are similar enough to retain, otherwise replace as blocks
            if sourceChunk.count == destChunk.count && sourceChunk.elementsEqual(destChunk) {
                // Chunks are identical - retain the entire chunk
                let chunkCharCount = sourceChunk.map { $0.count }.reduce(0, +)
                operations.append(.retain(chunkCharCount))
            } else {
                // Chunks differ - replace as blocks for efficiency
                if !sourceChunk.isEmpty {
                    let deleteCount = sourceChunk.map { $0.count }.reduce(0, +)
                    operations.append(.delete(deleteCount))
                }
                
                if !destChunk.isEmpty {
                    let insertText = destChunk.map { String($0) }.joined()
                    operations.append(.insert(insertText))
                }
            }
            
            sourceIndex = sourceChunkEnd
            destIndex = destChunkEnd
        }
        
        return operations
    }
    
    /// Convert line-based CollectionDifference to character-based DiffOperations
    @_optimize(speed)
    private static func convertLineDifferenceToOperations(
        _ difference: CollectionDifference<Substring>,
        sourceLines: [Substring],
        destLines: [Substring]
    ) -> DiffResult {
        
        if difference.isEmpty {
            let totalChars = sourceLines.map { $0.count }.reduce(0, +)
            return DiffResult(operations: [.retain(totalChars)])
        }
        
        var operations: [DiffOperation] = []
        var sourceIndex = 0
        var destIndex = 0
        
        // Create arrays to track which lines are removed/inserted
        var removedLines = Set<Int>()
        var insertedLines = Set<Int>()
        
        for change in difference {
            switch change {
            case .remove(let offset, _, _):
                removedLines.insert(offset)
            case .insert(let offset, _, _):
                insertedLines.insert(offset)
            }
        }
        
        // Process lines in order
        while sourceIndex < sourceLines.count || destIndex < destLines.count {
            if sourceIndex < sourceLines.count && removedLines.contains(sourceIndex) {
                // Delete this source line
                operations.append(.delete(sourceLines[sourceIndex].count))
                sourceIndex += 1
            } else if destIndex < destLines.count && insertedLines.contains(destIndex) {
                // Insert this destination line
                operations.append(.insert(String(destLines[destIndex])))
                destIndex += 1
            } else if sourceIndex < sourceLines.count && destIndex < destLines.count {
                // Retain this line (it's common)
                operations.append(.retain(sourceLines[sourceIndex].count))
                sourceIndex += 1
                destIndex += 1
            } else if sourceIndex < sourceLines.count {
                // Delete remaining source lines
                operations.append(.delete(sourceLines[sourceIndex].count))
                sourceIndex += 1
            } else if destIndex < destLines.count {
                // Insert remaining destination lines
                operations.append(.insert(String(destLines[destIndex])))
                destIndex += 1
            }
        }
        
        // Consolidate consecutive operations
        return DiffResult(operations: consolidateLineOperations(operations))
    }
    
    /// Find common prefix count between two line arrays
    @_optimize(speed)
    private static func findCommonPrefixCount<T: Equatable>(_ array1: [T], _ array2: [T]) -> Int {
        let minCount = min(array1.count, array2.count)
        var commonCount = 0
        
        for i in 0..<minCount {
            if array1[i] == array2[i] {
                commonCount += 1
            } else {
                break
            }
        }
        
        return commonCount
    }
    
    /// Find common suffix count between two line arrays
    @_optimize(speed)
    private static func findCommonSuffixCount<T: Equatable>(_ array1: [T], _ array2: [T]) -> Int {
        let minCount = min(array1.count, array2.count)
        var commonCount = 0
        
        for i in 1...minCount {
            let index1 = array1.count - i
            let index2 = array2.count - i
            
            if array1[index1] == array2[index2] {
                commonCount += 1
            } else {
                break
            }
        }
        
        return commonCount
    }
    
    /// Consolidate consecutive operations for line-based processing
    @_optimize(speed)
    private static func consolidateLineOperations(_ operations: [DiffOperation]) -> [DiffOperation] {
        guard !operations.isEmpty else { return [] }
        
        var consolidated: [DiffOperation] = []
        var current = operations[0]
        
        for i in 1..<operations.count {
            let next = operations[i]
            
            switch (current, next) {
            case (.retain(let count1), .retain(let count2)):
                current = .retain(count1 + count2)
            case (.delete(let count1), .delete(let count2)):
                current = .delete(count1 + count2)
            case (.insert(let text1), .insert(let text2)):
                current = .insert(text1 + text2)
            default:
                consolidated.append(current)
                current = next
            }
        }
        
        consolidated.append(current)
        return consolidated
    }
    
    /// Public method for line-based Swift native approach (prefix/suffix)
    @_optimize(speed)
    public static func createDiffUsingSwiftNativeLinesMethods(
        source: String,
        destination: String
    ) -> DiffResult {
        return createDiffUsingSwiftNativeLines(source: source, destination: destination)
    }
    
    /// Public method for line-based Swift native approach (difference)
    @_optimize(speed)
    public static func createDiffUsingSwiftNativeLinesWithDifferenceMethods(
        source: String,
        destination: String
    ) -> DiffResult {
        return createDiffUsingSwiftNativeLinesWithDifference(source: source, destination: destination)
    }
} 