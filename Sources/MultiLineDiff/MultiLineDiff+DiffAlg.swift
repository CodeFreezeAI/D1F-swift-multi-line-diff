//
//  Untitled.swift
//  MultiLineDiff
//
//  Created by Todd Bruss on 5/24/25.
//

extension MultiLineDiff {
    // MARK: - Enhanced Algorithm Selection & Utility Methods
    
    /// Enhanced method to check if Brus algorithm is suitable using Swift 6.1 optimizations
    @_optimize(speed)
    internal static func isBrusSuitable(source: String, destination: String) -> Bool {
        return DiffAlgorithmCore.AlgorithmSelector.selectOptimalAlgorithm(source: source, destination: destination) == .brus
    }
    
    /// Enhanced algorithm selection suggestion using Swift 6.1 features
    @_optimize(speed)
    internal static func suggestDiffAlgorithm(source: String, destination: String) -> String {
        switch DiffAlgorithmCore.AlgorithmSelector.selectOptimalAlgorithm(source: source, destination: destination) {
        case .brus: return "Brus"
        case .todd: return "Todd"
        }
    }
    
}
