//
//  DiffAlgorithm.swift
//  MultiLineDiff
//
//  Created by Todd Bruss on 5/24/25.
//


/// Represents the available diff algorithms
@frozen public enum DiffAlgorithm: String, Sendable, Codable {
    /// Simple, fast diff algorithm with O(n) time complexity
    case brus
    /// Detailed, semantic diff algorithm with O(n log n) time complexity
    case todd
    /// Swift native prefix/suffix algorithm - fastest for most cases
    case soda
    /// Swift native line-aware algorithm - fast with detailed line operations
    case line
    /// Swift native line-aware with CollectionDifference - Todd-compatible but faster
    case drew
}
