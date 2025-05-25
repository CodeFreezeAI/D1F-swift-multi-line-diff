//
//  ThreeWayComparisonTests.swift
//  MultiLineDiffTests
//
//  Created by Todd Bruss on 5/24/25.
//

import Testing
import Foundation
@testable import MultiLineDiff

struct ThreeWayComparisonTests {
    
    @Test("Brus vs Todd vs Myers - Comprehensive Comparison")
    func compareAllThreeAlgorithms() throws {
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
        
        print("🔬 Three-Way Algorithm Comparison")
        print("Source length: \(source.count) characters")
        print("Destination length: \(destination.count) characters")
        print("Source lines: \(source.split(separator: "\n").count)")
        print("Destination lines: \(destination.split(separator: "\n").count)")
        print()
        
        // Test Brus Algorithm
        let brusResult = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .brus)
        print("🟦 Brus Algorithm (Character-based, O(n)):")
        print("   Operations count: \(brusResult.operations.count)")
        print("   Algorithm used: \(brusResult.metadata?.algorithmUsed ?? .brus)")
        print("   Operations:")
        for (i, op) in brusResult.operations.enumerated() {
            print("     \(i): \(op.description)")
        }
        
        // Test Todd Algorithm  
        let toddResult = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .todd)
        print("\n🟩 Todd Algorithm (Line-based, O(n log n)):")
        print("   Operations count: \(toddResult.operations.count)")
        print("   Algorithm used: \(toddResult.metadata?.algorithmUsed ?? .todd)")
        print("   Operations:")
        for (i, op) in toddResult.operations.enumerated() {
            print("     \(i): \(op.description)")
        }
        
        // Test Myers (CollectionDifference) Algorithm
        let myersResult = MultiLineDiff.createDiffFromCollectionDifference(source: source, destination: destination)
        print("\n🟨 Myers Algorithm (Character-based CollectionDifference):")
        print("   Operations count: \(myersResult.operations.count)")
        print("   Operations:")
        for (i, op) in myersResult.operations.enumerated() {
            print("     \(i): \(op.description)")
        }
        
        // Verify all produce correct results
        let appliedBrus = try MultiLineDiff.applyDiff(to: source, diff: brusResult)
        let appliedTodd = try MultiLineDiff.applyDiff(to: source, diff: toddResult)
        let appliedMyers = try MultiLineDiff.applyDiff(to: source, diff: myersResult)
        
        #expect(appliedBrus == destination, "Brus should produce correct result")
        #expect(appliedTodd == destination, "Todd should produce correct result")
        #expect(appliedMyers == destination, "Myers should produce correct result")
        
        print("\n✅ All algorithms produce correct results!")
        
        // Performance comparison
        let iterations = 100
        
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
        
        print("\n🏁 Performance Comparison (\(iterations) iterations):")
        print("   Brus:  \(String(format: "%.2f", brusTime * 1000))ms total (\(String(format: "%.3f", (brusTime * 1000) / Double(iterations)))ms per op)")
        print("   Todd:  \(String(format: "%.2f", toddTime * 1000))ms total (\(String(format: "%.3f", (toddTime * 1000) / Double(iterations)))ms per op)")
        print("   Myers: \(String(format: "%.2f", myersTime * 1000))ms total (\(String(format: "%.3f", (myersTime * 1000) / Double(iterations)))ms per op)")
        
        // Calculate relative speeds
        let fastest = min(brusTime, toddTime, myersTime)
        print("\n📊 Relative Speed (1.0 = fastest):")
        print("   Brus:  \(String(format: "%.2f", brusTime / fastest))x")
        print("   Todd:  \(String(format: "%.2f", toddTime / fastest))x")
        print("   Myers: \(String(format: "%.2f", myersTime / fastest))x")
        
        print("\n📈 Operation Count Comparison:")
        print("   Brus:  \(brusResult.operations.count) operations")
        print("   Todd:  \(toddResult.operations.count) operations")
        print("   Myers: \(myersResult.operations.count) operations")
    }
    
    @Test("Small string comparison")
    func compareSmallStrings() throws {
        let source = "Hello World"
        let destination = "Hello Swift World"
        
        print("🔬 Small String Comparison")
        print("Source: '\(source)'")
        print("Destination: '\(destination)'")
        print()
        
        let brusResult = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .brus)
        let toddResult = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .todd)
        let myersResult = MultiLineDiff.createDiffFromCollectionDifference(source: source, destination: destination)
        
        print("🟦 Brus: \(brusResult.operations)")
        print("🟩 Todd: \(toddResult.operations)")
        print("🟨 Myers: \(myersResult.operations)")
        
        // Verify correctness
        let appliedBrus = try MultiLineDiff.applyDiff(to: source, diff: brusResult)
        let appliedTodd = try MultiLineDiff.applyDiff(to: source, diff: toddResult)
        let appliedMyers = try MultiLineDiff.applyDiff(to: source, diff: myersResult)
        
        #expect(appliedBrus == destination, "Brus should work on small strings")
        #expect(appliedTodd == destination, "Todd should work on small strings")
        #expect(appliedMyers == destination, "Myers should work on small strings")
        
        print("✅ All correct!")
    }
    
    @Test("Large string performance test")
    func compareLargeStrings() throws {
        // Generate larger test content
        let baseCode = """
        import Foundation
        
        class DataProcessor {
            private var cache: [String: Any] = [:]
            private let queue = DispatchQueue(label: "processor")
            
            func processData(_ input: String) -> String {
                return queue.sync {
                    if let cached = cache[input] as? String {
                        return cached
                    }
                    
                    let processed = input.uppercased()
                        .replacingOccurrences(of: " ", with: "_")
                        .replacingOccurrences(of: "\\n", with: "\\\\n")
                    
                    cache[input] = processed
                    return processed
                }
            }
            
            func clearCache() {
                cache.removeAll()
            }
        }
        """
        
        let source = String(repeating: baseCode, count: 5)
        let destination = source
            .replacingOccurrences(of: "DataProcessor", with: "FastProcessor")
            .replacingOccurrences(of: "processData", with: "fastProcess")
            .replacingOccurrences(of: "uppercased", with: "lowercased")
            .replacingOccurrences(of: "clearCache", with: "resetCache")
        
        print("🔬 Large String Performance Test")
        print("Source length: \(source.count) characters")
        print("Destination length: \(destination.count) characters")
        print("Source lines: \(source.split(separator: "\n").count)")
        print()
        
        let iterations = 10
        
        // Performance test
        let brusStart = Date()
        for _ in 0..<iterations {
            _ = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .brus)
        }
        let brusTime = Date().timeIntervalSince(brusStart)
        
        let toddStart = Date()
        for _ in 0..<iterations {
            _ = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .todd)
        }
        let toddTime = Date().timeIntervalSince(toddStart)
        
        let myersStart = Date()
        for _ in 0..<iterations {
            _ = MultiLineDiff.createDiffFromCollectionDifference(source: source, destination: destination)
        }
        let myersTime = Date().timeIntervalSince(myersStart)
        
        print("🏁 Large String Performance (\(iterations) iterations):")
        print("   Brus:  \(String(format: "%.1f", brusTime * 1000))ms (\(String(format: "%.1f", (brusTime * 1000) / Double(iterations)))ms per op)")
        print("   Todd:  \(String(format: "%.1f", toddTime * 1000))ms (\(String(format: "%.1f", (toddTime * 1000) / Double(iterations)))ms per op)")
        print("   Myers: \(String(format: "%.1f", myersTime * 1000))ms (\(String(format: "%.1f", (myersTime * 1000) / Double(iterations)))ms per op)")
        
        // Test one result for correctness
        let testResult = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .todd)
        let applied = try MultiLineDiff.applyDiff(to: source, diff: testResult)
        #expect(applied == destination, "Large string diff should be correct")
        
        print("✅ Large string test passed!")
    }
} 