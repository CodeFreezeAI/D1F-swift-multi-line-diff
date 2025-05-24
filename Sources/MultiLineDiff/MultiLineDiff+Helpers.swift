//
//  MultiLineDiff+Helpers.swift
//  MultiLineDiff
//
//  Created by Todd Bruss on 5/24/25.
//

import Foundation

// MARK: - Helper Functions
extension MultiLineDiff {
    /// Find the best matching section in a document using context matching
    internal static func findBestMatchingSection(
        fullLines: [Substring],
        metadata: DiffMetadata,
        sourceLineCount: Int
    ) -> Range<Int>? {
        guard let precedingContext = metadata.precedingContext else { return nil }
        let followingContext = metadata.followingContext
        
        var bestMatchIndex: Int?
        var bestMatchConfidence = 0.0
        
        // Search through the document looking for the best matching section
        for startIndex in 0..<fullLines.count {
            let endIndex = Swift.min(fullLines.count, startIndex + sourceLineCount)
            
            // Extract potential section
            let sectionLines = Array(fullLines[startIndex..<endIndex])
            let sectionText = sectionLines.joined(separator: "\n")
            
            // Calculate confidence score based on both contexts
            let confidence = calculateSectionMatchConfidence(
                sectionText: sectionText,
                precedingContext: precedingContext,
                followingContext: followingContext,
                fullLines: fullLines,
                sectionStartIndex: startIndex,
                sectionEndIndex: endIndex
            )
            
            // Update best match if this section has higher confidence
            if confidence > bestMatchConfidence {
                bestMatchConfidence = confidence
                bestMatchIndex = startIndex
            }
            
            // If we find a very high confidence match, use it immediately
            if confidence > 0.85 {
                break
            }
        }
        
        // Require minimum confidence to proceed
        guard let startIndex = bestMatchIndex, bestMatchConfidence > 0.3 else {
            return nil // Couldn't find a sufficiently confident match
        }
        
        let endIndex = Swift.min(fullLines.count, startIndex + sourceLineCount)
        return startIndex..<endIndex
    }
    
    /// Reconstruct document with modified section
    internal static func reconstructDocumentWithModifiedSection(
        fullLines: [Substring],
        sectionRange: Range<Int>,
        operations: [DiffOperation]
    ) throws -> String {
        // Extract the section to be modified
        let sectionLines = Array(fullLines[sectionRange])
        let sectionText = sectionLines.joined(separator: "\n")
        
        // Apply the diff to the section
        let modifiedSection = try processOperationsOnSource(
            source: sectionText,
            operations: operations,
            allowTruncatedSource: true
        )
        
        // Reconstruct the full document with the modified section
        var resultLines = Array(fullLines)
        let modifiedLines = modifiedSection.split(separator: "\n", omittingEmptySubsequences: false)
        
        // Replace the original section lines with modified lines
        resultLines.replaceSubrange(sectionRange, with: modifiedLines)
        
        return resultLines.map(String.init).joined(separator: "\n")
    }
    
    /// Perform smart verification of diff application result
    internal static func performSmartVerification(
        source: String,
        result: String,
        diff: DiffResult
    ) throws {
        // Smart verification: only verify if we're applying to the same type of source
        if let metadata = diff.metadata,
           let expectedDestination = metadata.destinationContent,
           let storedSource = metadata.sourceContent {
            
            // Only verify if we're applying to the same source that created the diff
            // or if we're applying to a truncated source that matches the stored source
            let shouldVerify = (source == storedSource) ||
            (storedSource.contains(source) && storedSource != source)
            
            if shouldVerify && result != expectedDestination {
                throw DiffError.verificationFailed(
                    expected: expectedDestination,
                    actual: result
                )
            }
        }
    }
    
    /// Decode an encoded diff based on the specified encoding format
    internal static func decodeEncodedDiff(
        encodedDiff: Any,
        encoding: DiffEncoding
    ) throws -> DiffResult {
        switch encoding {
        case .base64:
            guard let base64String = encodedDiff as? String else {
                throw DiffError.decodingFailed
            }
            return try diffFromBase64(base64String)
        case .jsonString:
            guard let jsonString = encodedDiff as? String else {
                throw DiffError.decodingFailed
            }
            return try decodeDiffFromJSONString(jsonString)
        case .jsonData:
            guard let jsonData = encodedDiff as? Data else {
                throw DiffError.decodingFailed
            }
            return try decodeDiffFromJSON(jsonData)
        }
    }
    
    /// Determine whether to allow truncated source handling based on metadata and source verification
    internal static func shouldAllowTruncatedSource(for source: String, diff: DiffResult) -> Bool {
        // First, check if we can verify with stored source content
        if let storedSource = diff.metadata?.sourceContent {
            return DiffMetadata.requiresTruncatedHandling(
                providedSource: source,
                storedSource: storedSource
            )
        } else if let applicationType = diff.metadata?.applicationType {
            // Fall back to explicit application type
            return (applicationType == .requiresTruncatedSource)
        } else {
            // Fall back to legacy heuristics if no explicit type or stored source
            return (diff.metadata?.sourceStartLine ?? 0) > 0 ||
            diff.metadata?.precedingContext != nil
        }
    }
    
}

