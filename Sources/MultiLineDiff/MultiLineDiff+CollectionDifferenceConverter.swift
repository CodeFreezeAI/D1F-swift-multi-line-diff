//
//  MultiLineDiff+CollectionDifferenceConverter.swift
//  MultiLineDiff
//
//  Created by Todd Bruss on 5/24/25.
//

extension MultiLineDiff {
    
    /// Convert Swift's CollectionDifference to DiffOperation array
    @_optimize(speed)
    internal static func convertCollectionDifference<T: Collection>(
        _ difference: CollectionDifference<T.Element>,
        source: T,
        destination: T
    ) -> [DiffOperation] where T.Element: Equatable {
        
        var operations: [DiffOperation] = []
        
        // Sort changes by offset to process in order
        let sortedChanges = difference.sorted { lhs, rhs in
            switch (lhs, rhs) {
            case (.remove(let lOffset, _, _), .remove(let rOffset, _, _)):
                return lOffset < rOffset
            case (.insert(let lOffset, _, _), .insert(let rOffset, _, _)):
                return lOffset < rOffset
            case (.remove(let lOffset, _, _), .insert(let rOffset, _, _)):
                return lOffset <= rOffset
            case (.insert(let lOffset, _, _), .remove(let rOffset, _, _)):
                return lOffset < rOffset
            }
        }
        
        var processedSourceOffset = 0
        var processedDestOffset = 0
        
        for change in sortedChanges {
            switch change {
            case .remove(let offset, _, _):
                // Add retains for unchanged elements before this removal
                let retainCount = offset - processedSourceOffset
                if retainCount > 0 {
                    operations.append(.retain(retainCount))
                }
                
                // Add delete operation
                operations.append(.delete(1)) // Assuming single character/element
                processedSourceOffset = offset + 1
                
            case .insert(let offset, let element, _):
                // Add retains for unchanged elements before this insertion
                let retainCount = offset - processedDestOffset
                if retainCount > 0 {
                    operations.append(.retain(retainCount))
                    processedSourceOffset += retainCount
                }
                
                // Add insert operation
                let insertText = String(describing: element)
                operations.append(.insert(insertText))
                processedDestOffset = offset + 1
            }
        }
        
        // Add final retains for any remaining unchanged elements
        let remainingSourceCount = source.count - processedSourceOffset
        if remainingSourceCount > 0 {
            operations.append(.retain(remainingSourceCount))
        }
        
        return operations
    }
    
    /// Convert String CollectionDifference to DiffOperation array (optimized for strings)
    @_optimize(speed)
    internal static func convertStringDifference(
        _ difference: CollectionDifference<Character>,
        source: String,
        destination: String
    ) -> [DiffOperation] {
        
        // Simple approach: build a sequence of operations by walking through both strings
        var operations: [DiffOperation] = []
        var sourceIndex = 0
        var destIndex = 0
        
        // Convert difference to arrays for easier processing
        var removals: [Int] = []
        var insertions: [(offset: Int, char: Character)] = []
        
        for change in difference {
            switch change {
            case .remove(let offset, _, _):
                removals.append(offset)
            case .insert(let offset, let char, _):
                insertions.append((offset, char))
            }
        }
        
        removals.sort()
        insertions.sort { $0.offset < $1.offset }
        
        // Process by walking through the source string
        while sourceIndex < source.count || destIndex < destination.count {
            
            // Check if current source position should be deleted
            if removals.contains(sourceIndex) {
                operations.append(.delete(1))
                sourceIndex += 1
                continue
            }
            
            // Check if we need to insert at current destination position
            if let insertion = insertions.first(where: { $0.offset == destIndex }) {
                operations.append(.insert(String(insertion.char)))
                destIndex += 1
                continue
            }
            
            // If we're at valid positions in both strings, check if they match
            if sourceIndex < source.count && destIndex < destination.count {
                let sourceChar = source[source.index(source.startIndex, offsetBy: sourceIndex)]
                let destChar = destination[destination.index(destination.startIndex, offsetBy: destIndex)]
                
                if sourceChar == destChar {
                    operations.append(.retain(1))
                    sourceIndex += 1
                    destIndex += 1
                } else {
                    // Characters don't match - this shouldn't happen with proper diff
                    // But handle it gracefully
                    operations.append(.delete(1))
                    operations.append(.insert(String(destChar)))
                    sourceIndex += 1
                    destIndex += 1
                }
            } else if sourceIndex < source.count {
                // Only source characters left - delete them
                operations.append(.delete(1))
                sourceIndex += 1
            } else if destIndex < destination.count {
                // Only destination characters left - insert them
                let destChar = destination[destination.index(destination.startIndex, offsetBy: destIndex)]
                operations.append(.insert(String(destChar)))
                destIndex += 1
            } else {
                break
            }
        }
        
        // Consolidate consecutive operations of the same type
        return consolidateOperations(operations)
    }
    
    /// Consolidate consecutive operations of the same type for efficiency
    @_optimize(speed)
    private static func consolidateOperations(_ operations: [DiffOperation]) -> [DiffOperation] {
        guard !operations.isEmpty else { return [] }
        
        var consolidated: [DiffOperation] = []
        var currentOp = operations[0]
        
        for i in 1..<operations.count {
            let nextOp = operations[i]
            
            switch (currentOp, nextOp) {
            case (.retain(let count1), .retain(let count2)):
                currentOp = .retain(count1 + count2)
            case (.delete(let count1), .delete(let count2)):
                currentOp = .delete(count1 + count2)
            case (.insert(let text1), .insert(let text2)):
                currentOp = .insert(text1 + text2)
            default:
                consolidated.append(currentOp)
                currentOp = nextOp
            }
        }
        
        consolidated.append(currentOp)
        return consolidated
    }
    
    /// Example usage method
    @_optimize(speed)
    public static func createDiffFromCollectionDifference(
        source: String,
        destination: String
    ) -> DiffResult {
        let difference = destination.difference(from: source)
        let operations = convertStringDifference(difference, source: source, destination: destination)
        return DiffResult(operations: operations)
    }
} 