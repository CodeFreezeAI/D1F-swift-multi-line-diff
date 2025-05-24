import Foundation
import MultiLineDiff

/// Demonstrates the enhanced truncated diff functionality with dual context matching
func demonstrateEnhancedTruncatedDiff() -> Bool {
    print("\n🔍 Enhanced Truncated Diff Demonstration")
    print("========================================\n")

    // Full document with repeated similar sections that could cause false matches
    let fullDocument = """
    # Documentation

    ## Setup Instructions
    Please follow these setup steps carefully.
    This is important for the installation.

    ## Configuration Settings  
    Please follow these setup steps carefully.
    This configuration is essential for operation.

    ## Advanced Configuration
    Please follow these setup steps carefully. 
    This advanced section covers complex scenarios.

    ## Conclusion
    Final notes and recommendations.
    """

    // Truncated section (middle part) - note the repeated "Please follow these setup steps carefully"
    let truncatedOriginal = """
    ## Configuration Settings  
    Please follow these setup steps carefully.
    This configuration is essential for operation.
    """

    // Modified version of the truncated section
    let truncatedModified = """
    ## Configuration Settings  
    Please follow these UPDATED setup steps carefully.
    This configuration is CRITICAL for operation.
    """

    print("📄 Full Document:")
    print(fullDocument)
    print("\n📝 Truncated Section (original):")
    print(truncatedOriginal)
    print("\n✏️  Truncated Section (modified):")
    print(truncatedModified)

    // Create diff with enhanced metadata that includes both contexts
    let diff = MultiLineDiff.createDiff(
        source: truncatedOriginal,
        destination: truncatedModified,
        algorithm: .todd,
        includeMetadata: true,
        sourceStartLine: 5  // Approximate line number
    )

    print("\n🧩 Diff Metadata:")
    if let metadata = diff.metadata {
        print("  Preceding Context: '\(metadata.precedingContext ?? "None")'")
        print("  Following Context: '\(metadata.followingContext ?? "None")'")
        print("  Algorithm Used: \(metadata.algorithmUsed?.rawValue ?? "Unknown")")
        print("  Source Lines: \(metadata.sourceTotalLines ?? 0)")
    }

    print("\n🔧 Diff Operations:")
    for (index, operation) in diff.operations.enumerated() {
        print("  \(index + 1). \(operation.description)")
    }

    // Apply the truncated diff to the full document
    // The enhanced algorithm should find the correct section using both contexts
    do {
        let result = try MultiLineDiff.applyDiff(
            to: fullDocument,
            diff: diff,
            allowTruncatedSource: true
        )
        
        print("\n✅ Result after applying truncated diff to full document:")
        print(result)
        
        // Verify the correct section was modified
        let expectedResult = """
        # Documentation

        ## Setup Instructions
        Please follow these setup steps carefully.
        This is important for the installation.

        ## Configuration Settings  
        Please follow these UPDATED setup steps carefully.
        This configuration is CRITICAL for operation.

        ## Advanced Configuration
        Please follow these setup steps carefully. 
        This advanced section covers complex scenarios.

        ## Conclusion
        Final notes and recommendations.
        """
        
        if result == expectedResult {
            print("\n🎉 SUCCESS: Enhanced dual context matching correctly identified and modified the right section!")
            print("\n📊 Key Enhancement Benefits:")
            print("• Preceding Context: Helps locate the section start")
            print("• Following Context: Validates section boundaries and prevents false matches")
            print("• Confidence Scoring: Ensures the best matching section is selected")
            print("• Robust Matching: Handles documents with repeated similar content")
            return true
        } else {
            print("\n❌ FAILED: Section matching didn't work as expected")
            print("Expected vs Actual difference detected")
            return false
        }
        
    } catch {
        print("\n❌ Error applying diff: \(error)")
        return false
    }
} 