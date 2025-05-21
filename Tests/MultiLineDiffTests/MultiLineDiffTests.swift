import Testing
import Foundation
@testable import MultiLineDiff

@Test func example() throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
}

@Test func testCreateDiffWithEmptyStrings() throws {
    let result = MultiLineDiff.createDiffBrus(source: "", destination: "")
    #expect(result.operations.isEmpty)
}

@Test func testCreateDiffWithSourceOnly() throws {
    let source = "Hello, world!"
    let destination = ""
    
    let result = MultiLineDiff.createDiffBrus(source: source, destination: destination)
    
    #expect(result.operations.count == 1)
    if case .delete(let count) = result.operations[0] {
        #expect(count == source.count)
    } else {
        throw TestError("Expected delete operation")
    }
}

@Test func testCreateDiffWithDestinationOnly() throws {
    let source = ""
    let destination = "Hello, world!"
    
    let result = MultiLineDiff.createDiffBrus(source: source, destination: destination)
    
    #expect(result.operations.count == 1)
    if case .insert(let text) = result.operations[0] {
        #expect(text == destination)
    } else {
        throw TestError("Expected insert operation")
    }
}

@Test func testCreateDiffWithSingleLineChanges() throws {
    let source = "Hello, world!"
    let destination = "Hello, Swift!"
    
    let result = MultiLineDiff.createDiffBrus(source: source, destination: destination)
    
    // Expected operations: retain "Hello, ", delete "world", insert "Swift", retain "!"
    #expect(result.operations.count == 4)
    
    if case .retain(let count) = result.operations[0] {
        #expect(count == "Hello, ".count)
    } else {
        throw TestError("Expected retain operation first")
    }
    
    if case .delete(let count) = result.operations[1] {
        #expect(count == "world".count)
    } else {
        throw TestError("Expected delete operation second")
    }
    
    if case .insert(let text) = result.operations[2] {
        #expect(text == "Swift")
    } else {
        throw TestError("Expected insert operation third")
    }
    
    if case .retain(let count) = result.operations[3] {
        #expect(count == "!".count)
    } else {
        throw TestError("Expected retain operation fourth")
    }
}

@Test func testCreateDiffWithMultiLineChanges() throws {
    let source = """
    hello
    1
    signal(SIGINT) { _ in
        print("Shutting down...")
        exit(1)
    }
    xxx
    """
    
    let destination = """
    1
    hello
     signal(SIGINT) { _ in
         print("Shutting down...")
         exit(0)
     }
    """
    
    let result = MultiLineDiff.createDiffBrus(source: source, destination: destination)
    
    print(result)
    
    // Verify the diff can be applied correctly
    let applied = try MultiLineDiff.applyDiff(to: source, diff: result)
    #expect(applied == destination)
    
    print(applied)
}

@Test func testApplyDiffWithEmptyStrings() throws {
    let result = MultiLineDiff.createDiffBrus(source: "", destination: "")
    let applied = try MultiLineDiff.applyDiff(to: "", diff: result)
    #expect(applied == "")
}

@Test func testApplyDiffWithSourceOnly() throws {
    let source = "Hello, world!"
    let destination = ""
    
    let result = MultiLineDiff.createDiffBrus(source: source, destination: destination)
    let applied = try MultiLineDiff.applyDiff(to: source, diff: result)
    
    #expect(applied == destination)
}

@Test func testApplyDiffWithDestinationOnly() throws {
    let source = ""
    let destination = "Hello, world!"
    
    let result = MultiLineDiff.createDiffBrus(source: source, destination: destination)
    let applied = try MultiLineDiff.applyDiff(to: source, diff: result)
    
    #expect(applied == destination)
}

@Test func testApplyDiffWithSingleLineChanges() throws {
    let source = "Hello, world!"
    let destination = "Hello, Swift!"
    
    let result = MultiLineDiff.createDiffBrus(source: source, destination: destination)
    let applied = try MultiLineDiff.applyDiff(to: source, diff: result)
    
    #expect(applied == destination)
}

@Test func testApplyDiffWithMultiLineChanges() throws {
    let source = """
    Line 1
    Line 2
    Line 4
    Line 3
    """
    
    let destination = """
    Line 1
    Modified Line 2
    Line 3
    Line 4
    """
    
    let result = MultiLineDiff.createDiffBrus(source: source, destination: destination)
    print(result)
    let applied = try MultiLineDiff.applyDiff(to: source, diff: result)
    print(applied)
    #expect(applied == destination)
}

@Test func testApplyDiffWithUnicodeContent() throws {
    let source = "Hello, 世界 !"
    let destination = "Hello, 世界!\n🚀"
    
    let result = MultiLineDiff.createDiffBrus(source: source, destination: destination)
    print(result)
    let applied = try MultiLineDiff.applyDiff(to: source, diff: result)
    print(applied)
    #expect(applied == destination)
}

@Test func testInvalidApplyDiff() throws {
    // Create a diff result with invalid operations
    let operations: [DiffOperation] = [
        .retain(100)  // Source doesn't have 100 characters
    ]
    
    let diff = DiffResult(operations: operations)
    
    do {
        _ = try MultiLineDiff.applyDiff(to: "short string", diff: diff)
        throw TestError("Expected error when applying invalid diff")
    } catch {
        // Error is expected
    }
}

@Test func testRoundTrip() throws {
    // Use a minimal set of test cases to avoid hanging
    let testCases = [
        ("", ""),
        ("Hello", "")
    ]
    
    for (source, destination) in testCases {
        let diff = MultiLineDiff.createDiffBrus(source: source, destination: destination)
        let result = try MultiLineDiff.applyDiff(to: source, diff: diff)
        #expect(result == destination, "Round trip failed for source: \(source), destination: \(destination)")
    }
}

@Test func testFileBasedDiffOperations() throws {
    let testFiles = try TestFileManager(testName: "FileBasedDiff")
    
    // Sample source code
    let sourceCode = """
    import Foundation
    
    class Calculator {
        func add(_ a: Int, _ b: Int) -> Int {
            return a + b
        }
        
        func subtract(_ a: Int, _ b: Int) -> Int {
            return a - b
        }
    }
    """
    
    // Sample modified code with changes
    let modifiedCode = """
    import Foundation
    
    class Calculator {
        // Add two numbers
        func add(_ a: Int, _ b: Int) -> Int {
            return a + b
        }
        
        // Subtract two numbers
        func subtract(_ a: Int, _ b: Int) -> Int {
            return a - b
        }
        
        // Multiply two numbers
        func multiply(_ a: Int, _ b: Int) -> Int {
            return a * b
        }
    }
    """
    
    // Write files
    let sourceFileURL = try testFiles.createFile(named: "source_code.swift", content: sourceCode)
    let modifiedFileURL = try testFiles.createFile(named: "modified_code.swift", content: modifiedCode)
    let diffFileURL = try testFiles.createFile(named: "diff.json", content: "")
    
    // Read back the files
    let sourceFromFile = try testFiles.readFile(sourceFileURL)
    let modifiedFromFile = try testFiles.readFile(modifiedFileURL)
    
    // Create diff
    let diff = MultiLineDiff.createDiffBrus(source: sourceFromFile, destination: modifiedFromFile)
    
    // Save diff to file
    try MultiLineDiff.saveDiffToFile(diff, fileURL: diffFileURL)
    
    // Load diff from file for verification
    let loadedDiff = try MultiLineDiff.loadDiffFromFile(fileURL: diffFileURL)
    #expect(loadedDiff.operations.count == diff.operations.count, "Loaded diff should have the same number of operations")
    
    // Apply diff
    let result = try MultiLineDiff.applyDiff(to: sourceFromFile, diff: diff)
    
    // Write result to output file
    let outputFileURL = try testFiles.createFile(named: "output_code.swift", content: result)
    
    // Read back the output and verify
    let outputFromFile = try testFiles.readFile(outputFileURL)
    
    // Verify
    #expect(outputFromFile == modifiedFromFile, "Output from applying diff should match the modified file")
}

@Test func testCodeModificationDiff() throws {
    // Function definition change test
    let originalFunction = """
    func processData(data: [String], options: Options) -> Result {
        // Initialize processing
        let processor = DataProcessor(options: options)
        
        // Process each item
        let results = data.map { processor.process($0) }
        
        return Result(items: results)
    }
    """
    
    let modifiedFunction = """
    func processData(data: [String], options: Options, callback: @escaping (Result) -> Void) {
        // Initialize processing with new configuration
        let processor = DataProcessor(options: options, enableCache: true)
        
        // Process each item with the enhanced algorithm
        let results = data.map { processor.processEnhanced($0) }
        
        // Execute callback with result
        callback(Result(items: results))
    }
    """
    
    // Create diff
    let diff = MultiLineDiff.createDiffBrus(source: originalFunction, destination: modifiedFunction)
    
    // Apply diff
    let result = try MultiLineDiff.applyDiff(to: originalFunction, diff: diff)
    
    // Verify
    #expect(result == modifiedFunction, "Applied diff should reproduce the exact modified code")
    
    // Display operations for debugging
    for op in diff.operations {
        print("Operation: \(op.description)")
    }
}

@Test func testDiffJSONEncodingDecoding() throws {
    // Create a diff with some operations
    let operations: [DiffOperation] = [
        .retain(10),
        .delete(5),
        .insert("Hello, world!"),
        .retain(3)
    ]
    
    let diff = DiffResult(operations: operations)
    
    // Encode to JSON string
    let jsonString = try MultiLineDiff.encodeDiffToJSONString(diff)
    
    // Should contain base64Operations key
    #expect(jsonString.contains("base64Operations"), "JSON should contain base64Operations key")
    
    // Decode back
    let decodedDiff = try MultiLineDiff.decodeDiffFromJSONString(jsonString)
    
    // Verify operations match
    #expect(decodedDiff.operations.count == diff.operations.count, "Operation count should match")
    
    for (index, op) in diff.operations.enumerated() {
        let decodedOp = decodedDiff.operations[index]
        
        switch (op, decodedOp) {
        case (.retain(let count1), .retain(let count2)):
            #expect(count1 == count2, "Retain count should match")
            
        case (.insert(let text1), .insert(let text2)):
            #expect(text1 == text2, "Insert text should match")
            
        case (.delete(let count1), .delete(let count2)):
            #expect(count1 == count2, "Delete count should match")
            
        default:
            throw TestError("Operation types don't match at index \(index)")
        }
    }
    
    // Test file-based save and load
    let fileManager = FileManager.default
    let tempDirURL = fileManager.temporaryDirectory.appendingPathComponent("MultiLineDiffJSONTest-\(UUID().uuidString)")
    try fileManager.createDirectory(at: tempDirURL, withIntermediateDirectories: true)
    
    let fileURL = tempDirURL.appendingPathComponent("test_diff.json")
    
    // Save to file
    try MultiLineDiff.saveDiffToFile(diff, fileURL: fileURL)
    
    // Load from file
    let loadedDiff = try MultiLineDiff.loadDiffFromFile(fileURL: fileURL)
    
    // Verify operations match
    #expect(loadedDiff.operations.count == diff.operations.count, "File-loaded operation count should match")
    
    // Clean up
    try fileManager.removeItem(at: tempDirURL)
}

@Test func testDiffOperationJSONEncoding() throws {
    // Create a diff with various operations
    let operations: [DiffOperation] = [
        .retain(10),
        .delete(5),
        .insert("Hello, world!"),
        .retain(3)
    ]
    
    let diff = DiffResult(operations: operations)
    
    // Encode to JSON string
    let jsonString = try MultiLineDiff.encodeDiffToJSONString(diff)
    
    print("JSON Encoding Test:")
    print("JSON String: \(jsonString)")
    
    // Verify JSON structure
    #expect(jsonString.contains("base64Operations"), "Should contain base64Operations key")
    
    // Decode back
    let decodedDiff = try MultiLineDiff.decodeDiffFromJSONString(jsonString)
    
    // Verify operations match
    #expect(decodedDiff.operations.count == diff.operations.count, "Operation count should match")
    
    for (index, op) in diff.operations.enumerated() {
        let decodedOp = decodedDiff.operations[index]
        
        switch (op, decodedOp) {
        case (.retain(let count1), .retain(let count2)):
            #expect(count1 == count2, "Retain count should match")
            
        case (.insert(let text1), .insert(let text2)):
            #expect(text1 == text2, "Insert text should match")
            
        case (.delete(let count1), .delete(let count2)):
            #expect(count1 == count2, "Delete count should match")
            
        default:
            throw TestError("Operation types don't match at index \(index)")
        }
    }
}

@Test func testLargeFileWithRegularChanges() throws {
    // Setup temporary directory paths
    let fileManager = FileManager.default
    let tempDirURL = fileManager.temporaryDirectory.appendingPathComponent("MultiLineDiffLargeTest-\(UUID().uuidString)")
    let originalFileURL = tempDirURL.appendingPathComponent("original_large.txt")
    let modifiedFileURL = tempDirURL.appendingPathComponent("modified_large.txt")
    let outputFileURL = tempDirURL.appendingPathComponent("result_large.txt")
    let diffFileURL = tempDirURL.appendingPathComponent("diff_large.json")
    
    // Create temp directory
    try fileManager.createDirectory(at: tempDirURL, withIntermediateDirectories: true)
    
    // Generate a large original file with numbered lines
    var originalLines: [String] = []
    for i in 1...100 {
        originalLines.append("Line \(i): This is the original content for line number \(i)")
    }
    let originalContent = originalLines.joined(separator: "\n")
    
    // Generate a modified file with changes every 5-10 lines
    var modifiedLines = originalLines
    
    // 1. Modify every 5th line
    for i in stride(from: 4, to: 100, by: 5) {
        modifiedLines[i] = "Line \(i+1): MODIFIED - This line was changed in the 5th line pattern"
    }
    
    // 2. Insert a new line after every 10th line
    var insertions = 0
    for i in stride(from: 9, to: 100 + insertions, by: 10) {
        let adjustedIndex = i + insertions
        modifiedLines.insert("NEW LINE: This is a newly inserted line after line \(adjustedIndex + 1)", at: adjustedIndex + 1)
        insertions += 1
    }
    
    // 3. Delete every 15th line
    var deletions = 0
    for i in stride(from: 14, to: 100 + insertions - deletions, by: 15) {
        let adjustedIndex = i - deletions
        modifiedLines.removeSubrange(adjustedIndex...adjustedIndex)
        deletions += 1
    }
    
    let modifiedContent = modifiedLines.joined(separator: "\n")
    
    // Write files to disk
    try originalContent.data(using: .utf8)?.write(to: originalFileURL)
    try modifiedContent.data(using: .utf8)?.write(to: modifiedFileURL)
    
    // Create diff
    let diff = MultiLineDiff.createDiffBrus(source: originalContent, destination: modifiedContent)
    
    // Verify diff operations contain the expected changes
    let opCounts = countOperations(diff)
    
    // Should have some of each operation type
    #expect(opCounts.insertCount > 0, "Should have insert operations")
    #expect(opCounts.deleteCount > 0, "Should have delete operations")
    #expect(opCounts.retainCount > 0, "Should have retain operations")
    
    // Save diff to JSON file
    try MultiLineDiff.saveDiffToFile(diff, fileURL: diffFileURL)
    
    // Load back the diff
    let loadedDiff = try MultiLineDiff.loadDiffFromFile(fileURL: diffFileURL)
    
    // Apply the loaded diff
    let result = try MultiLineDiff.applyDiff(to: originalContent, diff: loadedDiff)
    
    // Save result
    try result.data(using: .utf8)?.write(to: outputFileURL)
    
    // Diagnostic information
    print("Original content length: \(originalContent.count)")
    print("Modified content length: \(modifiedContent.count)")
    print("Result content length: \(result.count)")
    print("Diff operations count: \(loadedDiff.operations.count)")
    
    // Print first few diff operations for debugging
    print("First 10 diff operations:")
    for (index, op) in loadedDiff.operations.prefix(10).enumerated() {
        print("\(index): \(op.description)")
    }
    
    // Verify result matches modified content
    #expect(result == modifiedContent, "Output from applying diff should match the modified content")
    
    // Verify loading original content and applying diff produces correct result
    let reloadedOriginal = try String(contentsOf: originalFileURL)
    let appliedResult = try MultiLineDiff.applyDiff(to: reloadedOriginal, diff: loadedDiff)
    #expect(appliedResult == modifiedContent, "Diff should correctly transform original to modified when loaded from disk")
    
    // Get diff statistics for verification
    let diffStats = generateDiffStats(diff)
    
    // Should have statistics matching our modifications
    #expect(diffStats.insertedLines >= insertions, "Should have at least \(insertions) inserted lines")
    #expect(diffStats.deletedLines >= deletions, "Should have at least \(deletions) deleted lines")
    
    // Clean up
    try fileManager.removeItem(at: tempDirURL)
}

private func generateDiffStats(_ diff: DiffResult) -> (insertedLines: Int, deletedLines: Int, retainedChars: Int) {
    var insertedLines = 0
    var deletedLines = 0
    var retainedChars = 0
    
    for op in diff.operations {
        switch op {
        case .insert(let text):
            // Count the number of newlines in the inserted text
            insertedLines += text.components(separatedBy: "\n").count - 1
        case .delete(let count):
            // For deleted content, approximate line count based on average line length
            // This is a simplification as we don't have the deleted content's exact structure
            let avgLineLength = 40  // Assume average line length
            deletedLines += max(1, count / avgLineLength)
        case .retain(let count):
            retainedChars += count
        }
    }
    
    return (insertedLines, deletedLines, retainedChars)
}

@Test func testToddDiffWithMultiLineChanges() throws {
    // Test case with various types of changes
    let source = """
    Line 1: This is unchanged
    Line 2: This will be modified
    Line 3: This will be deleted
    Line 4: This stays the same
    Line 5: This is the final line
    """
    
    let destination = """
    Line 1: This is unchanged
    Line 2: This has been MODIFIED
    Line 4: This stays the same
    New line: This is inserted
    Line 5: This is the final line
    """
    
    // Create diff with more granular Todd algorithm
    let diff = MultiLineDiff.createDiffTodd(source: source, destination: destination)
    
    // Apply diff
    let applied = try MultiLineDiff.applyDiff(to: source, diff: diff)
    
    // Verify result matches
    #expect(applied == destination, "Applied Todd diff should match the destination")
    
    // Count operations
    let opCounts = countOperations(diff)
    
    // Should have multiple retain operations (for unchanged lines)
    #expect(opCounts.retainCount >= 2, "Should have multiple retain operations")
    #expect(opCounts.insertCount >= 1, "Should have at least one insert operation")
    #expect(opCounts.deleteCount >= 1, "Should have at least one delete operation")
}

@Test func testToddDiffWithComplexChanges() throws {
    // Create a more complex example with interleaved changes
    let source = """
    // Copyright notice
    import Foundation
    
    class BrusClass {
        var property1: String = "Initial value"
        var property2: Int = 0
        
        func method1() {
            print("Method 1")
            doSomething()
        }
        
        func method2() {
            print("Method 2")
        }
        
        private func doSomething() {
            // Implementation
        }
    }
    """
    
    let destination = """
    // Copyright notice
    // Added comment
    import Foundation
    import UIKit
    
    class BrusClass {
        // Properties
        var property1: String = "Changed value"
        var property2: Int = 42
        let newProperty: Bool = true
        
        // Methods
        func method1() {
            print("Method 1 - updated")
            doSomethingElse()
        }
        
        func method2() {
            print("Method 2")
        }
        
        func newMethod() {
            // New implementation
        }
        
        private func doSomethingElse() {
            // New implementation
        }
    }
    """
    
    // Create diff with Todd algorithm
    let diff = MultiLineDiff.createDiffTodd(source: source, destination: destination)
    
    // Apply diff
    let applied = try MultiLineDiff.applyDiff(to: source, diff: diff)
    
    // Verify result
    #expect(applied == destination, "Todd diff should correctly handle complex changes")
    
    // Compare with brus algorithm
    let brusDiff = MultiLineDiff.createDiffBrus(source: source, destination: destination)
    
    print("Todd operations count: \(diff.operations.count)")
    print("Brus operations count: \(brusDiff.operations.count)")
    
    // Print first few operations for debugging
    let maxOps = min(5, diff.operations.count)
    for i in 0..<maxOps {
        print("Todd op \(i): \(diff.operations[i].description)")
    }
}

// Helper for throwing errors in tests
struct TestError: Error, CustomStringConvertible {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    var description: String {
        return message
    }
}

/// Helper struct to hold operation counts
struct DiffOperationCounts {
    let retainCount: Int
    let insertCount: Int
    let deleteCount: Int
    let insertedChars: Int
    let deletedChars: Int
    let retainedChars: Int
    
    var totalOperations: Int {
        return retainCount + insertCount + deleteCount
    }
}

/// Helper function to count operations in a diff result
func countOperations(_ diff: DiffResult) -> DiffOperationCounts {
    var retainCount = 0
    var insertCount = 0
    var deleteCount = 0
    var insertedChars = 0
    var deletedChars = 0
    var retainedChars = 0
    
    for op in diff.operations {
        switch op {
        case .retain(let count):
            retainCount += 1
            retainedChars += count
        case .insert(let text):
            insertCount += 1
            insertedChars += text.count
        case .delete(let count):
            deleteCount += 1
            deletedChars += count
        }
    }
    
    return DiffOperationCounts(
        retainCount: retainCount,
        insertCount: insertCount,
        deleteCount: deleteCount,
        insertedChars: insertedChars,
        deletedChars: deletedChars,
        retainedChars: retainedChars
    )
}

/// Helper class for managing temporary test files
class TestFileManager {
    let tempDirURL: URL
    let fileManager: FileManager
    
    init(testName: String) throws {
        fileManager = FileManager.default
        tempDirURL = fileManager.temporaryDirectory.appendingPathComponent("MultiLineDiffTests-\(testName)-\(UUID().uuidString)")
        try fileManager.createDirectory(at: tempDirURL, withIntermediateDirectories: true)
    }
    
    func createFile(named: String, content: String) throws -> URL {
        let fileURL = tempDirURL.appendingPathComponent(named)
        try content.data(using: .utf8)?.write(to: fileURL)
        return fileURL
    }
    
    func readFile(_ url: URL) throws -> String {
        return try String(contentsOf: url)
    }
    
    func cleanup() throws {
        try fileManager.removeItem(at: tempDirURL)
    }
    
    deinit {
        try? cleanup()
    }
}
