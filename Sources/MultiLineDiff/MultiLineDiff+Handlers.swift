//
//  MultiLineDiff+Handlers.swift
//  MultiLineDiff
//
//  Created by Todd Bruss on 5/24/25.
//

extension MultiLineDiff {
    
    /// Enhanced retain operation handling
    @_optimize(speed)
    internal static func handleRetainOperation(
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
    internal static func handleDeleteOperation(
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
    
    
    /// Handle empty string cases for both diff algorithms
    internal static func handleEmptyStrings(source: String, destination: String) -> DiffResult? {
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
}
