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
    
    @Test("All Five Algorithms - Five-Way Comparison")
    func compareAllFiveAlgorithms() throws {
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
        
        print("🔬 Five-Way Algorithm Comparison")
        print("Source length: \(source.count) characters")
        print("Destination length: \(destination.count) characters")
        print()
        
        // Test all five algorithms
        let brusResult = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .zoom)
        let toddResult = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .todd)
        let sodaResult = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .flash)
        let lineResult = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .arrow)
        let drewResult = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .drew)
        
        print("🟦 Brus: \(brusResult.operations.count) operations")
        print("🟩 Todd: \(toddResult.operations.count) operations")
        print("🥤 Soda: \(sodaResult.operations.count) operations")
        print("📏 Line: \(lineResult.operations.count) operations")
        print("🎨 Drew: \(drewResult.operations.count) operations")
        print()
        
        // Verify all produce correct results
        let appliedBrus = try MultiLineDiff.applyDiff(to: source, diff: brusResult)
        let appliedTodd = try MultiLineDiff.applyDiff(to: source, diff: toddResult)
        let appliedSoda = try MultiLineDiff.applyDiff(to: source, diff: sodaResult)
        let appliedLine = try MultiLineDiff.applyDiff(to: source, diff: lineResult)
        let appliedDrew = try MultiLineDiff.applyDiff(to: source, diff: drewResult)
        
        #expect(appliedBrus == destination, "Brus should produce correct result")
        #expect(appliedTodd == destination, "Todd should produce correct result")
        #expect(appliedSoda == destination, "Soda should produce correct result")
        #expect(appliedLine == destination, "Line should produce correct result")
        #expect(appliedDrew == destination, "Drew should produce correct result")
        
        print("✅ All algorithms produce correct results!")
        print()
        
        // Performance comparison
        let iterations = 1000
        
        // Brus performance
        let brusStart = Date()
        for _ in 0..<iterations {
            _ = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .zoom)
        }
        let brusTime = Date().timeIntervalSince(brusStart)
        
        // Todd performance
        let toddStart = Date()
        for _ in 0..<iterations {
            _ = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .todd)
        }
        let toddTime = Date().timeIntervalSince(toddStart)
        
        // Soda performance
        let sodaStart = Date()
        for _ in 0..<iterations {
            _ = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .flash)
        }
        let sodaTime = Date().timeIntervalSince(sodaStart)
        
        // Line performance
        let lineStart = Date()
        for _ in 0..<iterations {
            _ = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .arrow)
        }
        let lineTime = Date().timeIntervalSince(lineStart)
        
        // Drew performance
        let drewStart = Date()
        for _ in 0..<iterations {
            _ = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .drew)
        }
        let drewTime = Date().timeIntervalSince(drewStart)
        
        print("🏁 Performance Comparison (\(iterations) iterations):")
        print("   Brus: \(String(format: "%6.2f", brusTime * 1000))ms (\(String(format: "%.4f", (brusTime * 1000) / Double(iterations)))ms per op)")
        print("   Todd: \(String(format: "%6.2f", toddTime * 1000))ms (\(String(format: "%.4f", (toddTime * 1000) / Double(iterations)))ms per op)")
        print("   Soda: \(String(format: "%6.2f", sodaTime * 1000))ms (\(String(format: "%.4f", (sodaTime * 1000) / Double(iterations)))ms per op)")
        print("   Line: \(String(format: "%6.2f", lineTime * 1000))ms (\(String(format: "%.4f", (lineTime * 1000) / Double(iterations)))ms per op)")
        print("   Drew: \(String(format: "%6.2f", drewTime * 1000))ms (\(String(format: "%.4f", (drewTime * 1000) / Double(iterations)))ms per op)")
        
        // Calculate relative speeds
        let fastest = min(brusTime, toddTime, sodaTime, lineTime, drewTime)
        print("\n📊 Relative Speed (1.0 = fastest):")
        print("   Brus: \(String(format: "%.2f", brusTime / fastest))x")
        print("   Todd: \(String(format: "%.2f", toddTime / fastest))x")
        print("   Soda: \(String(format: "%.2f", sodaTime / fastest))x")
        print("   Line: \(String(format: "%.2f", lineTime / fastest))x")
        print("   Drew: \(String(format: "%.2f", drewTime / fastest))x")
        
        print("\n📈 Operation Count Comparison:")
        print("   Brus: \(brusResult.operations.count) operations")
        print("   Todd: \(toddResult.operations.count) operations")
        print("   Soda: \(sodaResult.operations.count) operations")
        print("   Line: \(lineResult.operations.count) operations")
        print("   Drew: \(drewResult.operations.count) operations")
        
        // Show the actual operations for comparison
        print("\n🔍 Operation Details:")
        print("🟦 Brus: \(formatOperations(brusResult))")
        print("🟩 Todd: \(formatOperations(toddResult))")
        print("🥤 Soda: \(formatOperations(sodaResult))")
        print("📏 Line: \(formatOperations(lineResult))")
        print("🎨 Drew: \(formatOperations(drewResult))")
    }
    
    @Test("Simple string test")
    func compareSimpleStrings() throws {
        let source = "Hello World"
        let destination = "Hello Swift World"
        
        print("🔬 Simple String Test")
        print("Source: '\(source)'")
        print("Destination: '\(destination)'")
        print()
        
        let brusResult = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .zoom)
        let toddResult = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .todd)
        let sodaResult = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .flash)
        let lineResult = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .arrow)
        let drewResult = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .drew)
        
        print("🟦 Brus: \(formatOperations(brusResult))")
        print("🟩 Todd: \(formatOperations(toddResult))")
        print("🥤 Soda: \(formatOperations(sodaResult))")
        print("📏 Line: \(formatOperations(lineResult))")
        print("🎨 Drew: \(formatOperations(drewResult))")
        
        // Verify correctness
        let appliedBrus = try MultiLineDiff.applyDiff(to: source, diff: brusResult)
        let appliedTodd = try MultiLineDiff.applyDiff(to: source, diff: toddResult)
        let appliedSoda = try MultiLineDiff.applyDiff(to: source, diff: sodaResult)
        let appliedLine = try MultiLineDiff.applyDiff(to: source, diff: lineResult)
        let appliedDrew = try MultiLineDiff.applyDiff(to: source, diff: drewResult)
        
        #expect(appliedBrus == destination, "Brus should work")
        #expect(appliedTodd == destination, "Todd should work")
        #expect(appliedSoda == destination, "Soda should work")
        #expect(appliedLine == destination, "Line should work")
        #expect(appliedDrew == destination, "Drew should work")
        
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
            ("Brus", { MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .zoom) }),
            ("Todd", { MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .todd) }),
            ("Soda", { MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .flash) }),
            ("Line", { MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .arrow) }),
            ("Drew", { MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .drew) })
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