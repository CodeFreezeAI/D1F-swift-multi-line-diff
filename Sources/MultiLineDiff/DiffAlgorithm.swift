//
//  DiffAlgorithm.swift
//  MultiLineDiff
//
//  Created by Todd Bruss on 5/24/25.
//

/// Global algorithm names to eliminate hardcoded strings throughout the project
public struct AlgorithmNames {
    public static let zoom = "Zoom"
    public static let todd = "Todd"
    public static let flash = "Flash"
    public static let arrow = "Arrow"
    public static let drew = "Drew"
    
    /// Legacy names for backward compatibility
    public struct Legacy {
        public static let brus = "Brus"
        public static let soda = "Soda"
        public static let line = "Line"
    }
}

/// Represents the available diff algorithms
@frozen public enum DiffAlgorithm: String, Sendable, Codable {
    /// Simple, fast diff algorithm with O(n) time complexity
    case zoom
    /// Detailed, semantic diff algorithm with O(n log n) time complexity
    case todd
    /// Swift native prefix/suffix algorithm - fastest for most cases
    case flash
    /// Swift native line-aware algorithm - fast with detailed line operations
    case arrow
    /// Swift native line-aware with CollectionDifference - Todd-compatible but faster
    case drew
    
    /// Display name for the algorithm
    public var displayName: String {
        switch self {
        case .zoom: return AlgorithmNames.zoom
        case .todd: return AlgorithmNames.todd
        case .flash: return AlgorithmNames.flash
        case .arrow: return AlgorithmNames.arrow
        case .drew: return AlgorithmNames.drew
        }
    }
    
    /// Legacy case mapping for backward compatibility
    public static func from(legacy: String) -> DiffAlgorithm? {
        switch legacy.lowercased() {
        case "brus": return .zoom
        case "soda": return .flash
        case "line": return .arrow
        case "todd": return .todd
        case "drew": return .drew
        default: return nil
        }
    }
}
