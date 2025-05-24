//
//  MultiLineStringExt.swift
//  MultiLineDiff
//
//  Created by Todd Bruss on 5/24/25.
//

/// Swift 6.1 Enhanced String Processing Utilities
public extension String {
    func truncated(to length: Int) -> String {
        count > length ? prefix(length) + "..." : self
    }
    
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
