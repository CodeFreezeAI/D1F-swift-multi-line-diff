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
        
        // Handle middle section with simple but efficient approach
        if !sourceMiddleLines.isEmpty || !destMiddleLines.isEmpty {
            // Apply prefix/suffix optimization to the middle section as well
            let middlePrefixCount = findCommonPrefixCount(sourceMiddleLines, destMiddleLines)
            let sourceAfterMiddlePrefix = Array(sourceMiddleLines.dropFirst(middlePrefixCount))
            let destAfterMiddlePrefix = Array(destMiddleLines.dropFirst(middlePrefixCount))
            
            let middleSuffixCount = findCommonSuffixCount(sourceAfterMiddlePrefix, destAfterMiddlePrefix)
            let sourceCore = Array(sourceAfterMiddlePrefix.dropLast(middleSuffixCount))
            let destCore = Array(destAfterMiddlePrefix.dropLast(middleSuffixCount))
            
            // Retain middle prefix
            if middlePrefixCount > 0 {
                let prefixCharCount = sourceMiddleLines.prefix(middlePrefixCount).map { $0.count }.reduce(0, +)
                operations.append(.retain(prefixCharCount))
            }
            
            // Handle core differences with bulk operations
            if !sourceCore.isEmpty {
                let deleteCount = sourceCore.map { $0.count }.reduce(0, +)
                operations.append(.delete(deleteCount))
            }
            
            if !destCore.isEmpty {
                let insertText = destCore.map { String($0) }.joined()
                operations.append(.insert(insertText))
            }
            
            // Retain middle suffix
            if middleSuffixCount > 0 {
                let suffixCharCount = sourceAfterMiddlePrefix.suffix(middleSuffixCount).map { $0.count }.reduce(0, +)
                operations.append(.retain(suffixCharCount))
            }
        }
        
        // Retain common suffix lines
        if commonSuffixCount > 0 {
            let suffixCharCount = sourceAfterPrefix.suffix(commonSuffixCount).map { $0.count }.reduce(0, +)
            operations.append(.retain(suffixCharCount))
        }
        
        return DiffResult(operations: consolidateLineOperations(operations))
    }
    
    /// Create intelligent line-by-line diff without using CollectionDifference
    @_optimize(speed)
    private static func createIntelligentLineByLineDiff(
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
        
        // Use a simple but efficient line matching approach
        var operations: [DiffOperation] = []
        var sourceIndex = 0
        var destIndex = 0
        
        // Process lines by finding exact matches and handling differences
        while sourceIndex < sourceLines.count || destIndex < destLines.count {
            
            // If we've processed all source lines, insert remaining dest lines
            if sourceIndex >= sourceLines.count {
                let remainingDestText = destLines[destIndex...].map { String($0) }.joined()
                operations.append(.insert(remainingDestText))
                break
            }
            
            // If we've processed all dest lines, delete remaining source lines
            if destIndex >= destLines.count {
                let remainingSourceCount = sourceLines[sourceIndex...].map { $0.count }.reduce(0, +)
                operations.append(.delete(remainingSourceCount))
                break
            }
            
            let sourceLine = sourceLines[sourceIndex]
            let destLine = destLines[destIndex]
            
            // If lines match exactly, retain
            if sourceLine == destLine {
                operations.append(.retain(sourceLine.count))
                sourceIndex += 1
                destIndex += 1
                continue
            }
            
            // Lines don't match - look ahead to see if we can find a match
            let lookAheadDistance = min(5, min(sourceLines.count - sourceIndex, destLines.count - destIndex))
            var foundMatch = false
            
            // Look for the dest line in upcoming source lines (deletion case)
            for i in 1..<lookAheadDistance {
                if sourceIndex + i < sourceLines.count && sourceLines[sourceIndex + i] == destLine {
                    // Delete the intervening source lines
                    let deleteCount = sourceLines[sourceIndex..<sourceIndex + i].map { $0.count }.reduce(0, +)
                    operations.append(.delete(deleteCount))
                    sourceIndex += i
                    foundMatch = true
                    break
                }
            }
            
            if foundMatch { continue }
            
            // Look for the source line in upcoming dest lines (insertion case)
            for i in 1..<lookAheadDistance {
                if destIndex + i < destLines.count && destLines[destIndex + i] == sourceLine {
                    // Insert the intervening dest lines
                    let insertText = destLines[destIndex..<destIndex + i].map { String($0) }.joined()
                    operations.append(.insert(insertText))
                    destIndex += i
                    foundMatch = true
                    break
                }
            }
            
            if foundMatch { continue }
            
            // No match found in lookahead - treat as a replacement
            operations.append(.delete(sourceLine.count))
            operations.append(.insert(String(destLine)))
            sourceIndex += 1
            destIndex += 1
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