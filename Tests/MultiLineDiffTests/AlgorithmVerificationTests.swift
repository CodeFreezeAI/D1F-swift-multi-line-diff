//
//  AlgorithmVerificationTests.swift
//  MultiLineDiffTests
//
//  Created by Todd Bruss on 5/24/25.
//

import Testing
import Foundation
@testable import MultiLineDiff

struct AlgorithmVerificationTests {
    
    @Test("Verify Todd vs Brus algorithm selection")
    func verifyAlgorithmSelection() throws {
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
        
        // Explicitly test Brus algorithm
        let brusResult = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .brus)
        print("🔍 Brus Algorithm:")
        print("   Operations count: \(brusResult.operations.count)")
        print("   Operations: \(brusResult.operations)")
        print("   Algorithm used: \(brusResult.metadata?.algorithmUsed ?? .brus)")
        
        // Explicitly test Todd algorithm
        let toddResult = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .todd)
        print("\n🔍 Todd Algorithm:")
        print("   Operations count: \(toddResult.operations.count)")
        print("   Operations: \(toddResult.operations)")
        print("   Algorithm used: \(toddResult.metadata?.algorithmUsed ?? .todd)")
        
        // Test default algorithm selection
        let defaultResult = MultiLineDiff.createDiff(source: source, destination: destination)
        print("\n🔍 Default Algorithm:")
        print("   Operations count: \(defaultResult.operations.count)")
        print("   Operations: \(defaultResult.operations)")
        print("   Algorithm used: \(defaultResult.metadata?.algorithmUsed ?? .brus)")
        
        // Verify they produce correct results
        let applied1 = try MultiLineDiff.applyDiff(to: source, diff: brusResult)
        let applied2 = try MultiLineDiff.applyDiff(to: source, diff: toddResult)
        let applied3 = try MultiLineDiff.applyDiff(to: source, diff: defaultResult)
        
        #expect(applied1 == destination, "Brus should produce correct result")
        #expect(applied2 == destination, "Todd should produce correct result")
        #expect(applied3 == destination, "Default should produce correct result")
        
        // Todd should typically have more operations than Brus for multi-line text
        print("\n📊 Comparison:")
        print("   Brus operations: \(brusResult.operations.count)")
        print("   Todd operations: \(toddResult.operations.count)")
        print("   Todd should have more operations for line-aware diffing")
        
        // Check if Todd is actually producing more operations
        if toddResult.operations.count <= brusResult.operations.count {
            print("   ⚠️  WARNING: Todd has same or fewer operations than Brus!")
            print("   This suggests Todd might not be running or is falling back to Brus")
        }
    }
} 