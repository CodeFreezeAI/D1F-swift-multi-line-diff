//
//  JSON.swift
//  MultiLineDiff
//
//  Created by Todd Bruss on 5/20/25.
//

import Foundation

extension MultiLineDiff {
    /// Encodes a diff result to JSON data
    /// - Parameters:
    ///   - diff: The diff result to encode
    ///   - prettyPrinted: Whether to format the JSON for human readability
    /// - Returns: The encoded JSON data
    /// - Throws: An error if encoding fails
    public static func encodeDiffToJSON(_ diff: DiffResult, prettyPrinted: Bool = true) throws -> Data {
        let encoder = JSONEncoder()
        if prettyPrinted {
            encoder.outputFormatting = [.sortedKeys]
        }
        
        // First encode the operations to data
        let operationsData = try encoder.encode(diff.operations)
        
        // Create a wrapper with base64 encoded operations and metadata
        var wrapper: [String: Any] = [
            "base64": operationsData.base64EncodedString()
        ]
        
        // Add metadata if available
        if let metadata = diff.metadata {
            let metadataData = try encoder.encode(metadata)
            wrapper["metadata"] = metadataData.base64EncodedString()
        }
        
        // Re-encode the complete wrapper
        return try JSONSerialization.data(withJSONObject: wrapper, options: prettyPrinted ? [.sortedKeys, .prettyPrinted] : [])
    }
    
    /// Encodes a diff result to a JSON string
    /// - Parameters:
    ///   - diff: The diff result to encode
    ///   - prettyPrinted: Whether to format the JSON for human readability
    /// - Returns: The JSON string representation of the diff
    /// - Throws: An error if encoding fails
    public static func encodeDiffToJSONString(_ diff: DiffResult, prettyPrinted: Bool = false) throws -> String {
        let data = try encodeDiffToJSON(diff, prettyPrinted: prettyPrinted)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw DiffError.encodingFailed
        }
        return jsonString
    }
    
    /// Decodes a diff result from JSON data
    /// - Parameter data: The JSON data to decode
    /// - Returns: The decoded diff result
    /// - Throws: An error if decoding fails
    public static func decodeDiffFromJSON(_ data: Data) throws -> DiffResult {
        let decoder = JSONDecoder()
        
        // First, try to decode with the new enhanced format
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Extract base64 operations string
                guard let base64String = json["base64"] as? String,
                      let operationsData = Data(base64Encoded: base64String) else {
                    throw DiffError.decodingFailed
                }
                
                // Decode the operations from the base64 data
                let operations = try decoder.decode([DiffOperation].self, from: operationsData)
                
                // Decode metadata if available
                var metadata: DiffMetadata? = nil
                if let metadataBase64 = json["metadata"] as? String,
                   let metadataData = Data(base64Encoded: metadataBase64) {
                    metadata = try? decoder.decode(DiffMetadata.self, from: metadataData)
                }
                
                return DiffResult(operations: operations, metadata: metadata)
            }
        } catch {
            // Fall through to try old format
        }
        
        // Fall back to old format (direct array of operations)
        do {
            let operations = try decoder.decode([DiffOperation].self, from: data)
            return DiffResult(operations: operations)
        } catch {
            throw DiffError.decodingFailed
        }
    }
    
    /// Decodes a diff result from a JSON string
    /// - Parameter jsonString: The JSON string to decode
    /// - Returns: The decoded diff result
    /// - Throws: An error if decoding fails
    public static func decodeDiffFromJSONString(_ jsonString: String) throws -> DiffResult {
        guard let data = jsonString.data(using: .utf8) else {
            throw DiffError.decodingFailed
        }
        return try decodeDiffFromJSON(data)
    }
    
    /// Gets the base64 string representation of a diff result directly
    /// - Parameter diff: The diff result to encode
    /// - Returns: A base64 encoded string representing the diff operations
    /// - Throws: An error if encoding fails
    public static func diffToBase64(_ diff: DiffResult) throws -> String {
        let encoder = JSONEncoder()
        
        // Create a compound object with both operations and metadata
        var wrapper: [String: Any] = [:]
        
        // Encode operations
        let operationsData = try encoder.encode(diff.operations)
        wrapper["ops"] = operationsData.base64EncodedString()
        
        // Encode metadata if available
        if let metadata = diff.metadata {
            let metadataData = try encoder.encode(metadata)
            wrapper["meta"] = metadataData.base64EncodedString()
        }
        
        // Convert the wrapper to data and base64
        let wrapperData = try JSONSerialization.data(withJSONObject: wrapper)
        return wrapperData.base64EncodedString()
    }
    
    /// Creates a diff result from a base64 encoded string
    /// - Parameter base64String: The base64 encoded string containing the diff operations
    /// - Returns: The decoded diff result
    /// - Throws: An error if decoding fails
    public static func diffFromBase64(_ base64String: String) throws -> DiffResult {
        guard let data = Data(base64Encoded: base64String) else {
            throw DiffError.decodingFailed
        }
        
        // Try to decode as a wrapper first
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let decoder = JSONDecoder()
                
                // Handle new format with metadata
                if let opsBase64 = json["ops"] as? String {
                    guard let opsData = Data(base64Encoded: opsBase64) else {
                        throw DiffError.decodingFailed
                    }
                    
                    let operations = try decoder.decode([DiffOperation].self, from: opsData)
                    
                    // Try to decode metadata
                    var metadata: DiffMetadata? = nil
                    if let metaBase64 = json["meta"] as? String,
                       let metaData = Data(base64Encoded: metaBase64) {
                        metadata = try? decoder.decode(DiffMetadata.self, from: metaData)
                        
                        // Legacy support for old format
                        if let truncatedAt = json["truncatedAt"] as? Int,
                                metadata!.sourceStartLine == nil {
                            metadata = DiffMetadata(
                                sourceStartLine: truncatedAt,
                                sourceEndLine: metadata!.sourceEndLine,
                                destStartLine: metadata!.destStartLine,
                                destEndLine: metadata!.destEndLine,
                                sourceTotalLines: metadata!.sourceTotalLines,
                                destTotalLines: metadata!.destTotalLines,
                                precedingContext: metadata!.precedingContext,
                                followingContext: metadata!.followingContext
                            )
                        }
                    }
                    
                    return DiffResult(operations: operations, metadata: metadata)
                }
            }
        } catch {
            // Fall through to try old format
        }
        
        // Fall back to old format (operations only)
        let decoder = JSONDecoder()
        do {
            let operations = try decoder.decode([DiffOperation].self, from: data)
            return DiffResult(operations: operations)
        } catch {
            throw DiffError.decodingFailed
        }
    }
}
