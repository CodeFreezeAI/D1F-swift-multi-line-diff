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
        
        // Build operations based on lines - PROCESS EACH LINE INDIVIDUALLY
        var operations: [DiffOperation] = []
        
        // Retain common prefix lines
        if commonPrefixCount > 0 {
            let prefixCharCount = sourceLines.prefix(commonPrefixCount).map { $0.count }.reduce(0, +)
            operations.append(.retain(prefixCharCount))
        }
        
        // Process middle lines individually using line-by-line diff
        if !sourceMiddleLines.isEmpty || !destMiddleLines.isEmpty {
            let middleOperations = createLineByLineDiff(
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
    
    /// Create line-by-line diff for middle sections
    @_optimize(speed)
    private static func createLineByLineDiff(
        sourceLines: [Substring],
        destLines: [Substring]
    ) -> [DiffOperation] {
        
        // Use Swift's difference on the middle lines
        let difference = destLines.difference(from: sourceLines)
        
        var operations: [DiffOperation] = []
        var sourceIndex = 0
        var destIndex = 0
        
        // Create sets to track which lines are removed/inserted
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
        
        // Process lines in order, creating individual operations for each line
        while sourceIndex < sourceLines.count || destIndex < destLines.count {
            if sourceIndex < sourceLines.count && removedLines.contains(sourceIndex) {
                // Delete this specific source line
                operations.append(.delete(sourceLines[sourceIndex].count))
                sourceIndex += 1
            } else if destIndex < destLines.count && insertedLines.contains(destIndex) {
                // Insert this specific destination line
                operations.append(.insert(String(destLines[destIndex])))
                destIndex += 1
            } else if sourceIndex < sourceLines.count && destIndex < destLines.count {
                // Retain this line (it's common between source and dest)
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
        
        return operations
    }
    
    /// Alternative line-based approach using CollectionDifference on lines
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
        
        // Split into lines
        let sourceLines = source.efficientLines
        let destLines = destination.efficientLines
        
        // Use Swift's difference on lines
        let difference = destLines.difference(from: sourceLines)
        
        // Verify the difference is valid
        guard let applied = sourceLines.applying(difference), applied == destLines else {
            // Fallback to prefix/suffix approach
            return createDiffUsingSwiftNativeLines(source: source, destination: destination)
        }
        
        // Convert line-based difference to character-based operations
        return convertLineDifferenceToOperations(difference, sourceLines: sourceLines, destLines: destLines)
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