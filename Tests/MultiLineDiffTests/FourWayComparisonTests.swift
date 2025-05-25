//
//  FourWayComparisonTests.swift
//  MultiLineDiffTests
//
//  Created by Todd Bruss on 5/24/25.
//

import Testing
import Foundation
@testable import MultiLineDiff

struct FourWayComparisonTests {
    
    @Test("Brus vs Todd vs Myers vs Swift Native - Ultimate Comparison")
    func compareAllFourAlgorithms() throws {
        let source = """
        struct User {
            let id: Int
            let name: String
            let email: String
            
            func validate() -> Bool {
                return !name.isEmpty && email.contains("@")
            }
        }
        """
        
        let destination = """
        struct User {
            let id: UUID
            let fullName: String
            let emailAddress: String
            
            func isValid() -> Bool {
                return !fullName.isEmpty && emailAddress.contains("@")
            }
        }
        """
        
        print("🔬 Four-Way Algorithm Comparison")
        print("Source length: \(source.count) characters")
        print("Destination length: \(destination.count) characters")
        print()
        
        // Test all four algorithms
        let brusResult = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .brus)
        let toddResult = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .todd)
        let myersResult = MultiLineDiff.createDiffFromCollectionDifference(source: source, destination: destination)
        let swiftNativeResult = MultiLineDiff.createDiffUsingSwiftNativeMethods(source: source, destination: destination)
        
        print("🟦 Brus: \(brusResult.operations.count) operations")
        print("🟩 Todd: \(toddResult.operations.count) operations")
        print("🟨 Myers: \(myersResult.operations.count) operations")
        print("🟪 Swift Native: \(swiftNativeResult.operations.count) operations")
        print()
        
        // Verify all produce correct results
        let appliedBrus = try MultiLineDiff.applyDiff(to: source, diff: brusResult)
        let appliedTodd = try MultiLineDiff.applyDiff(to: source, diff: toddResult)
        let appliedMyers = try MultiLineDiff.applyDiff(to: source, diff: myersResult)
        let appliedSwiftNative = try MultiLineDiff.applyDiff(to: source, diff: swiftNativeResult)
        
        #expect(appliedBrus == destination, "Brus should produce correct result")
        #expect(appliedTodd == destination, "Todd should produce correct result")
        #expect(appliedMyers == destination, "Myers should produce correct result")
        #expect(appliedSwiftNative == destination, "Swift Native should produce correct result")
        
        print("✅ All algorithms produce correct results!")
        print()
        
        // Performance comparison
        let iterations = 1000
        
        // Brus performance
        let brusStart = Date()
        for _ in 0..<iterations {
            _ = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .brus)
        }
        let brusTime = Date().timeIntervalSince(brusStart)
        
        // Todd performance
        let toddStart = Date()
        for _ in 0..<iterations {
            _ = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .todd)
        }
        let toddTime = Date().timeIntervalSince(toddStart)
        
        // Myers performance
        let myersStart = Date()
        for _ in 0..<iterations {
            _ = MultiLineDiff.createDiffFromCollectionDifference(source: source, destination: destination)
        }
        let myersTime = Date().timeIntervalSince(myersStart)
        
        // Swift Native performance
        let swiftNativeStart = Date()
        for _ in 0..<iterations {
            _ = MultiLineDiff.createDiffUsingSwiftNativeMethods(source: source, destination: destination)
        }
        let swiftNativeTime = Date().timeIntervalSince(swiftNativeStart)
        
        print("🏁 Performance Comparison (\(iterations) iterations):")
        print("   Brus:        \(String(format: "%6.2f", brusTime * 1000))ms (\(String(format: "%.4f", (brusTime * 1000) / Double(iterations)))ms per op)")
        print("   Todd:        \(String(format: "%6.2f", toddTime * 1000))ms (\(String(format: "%.4f", (toddTime * 1000) / Double(iterations)))ms per op)")
        print("   Myers:       \(String(format: "%6.2f", myersTime * 1000))ms (\(String(format: "%.4f", (myersTime * 1000) / Double(iterations)))ms per op)")
        print("   Swift Native:\(String(format: "%6.2f", swiftNativeTime * 1000))ms (\(String(format: "%.4f", (swiftNativeTime * 1000) / Double(iterations)))ms per op)")
        
        // Calculate relative speeds
        let fastest = min(brusTime, toddTime, myersTime, swiftNativeTime)
        print("\n📊 Relative Speed (1.0 = fastest):")
        print("   Brus:        \(String(format: "%.2f", brusTime / fastest))x")
        print("   Todd:        \(String(format: "%.2f", toddTime / fastest))x")
        print("   Myers:       \(String(format: "%.2f", myersTime / fastest))x")
        print("   Swift Native:\(String(format: "%.2f", swiftNativeTime / fastest))x")
        
        print("\n📈 Operation Count Comparison:")
        print("   Brus:        \(brusResult.operations.count) operations")
        print("   Todd:        \(toddResult.operations.count) operations")
        print("   Myers:       \(myersResult.operations.count) operations")
        print("   Swift Native:\(swiftNativeResult.operations.count) operations")
        
        // Show the actual operations for comparison
        print("\n🔍 Operation Details:")
        print("🟦 Brus: \(brusResult.operations)")
        print("🟩 Todd: \(toddResult.operations)")
        print("🟨 Myers: \(myersResult.operations)")
        print("🟪 Swift Native: \(swiftNativeResult.operations)")
    }
    
    @Test("Simple string test")
    func compareSimpleStrings() throws {
        let source = "Hello World"
        let destination = "Hello Swift World"
        
        print("🔬 Simple String Test")
        print("Source: '\(source)'")
        print("Destination: '\(destination)'")
        print()
        
        let brusResult = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .brus)
        let toddResult = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .todd)
        let myersResult = MultiLineDiff.createDiffFromCollectionDifference(source: source, destination: destination)
        let swiftNativeResult = MultiLineDiff.createDiffUsingSwiftNativeMethods(source: source, destination: destination)
        
        print("🟦 Brus:        \(brusResult.operations)")
        print("🟩 Todd:        \(toddResult.operations)")
        print("🟨 Myers:       \(myersResult.operations)")
        print("🟪 Swift Native:\(swiftNativeResult.operations)")
        
        // Verify correctness
        let appliedBrus = try MultiLineDiff.applyDiff(to: source, diff: brusResult)
        let appliedTodd = try MultiLineDiff.applyDiff(to: source, diff: toddResult)
        let appliedMyers = try MultiLineDiff.applyDiff(to: source, diff: myersResult)
        let appliedSwiftNative = try MultiLineDiff.applyDiff(to: source, diff: swiftNativeResult)
        
        #expect(appliedBrus == destination, "Brus should work")
        #expect(appliedTodd == destination, "Todd should work")
        #expect(appliedMyers == destination, "Myers should work")
        #expect(appliedSwiftNative == destination, "Swift Native should work")
        
        print("✅ All correct!")
    }
    
    @Test("Speed test on large strings")
    func speedTestLargeStrings() throws {
        // Generate large test strings
        let baseText = "The quick brown fox jumps over the lazy dog. "
        let source = String(repeating: baseText, count: 1000) // ~45KB
        let destination = source.replacingOccurrences(of: "quick brown", with: "slow red")
            .replacingOccurrences(of: "lazy dog", with: "active cat")
        
        print("🚀 Large String Speed Test")
        print("Source length: \(source.count) characters")
        print("Destination length: \(destination.count) characters")
        print()
        
        let iterations = 10
        
        // Test each algorithm
        let algorithms: [(name: String, test: () -> DiffResult)] = [
            ("Brus", { MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .brus) }),
            ("Todd", { MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .todd) }),
            ("Myers", { MultiLineDiff.createDiffFromCollectionDifference(source: source, destination: destination) }),
            ("Swift Native", { MultiLineDiff.createDiffUsingSwiftNativeMethods(source: source, destination: destination) })
        ]
        
        for (name, test) in algorithms {
            let start = Date()
            var result: DiffResult?
            for _ in 0..<iterations {
                result = test()
            }
            let time = Date().timeIntervalSince(start)
            
            // Verify correctness
            if let result = result {
                let applied = try MultiLineDiff.applyDiff(to: source, diff: result)
                let isCorrect = applied == destination
                print("   \(name): \(String(format: "%6.1f", time * 1000))ms (\(String(format: "%.1f", (time * 1000) / Double(iterations)))ms per op) - \(result.operations.count) ops - \(isCorrect ? "✅" : "❌")")
            }
        }
    }
} 