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
        
        // Create a wrapper with base64 encoded operations
        let wrapper = [
            "base64": operationsData.base64EncodedString()
        ]
        
        return try encoder.encode(wrapper)
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
        
        // Decode the wrapper first
        let wrapper = try decoder.decode([String: String].self, from: data)
        
        guard let base64String = wrapper["base64"],
              let operationsData = Data(base64Encoded: base64String) else {
            throw DiffError.decodingFailed
        }
        
        // Decode the operations from the base64 data
        let operations = try decoder.decode([DiffOperation].self, from: operationsData)
        return DiffResult(operations: operations)
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
}
