//
//  PerformanceBenchmarkTests.swift
//  MultiLineDiffTests
//
//  Created by Todd Bruss on 5/24/25.
//

import Testing
import Foundation
@testable import MultiLineDiff

struct PerformanceBenchmarkTests {
    
    @Test("Performance benchmark - Small strings")
    func benchmarkSmallStrings() throws {
        let iterations = 1000
        let source = "Hello World"
        let destination = "Hello Swift World"
        
        // Warm up
        for _ in 0..<10 {
            _ = MultiLineDiff.createDiffFromCollectionDifference(source: source, destination: destination)
        }
        
        let start = Date()
        for _ in 0..<iterations {
            _ = MultiLineDiff.createDiffFromCollectionDifference(source: source, destination: destination)
        }
        let time = Date().timeIntervalSince(start)
        
        print("🚀 Small strings (\(iterations) iterations): \(time * 1000)ms total, \((time * 1000) / Double(iterations))ms per operation")
    }
    
    @Test("Performance benchmark - Medium strings")
    func benchmarkMediumStrings() throws {
        let iterations = 100
        let source = """
        func calculateSum(numbers: [Int]) -> Int {
            var total = 0
            for number in numbers {
                total += number
            }
            return total
        }
        """
        
        let destination = """
        func calculateSum(values: [Int]) -> Int {
            var sum = 0
            for value in values {
                sum += value * 2
            }
            return sum
        }
        """
        
        // Warm up
        for _ in 0..<5 {
            _ = MultiLineDiff.createDiffFromCollectionDifference(source: source, destination: destination)
        }
        
        let start = Date()
        for _ in 0..<iterations {
            _ = MultiLineDiff.createDiffFromCollectionDifference(source: source, destination: destination)
        }
        let time = Date().timeIntervalSince(start)
        
        print("🚀 Medium strings (\(iterations) iterations): \(time * 1000)ms total, \((time * 1000) / Double(iterations))ms per operation")
    }
    
    @Test("Performance benchmark - Large strings")
    func benchmarkLargeStrings() throws {
        let iterations = 10
        
        // Generate large strings
        let baseText = """
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
                        .replacingOccurrences(of: "\n", with: "\\n")
                    
                    cache[input] = processed
                    return processed
                }
            }
        }
        """
        
        let source = String(repeating: baseText, count: 10)
        let destination = source.replacingOccurrences(of: "DataProcessor", with: "FastProcessor")
            .replacingOccurrences(of: "processData", with: "fastProcess")
            .replacingOccurrences(of: "uppercased", with: "lowercased")
        
        // Warm up
        for _ in 0..<2 {
            _ = MultiLineDiff.createDiffFromCollectionDifference(source: source, destination: destination)
        }
        
        let start = Date()
        for _ in 0..<iterations {
            _ = MultiLineDiff.createDiffFromCollectionDifference(source: source, destination: destination)
        }
        let time = Date().timeIntervalSince(start)
        
        print("🚀 Large strings (\(iterations) iterations): \(time * 1000)ms total, \((time * 1000) / Double(iterations))ms per operation")
        print("   Source length: \(source.count) characters")
        print("   Destination length: \(destination.count) characters")
    }
    
    @Test("Performance comparison - Optimized vs Todd")
    func compareWithToddAlgorithm() throws {
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
        
        let iterations = 100
        
        // Test optimized converter
        var start = Date()
        for _ in 0..<iterations {
            _ = MultiLineDiff.createDiffFromCollectionDifference(source: source, destination: destination)
        }
        let optimizedTime = Date().timeIntervalSince(start)
        
        // Test Todd algorithm
        start = Date()
        for _ in 0..<iterations {
            _ = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .todd)
        }
        let toddTime = Date().timeIntervalSince(start)
        
        print("🏁 Performance Comparison (\(iterations) iterations):")
        print("   Optimized converter: \(optimizedTime * 1000)ms (\((optimizedTime * 1000) / Double(iterations))ms per op)")
        print("   Todd algorithm: \(toddTime * 1000)ms (\((toddTime * 1000) / Double(iterations))ms per op)")
        print("   Speedup: \(toddTime / optimizedTime)x")
        
        // Verify both produce correct results
        let result1 = MultiLineDiff.createDiffFromCollectionDifference(source: source, destination: destination)
        let result2 = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .todd)
        
        let applied1 = try MultiLineDiff.applyDiff(to: source, diff: result1)
        let applied2 = try MultiLineDiff.applyDiff(to: source, diff: result2)
        
        #expect(applied1 == destination, "Optimized converter should produce correct result")
        #expect(applied2 == destination, "Todd algorithm should produce correct result")
        
        print("   Both algorithms produce correct results: ✅")
    }
} 