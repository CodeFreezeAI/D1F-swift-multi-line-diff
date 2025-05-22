import Foundation
import MultiLineDiff
import Darwin

// Get current timestamp in milliseconds
func getCurrentTimeMs() -> Int64 {
    return Int64(Date().timeIntervalSince1970 * 1000)
}

// Function to run a test and print results
func runTest(_ name: String, _ test: () throws -> Bool) {
    print("Running test: \(name)")
    do {
        let success = try test()
        print("✅ \(name): \(success ? "SUCCESS" : "FAILED")")
    } catch {
        print("❌ \(name): ERROR - \(error)")
    }
    print("")
}

// Test empty strings
runTest("Empty Strings") {
    let result = MultiLineDiff.createDiff(source: "", destination: "")
    return result.operations.isEmpty
}

// Test source only
runTest("Source Only") {
    let source = "Hello, world!"
    let destination = ""
    
    let result = MultiLineDiff.createDiff(source: source, destination: destination)
    
    guard result.operations.count == 1 else { return false }
    if case .delete(let count) = result.operations[0] {
        return count == source.count
    }
    return false
}

// Test destination only
runTest("Destination Only") {
    let source = ""
    let destination = "Hello, world!"
    
    let result = MultiLineDiff.createDiff(source: source, destination: destination)
    
    guard result.operations.count == 1 else { return false }
    if case .insert(let text) = result.operations[0] {
        return text == destination
    }
    return false
}

// Test single-line changes
runTest("Single-Line Changes") {
    let source = "Hello, world!"
    let destination = "Hello, Swift!"
    
    let result = MultiLineDiff.createDiff(source: source, destination: destination)
    let applied = try MultiLineDiff.applyDiff(to: source, diff: result)
    
    return applied == destination
}

// Test multi-line changes
runTest("Multi-Line Changes") {
    let source = """
    Line 1
    Line 2
    Line 3
    """
    
    let destination = """
    Line 1
    Modified Line 2
    Line 3
    Line 4
    """
    
    let result = MultiLineDiff.createDiff(source: source, destination: destination)
    let applied = try MultiLineDiff.applyDiff(to: source, diff: result)
    
    return applied == destination
}

// Test Unicode content
runTest("Unicode Content") {
    let source = "Hello, 世界!"
    let destination = "Hello, 世界! 🚀"
    
    let result = MultiLineDiff.createDiff(source: source, destination: destination)
    let applied = try MultiLineDiff.applyDiff(to: source, diff: result)
    
    return applied == destination
}

// Test round trip with various inputs
runTest("Round Trip Tests") {
    let testCases = [
        ("", ""),
        ("Hello", ""),
        ("", "Hello"),
        ("Hello", "Hello"),
        ("Hello", "Hello, world!"),
        ("Hello, world!", "Hello"),
        ("Hello, world!", "Hello, Swift!"),
        ("Multi\nLine\nText", "Multi\nLine\nModified\nText"),
        ("Unicode 😀 Text", "Modified Unicode 😀 😎 Text")
    ]
    
    for (source, destination) in testCases {
        print("  Testing: \"\(source)\" -> \"\(destination)\"")
        let diff = MultiLineDiff.createDiff(source: source, destination: destination)
        let result = try MultiLineDiff.applyDiff(to: source, diff: diff)
        if result != destination {
            print("  ❌ Round trip failed: \"\(result)\" != \"\(destination)\"")
            return false
        }
    }
    
    return true
}

print("All tests completed.")

// MARK: - Real World Examples with FileManager

print("\n=== Real World Examples ===\n")

// Example: Working with actual source code files
func demonstrateCodeFileDiff() {
    print("Creating and applying diffs to source code files:")
    
    do {
        // Create temporary directory
        let fileManager = FileManager.default
        let tempDirURL = fileManager.temporaryDirectory.appendingPathComponent("CODE_FILE_DIFF_DEMO-\(UUID().uuidString)")
        
        // Create directory
        try fileManager.createDirectory(at: tempDirURL, withIntermediateDirectories: true)
        print("  🏷️ LABELED TEMP DIRECTORY: \(tempDirURL.path)")
        
        // Original version of the view controller
        let originalCode = """
        import UIKit
        
        class ViewController: UIViewController {
            
            // UI Components
            private let tableView = UITableView()
            private var data: [String] = []
            
            override func viewDidLoad() {
                super.viewDidLoad()
                setupUI()
                loadData()
            }
            
            private func setupUI() {
                view.addSubview(tableView)
                tableView.delegate = self
                tableView.dataSource = self
                
                // Layout constraints
                tableView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    tableView.topAnchor.constraint(equalTo: view.topAnchor),
                    tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
                    tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                    tableView.rightAnchor.constraint(equalTo: view.rightAnchor)
                ])
            }
            
            private func loadData() {
                data = ["Item 1", "Item 2", "Item 3"]
                tableView.reloadData()
            }
        }
        
        // MARK: - UITableViewDelegate, UITableViewDataSource
        extension ViewController: UITableViewDelegate, UITableViewDataSource {
            func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return data.count
            }
            
            func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")
                cell.textLabel?.text = data[indexPath.row]
                return cell
            }
        }
        """
        
        // Updated version with added search functionality
        let updatedCode = """
        import UIKit
        
        class ViewController: UIViewController {
            
            // UI Components
            private let tableView = UITableView()
            private let searchBar = UISearchBar()
            private var data: [String] = []
            private var filteredData: [String] = []
            
            override func viewDidLoad() {
                super.viewDidLoad()
                setupUI()
                loadData()
            }
            
            private func setupUI() {
                // Add search bar
                view.addSubview(searchBar)
                searchBar.delegate = self
                searchBar.placeholder = "Search items..."
                
                // Add table view
                view.addSubview(tableView)
                tableView.delegate = self
                tableView.dataSource = self
                tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
                
                // Layout constraints
                searchBar.translatesAutoresizingMaskIntoConstraints = false
                tableView.translatesAutoresizingMaskIntoConstraints = false
                
                NSLayoutConstraint.activate([
                    searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                    searchBar.leftAnchor.constraint(equalTo: view.leftAnchor),
                    searchBar.rightAnchor.constraint(equalTo: view.rightAnchor),
                    
                    tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
                    tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
                    tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                    tableView.rightAnchor.constraint(equalTo: view.rightAnchor)
                ])
            }
            
            private func loadData() {
                data = ["Item 1", "Item 2", "Item 3", "Example 4", "Test 5"]
                filteredData = data
                tableView.reloadData()
            }
            
            private func filterContentForSearchText(_ searchText: String) {
                if searchText.isEmpty {
                    filteredData = data
                } else {
                    filteredData = data.filter { $0.lowercased().contains(searchText.lowercased()) }
                }
                tableView.reloadData()
            }
        }
        
        // MARK: - UITableViewDelegate, UITableViewDataSource
        extension ViewController: UITableViewDelegate, UITableViewDataSource {
            func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return filteredData.count
            }
            
            func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                cell.textLabel?.text = filteredData[indexPath.row]
                return cell
            }
        }
        
        // MARK: - UISearchBarDelegate
        extension ViewController: UISearchBarDelegate {
            func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
                filterContentForSearchText(searchText)
            }
            
            func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
                searchBar.resignFirstResponder()
            }
        }
        """
        
        // Save original and updated code to files
        let originalFileURL = tempDirURL.appendingPathComponent("ViewController.swift")
        let updatedFileURL = tempDirURL.appendingPathComponent("ViewControllerUpdated.swift")
        let outputFileURL = tempDirURL.appendingPathComponent("ViewControllerOutput.swift")
        
        try originalCode.write(to: originalFileURL, atomically: true, encoding: .utf8)
        try updatedCode.write(to: updatedFileURL, atomically: true, encoding: .utf8)
        
        print("  Created original and updated code files")
        
        // Create diff between files
        let originalCodeContent = try String(contentsOf: originalFileURL, encoding: .utf8)
        let updatedCodeContent = try String(contentsOf: updatedFileURL, encoding: .utf8)
        
        let diff = MultiLineDiff.createDiff(source: originalCodeContent, destination: updatedCodeContent)
        print("  Created diff with \(diff.operations.count) operations")
        
        // Save diff to file
        let diffFileURL = tempDirURL.appendingPathComponent("ViewControllerDiff.json")
        try MultiLineDiff.saveDiffToFile(diff, fileURL: diffFileURL)
        print("  Saved diff to: \(diffFileURL.path)")
        
        // Also save a human-readable JSON string to a text file for inspection
        let diffJsonString = try MultiLineDiff.encodeDiffToJSONString(diff)
        let diffTextFileURL = tempDirURL.appendingPathComponent("ViewControllerDiff.txt")
        try diffJsonString.data(using: .utf8)?.write(to: diffTextFileURL)
        print("  Saved human-readable diff to: \(diffTextFileURL.path)")
        
        // Load diff back from file for verification
        let loadedDiff = try MultiLineDiff.loadDiffFromFile(fileURL: diffFileURL)
        print("  Loaded diff from file (operations: \(loadedDiff.operations.count))")
        
        // Apply diff
        let result = try MultiLineDiff.applyDiff(to: originalCodeContent, diff: diff)
        
        // Write result
        try result.write(to: outputFileURL, atomically: true, encoding: .utf8)
        print("  Applied diff and wrote output to file")
        
        // Verify
        let outputContent = try String(contentsOf: outputFileURL, encoding: .utf8)
        if outputContent == updatedCodeContent {
            print("  ✅ SUCCESS: Output matches the updated code")
        } else {
            print("  ❌ FAILURE: Output does not match the updated code")
        }
        
        // Display one sample operation
        if let sampleOp = diff.operations.first(where: { 
            if case .insert = $0 { return true } else { return false }
        }) {
            print("\n  Sample operation: \(sampleOp.description)")
        }
        
        print("\n  Files available at:")
        print("  - Original: \(originalFileURL.path)")
        print("  - Updated: \(updatedFileURL.path)")
        print("  - Output: \(outputFileURL.path)")
        
        // Optional: Clean up
        // try fileManager.removeItem(at: tempDirURL)
        // print("  Cleaned up temporary directory")
        
    } catch {
        print("  ❌ ERROR: \(error)")
    }
}

// Example: Working with large files and regular pattern changes
func demonstrateLargeFileDiffWithPatterns() {
    print("\nCreating and applying diffs to large files with regular change patterns:")
    
    do {
        // Create temporary directory
        let fileManager = FileManager.default
        let tempDirURL = fileManager.temporaryDirectory.appendingPathComponent("LARGE_FILE_DIFF_DEMO-\(UUID().uuidString)")
        
        // Create directory
        try fileManager.createDirectory(at: tempDirURL, withIntermediateDirectories: true)
        print("  🏷️ LABELED TEMP DIRECTORY: \(tempDirURL.path)")
        
        // Generate a large source code file with numbered lines (simulating a real-world file)
        var originalLines: [String] = []
        originalLines.append("/**")
        originalLines.append(" * Large File Example")
        originalLines.append(" * This file demonstrates diffing on larger files with regular pattern changes")
        originalLines.append(" */")
        originalLines.append("")
        originalLines.append("import Foundation")
        originalLines.append("")
        originalLines.append("class LargeFileExample {")
        
        // Add 50 numbered method definitions
        for i in 1...50 {
            originalLines.append("    /**")
            originalLines.append("     * Method \(i) documentation")
            originalLines.append("     * Performs operation \(i)")
            originalLines.append("     */")
            originalLines.append("    func method\(i)(param: String) -> Int {")
            originalLines.append("        // Implementation for method \(i)")
            originalLines.append("        print(\"Executing method \(i) with param: \\(param)\")")
            originalLines.append("        return \(i)")
            originalLines.append("    }")
            originalLines.append("")
        }
        
        originalLines.append("    // Helper methods")
        originalLines.append("    private func helperMethod() {")
        originalLines.append("        // Helper implementation")
        originalLines.append("    }")
        originalLines.append("}")
        
        let originalContent = originalLines.joined(separator: "\n")
        
        // Generate modified content with systematic changes
        var modifiedLines = originalLines
        
        // 1. Change method signatures every 5 methods
        for i in stride(from: 0, to: 50, by: 5) {
            let baseIndex = 8 + (i * 9) + 4  // Line with method signature
            if baseIndex < modifiedLines.count {
                let oldLine = modifiedLines[baseIndex]
                modifiedLines[baseIndex] = oldLine.replacingOccurrences(
                    of: "func method\(i+1)(param: String) -> Int",
                    with: "func method\(i+1)(param: String, options: [String: Any] = [:]) -> Int"
                )
            }
        }
        
        // 2. Add new methods every 10 methods
        var insertions = 0
        for i in stride(from: 0, to: 50, by: 10) {
            let baseIndex = 8 + (i * 9) + 9 + insertions  // Line after method
            if baseIndex < modifiedLines.count {
                let newMethod = [
                    "    /**",
                    "     * New method added after method \(i+1)",
                    "     * This demonstrates inserting new content",
                    "     */",
                    "    func newMethodAfter\(i+1)(param1: String, param2: Int) -> Bool {",
                    "        // New method implementation",
                    "        print(\"New method after \(i+1) executing with \\(param1) and \\(param2)\")",
                    "        return true",
                    "    }",
                    ""
                ]
                modifiedLines.insert(contentsOf: newMethod, at: baseIndex)
                insertions += newMethod.count
            }
        }
        
        // 3. Remove some methods entirely
        var deletions = 0
        for i in stride(from: 2, to: 50, by: 15) {
            let baseIndex = 8 + (i * 9) + insertions - deletions - 1  // Start of method block
            if baseIndex + 9 < modifiedLines.count {
                modifiedLines.removeSubrange(baseIndex..<baseIndex+9)
                deletions += 9
            }
        }
        
        // 4. Modify implementation in remaining methods
        for i in stride(from: 3, to: 50, by: 7) {
            // Find the method in the modified array
            for (index, line) in modifiedLines.enumerated() {
                if line.contains("func method\(i+1)(") {
                    // Found the method, now modify its implementation (2 lines after signature)
                    let implIndex = index + 2
                    if implIndex < modifiedLines.count {
                        modifiedLines[implIndex] = "        // UPDATED: Modified implementation for method \(i+1)"
                    }
                    break
                }
            }
        }
        
        let modifiedContent = modifiedLines.joined(separator: "\n")
        
        // Save files to disk
        let originalFileURL = tempDirURL.appendingPathComponent("LargeFileExample.swift")
        let modifiedFileURL = tempDirURL.appendingPathComponent("LargeFileExample.modified.swift")
        let outputFileURL = tempDirURL.appendingPathComponent("LargeFileExample.output.swift")
        let diffFileURL = tempDirURL.appendingPathComponent("LargeFileExample.diff.json")
        
        try originalContent.data(using: .utf8)?.write(to: originalFileURL)
        try modifiedContent.data(using: .utf8)?.write(to: modifiedFileURL)
        
        print("  Created original and modified large files")
        
        // Create the diff
        let diff = MultiLineDiff.createDiff(source: originalContent, destination: modifiedContent)
        
        // Collect statistics on the diff
        var insertCount = 0
        var deleteCount = 0
        var retainCount = 0
        var insertedChars = 0
        var deletedChars = 0
        var retainedChars = 0
        
        for op in diff.operations {
            switch op {
            case .insert(let text):
                insertCount += 1
                insertedChars += text.count
            case .delete(let count):
                deleteCount += 1
                deletedChars += count
            case .retain(let count):
                retainCount += 1
                retainedChars += count
            }
        }
        
        print("  Created diff with \(diff.operations.count) operations:")
        print("    - Insert operations: \(insertCount) (total \(insertedChars) characters)")
        print("    - Delete operations: \(deleteCount) (total \(deletedChars) characters)")
        print("    - Retain operations: \(retainCount) (total \(retainedChars) characters)")
        
        // Save diff to file
        try MultiLineDiff.saveDiffToFile(diff, fileURL: diffFileURL)
        print("  Saved diff to: \(diffFileURL.path)")
        
        // Load diff from file
        let loadedDiff = try MultiLineDiff.loadDiffFromFile(fileURL: diffFileURL)
        print("  Loaded diff from file")
        
        // Apply the loaded diff
        let result = try MultiLineDiff.applyDiff(to: originalContent, diff: loadedDiff)
        
        // Verify result matches expected
        let matches = result == modifiedContent
        print("  Applied diff to original content: \(matches ? "✅ SUCCESS" : "❌ FAILURE")")
        
        // Save result
        try result.data(using: .utf8)?.write(to: outputFileURL)
        print("  Saved output to: \(outputFileURL.path)")
        
        print("\n  Files available at:")
        print("  - Original: \(originalFileURL.path)")
        print("  - Modified: \(modifiedFileURL.path)")
        print("  - Output: \(outputFileURL.path)")
        print("  - Diff: \(diffFileURL.path)")
    } catch {
        print("  ❌ ERROR: \(error)")
    }
}

// Example: Comparing Brus vs. Todd diff algorithm
func demonstrateAlgorithmComparison() {
    print("\nComparing Brus vs. Todd Diff Algorithms:")
    
    do {
        // Create a sample file with multiple changes
        let sourceCode = """
        import Foundation
        
        struct User {
            let id: UUID
            var name: String
            var email: String
            var age: Int
            
            init(name: String, email: String, age: Int) {
                self.id = UUID()
                self.name = name
                self.email = email
                self.age = age
            }
            
            func greet() -> String {
                return "Hello, my name is \\(name)!"
            }
        }
        
        // Helper functions
        func validateEmail(_ email: String) -> Bool {
            // Basic validation
            return email.contains("@")
        }
        
        func createUser(name: String, email: String, age: Int) -> User? {
            guard validateEmail(email) else {
                return nil
            }
            return User(name: name, email: email, age: age)
        }
        """
        
        let modifiedCode = """
        import Foundation
        import UIKit
        
        struct User {
            let id: UUID
            var name: String
            var email: String
            var age: Int
            var avatar: UIImage?
            
            init(name: String, email: String, age: Int, avatar: UIImage? = nil) {
                self.id = UUID()
                self.name = name
                self.email = email
                self.age = age
                self.avatar = avatar
            }
            
            func greet() -> String {
                return "👋 Hello, my name is \\(name)!"
            }
            
            func updateAvatar(_ newAvatar: UIImage) {
                self.avatar = newAvatar
            }
        }
        
        // Helper functions
        func validateEmail(_ email: String) -> Bool {
            // Enhanced validation
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
            return emailPredicate.evaluate(with: email)
        }
        
        func createUser(name: String, email: String, age: Int, avatar: UIImage? = nil) -> User? {
            guard validateEmail(email) else {
                return nil
            }
            return User(name: name, email: email, age: age, avatar: avatar)
        }
        """
        
        // Create temporary directory
        let fileManager = FileManager.default
        let tempDirURL = fileManager.temporaryDirectory.appendingPathComponent("ALGORITHM_COMPARISON_DEMO-\(UUID().uuidString)")
        
        // Create directory
        try fileManager.createDirectory(at: tempDirURL, withIntermediateDirectories: true)
        print("  🏷️ LABELED TEMP DIRECTORY: \(tempDirURL.path)")
        
        // Save files
        let originalFileURL = tempDirURL.appendingPathComponent("User.swift")
        let modifiedFileURL = tempDirURL.appendingPathComponent("User.modified.swift")
        
        try sourceCode.data(using: .utf8)?.write(to: originalFileURL)
        try modifiedCode.data(using: .utf8)?.write(to: modifiedFileURL)
        
        // Create diffs with both algorithms
        let brusDiff = MultiLineDiff.createDiff(source: sourceCode, destination: modifiedCode, algorithm: .brus)
        let toddDiff = MultiLineDiff.createDiff(source: sourceCode, destination: modifiedCode, algorithm: .todd)
        
        // Save diffs to files
        let brusDiffFileURL = tempDirURL.appendingPathComponent("brus_diff.json")
        let toddDiffFileURL = tempDirURL.appendingPathComponent("todd_diff.json")
        
        try MultiLineDiff.saveDiffToFile(brusDiff, fileURL: brusDiffFileURL)
        try MultiLineDiff.saveDiffToFile(toddDiff, fileURL: toddDiffFileURL)
        
        // Count operations by type
        func countOperations(_ diff: DiffResult) -> (retain: Int, insert: Int, delete: Int) {
            var retainCount = 0
            var insertCount = 0
            var deleteCount = 0
            
            for op in diff.operations {
                switch op {
                case .retain: retainCount += 1
                case .insert: insertCount += 1
                case .delete: deleteCount += 1
                }
            }
            
            return (retainCount, insertCount, deleteCount)
        }
        
        let brusOpCounts = countOperations(brusDiff)
        let toddOpCounts = countOperations(toddDiff)
        
        // Print comparison
        print("\n  Brus Diff Algorithm:")
        print("    -  Total operations: \(brusDiff.operations.count)")
        print("    - Retain operations: \(brusOpCounts.retain)")
        print("    - Insert operations: \(brusOpCounts.insert)")
        print("    - Delete operations: \(brusOpCounts.delete)")
        
        print("\n  Todd Diff Algorithm:")
        print("    -  Total operations: \(toddDiff.operations.count)")
        print("    - Retain operations: \(toddOpCounts.retain)")
        print("    - Insert operations: \(toddOpCounts.insert)")
        print("    - Delete operations: \(toddOpCounts.delete)")
        
        // Apply both diffs to verify they work
        let brusResult = try MultiLineDiff.applyDiff(to: sourceCode, diff: brusDiff)
        let toddResult = try MultiLineDiff.applyDiff(to: sourceCode, diff: toddDiff)
        
        let brusMatches = brusResult == modifiedCode
        let toddMatches = toddResult == modifiedCode
        let bothFilesMatch = toddResult == brusResult
        
        print("\n  Results:")
        print("    - Brus diff correctly transforms source: \(brusMatches ? "✅" : "❌")")
        print("    - Todd diff correctly transforms source: \(toddMatches ? "✅" : "❌")")
        print("    - Todd = Brus results are a dead match!: \(bothFilesMatch ? "✅" : "❌")")

        print("\n  Files available at:")
        print("    - Original: \(originalFileURL.path)")
        print("    - Modified: \(modifiedFileURL.path)")
        print("    - Brus Diff: \(brusDiffFileURL.path)")
        print("    - Todd Diff: \(toddDiffFileURL.path)")

    } catch {
        print("  ❌ ERROR: \(error)")
    }
}

func demonstrateBase64Diff() {
    print("\nDemonstrating Base64 Diff Operations:")
    
    let source = """
    class Example {
        func greet() {
            print("Hello")
        }
    }
    """
    
    let destination = """
    class Example {
        // Added documentation
        func greet(name: String) {
            print("Hello, \\(name)!")
        }
    }
    """
    
    do {
        // Create diff result with full metadata
        let diffResult = MultiLineDiff.createDiff(
            source: source, 
            destination: destination, 
            includeMetadata: true
        )
        
        // Convert to Base64 and JSON
        let base64Diff = try MultiLineDiff.diffToBase64(diffResult)
        let jsonString = try MultiLineDiff.encodeDiffToJSONString(diffResult, prettyPrinted: true)
        
        // Decode both formats
        let base64DecodedDiff = try MultiLineDiff.diffFromBase64(base64Diff)
        let jsonDecodedDiff = try MultiLineDiff.decodeDiffFromJSONString(jsonString)
        
        // Print full metadata details
        print("\n=== Full Metadata Comparison ===")
        
        print("\n--- Base64 Decoded Metadata ---")
        if let metadata = base64DecodedDiff.metadata {
            print("Source Start Line: \(metadata.sourceStartLine ?? -1)")
            print("Source End Line: \(metadata.sourceEndLine ?? -1)")
            print("Dest Start Line: \(metadata.destStartLine ?? -1)")
            print("Dest End Line: \(metadata.destEndLine ?? -1)")
            print("Source Total Lines: \(metadata.sourceTotalLines ?? -1)")
            print("Dest Total Lines: \(metadata.destTotalLines ?? -1)")
            print("Preceding Context: \(metadata.precedingContext ?? "N/A")")
            print("Following Context: \(metadata.followingContext ?? "N/A")")
            print("Insert Operations: \(metadata.insertOperations ?? -1)")
            print("Delete Operations: \(metadata.deleteOperations ?? -1)")
            print("Retain Operations: \(metadata.retainOperations ?? -1)")
            print("Change Type: \(metadata.changeType?.rawValue ?? "N/A")")
            print("Change Percentage: \(metadata.changePercentage ?? -1)%")
            print("Algorithm Used: \(metadata.algorithmUsed?.rawValue ?? "N/A")")
            print("Diff ID: \(metadata.diffId ?? "N/A")")
        }
        
        print("\n--- JSON Decoded Metadata ---")
        if let metadata = jsonDecodedDiff.metadata {
            print("Source Start Line: \(metadata.sourceStartLine ?? -1)")
            print("Source End Line: \(metadata.sourceEndLine ?? -1)")
            print("Dest Start Line: \(metadata.destStartLine ?? -1)")
            print("Dest End Line: \(metadata.destEndLine ?? -1)")
            print("Source Total Lines: \(metadata.sourceTotalLines ?? -1)")
            print("Dest Total Lines: \(metadata.destTotalLines ?? -1)")
            print("Preceding Context: \(metadata.precedingContext ?? "N/A")")
            print("Following Context: \(metadata.followingContext ?? "N/A")")
            print("Insert Operations: \(metadata.insertOperations ?? -1)")
            print("Delete Operations: \(metadata.deleteOperations ?? -1)")
            print("Retain Operations: \(metadata.retainOperations ?? -1)")
            print("Change Type: \(metadata.changeType?.rawValue ?? "N/A")")
            print("Change Percentage: \(metadata.changePercentage ?? -1)%")
            print("Algorithm Used: \(metadata.algorithmUsed?.rawValue ?? "N/A")")
            print("Diff ID: \(metadata.diffId ?? "N/A")")
        }
        
        print("\n=== Full Encoding Details ===")
        print("\nBase64 Diff:")
        print(base64Diff)
        
        print("\nJSON Diff:")
        print(jsonString)
        
        // Format comparison
        let base64Bytes = base64Diff.data(using: .utf8)?.count ?? 0
        let jsonBytes = jsonString.data(using: .utf8)?.count ?? 0
        let sizeReduction = jsonBytes > 0 ? 
            Double(base64Bytes - jsonBytes) / Double(jsonBytes) * 100 : 0
        
        print("\n  Format comparison:")
        print("  - Base64 length: \(base64Bytes) bytes")
        print("  - JSON length: \(jsonBytes) bytes")
        print("  - Size reduction: \(String(format: "%.2f", sizeReduction))%")
        
        // Apply base64 diff
        let result = try MultiLineDiff.applyBase64Diff(to: source, base64Diff: base64Diff)
        let success = result == destination
        
        print("\n  Applied base64 diff:")
        print("  - Success: \(success ? "✅" : "❌")")
        
    } catch {
        print("  ❌ ERROR: \(error)")
    }
}

// Example: Working with truncated diffs - demonstrating both use cases
func demonstrateTruncatedDiff() {
    print("\nDemonstrating Truncated Diff Scenarios:")
    
    do {
        // Create temporary directory
        let fileManager = FileManager.default
        let tempDirURL = fileManager.temporaryDirectory.appendingPathComponent("TRUNCATEDDIFFDEMO-\(UUID().uuidString)")
        
        // Create directory
        try fileManager.createDirectory(at: tempDirURL, withIntermediateDirectories: true)
        print("  LABELED TEMP DIRECTORY: \(tempDirURL.path)")
        
        // Original content with multiple sections and extra lines
        let originalContent = """
        # Document Header
        This is the original document header with important context.
        Additional header information and metadata.
        
        ## Section 1: Initial Content
        Line 1: Original first section content
        Line 2: More details about the first section
        Line 2a: Some additional context in the first section
        Line 2b: Even more information that wasn't here before
        
        ## Section 2: Main Content
        Line 3: Original main section content
        Line 4: Detailed explanation of the main section
        
        ## Section 3: Conclusion
        Line 5: Concluding remarks
        Line 6: Final thoughts
        
        ## Section 4: Extra Content
        Line 7: This is completely new section not in the truncated content
        Line 8: Another line that doesn't exist in the truncated version
        """
        
        // Truncated content (beginning of the file is missing)
        let truncatedContent = """
        ## Section 2: Main Content
        Line 3: Original main section content
        Line 4: Detailed explanation of the main section
        
        ## Section 3: Conclusion
        Line 5: Concluding remarks
        Line 6: Final thoughts
        """
        
        // Modified content with changes (matches the new structure)
        let modifiedContent = """
        # Document Header
        This is the UPDATED document header with important context.
        Additional header information and metadata.
        
        ## Section 1: Initial Content
        Line 1: MODIFIED first section content
        Line 2: Updated details about the first section
        Line 2a: Some additional context in the first section
        Line 2b: Even more information that wasn't here before
        
        ## Section 2: Main Content
        Line 3: UPDATED main section content
        Line 4: Comprehensive explanation of the main section
        
        ## Section 3: Conclusion
        Line 5: Enhanced concluding remarks
        Line 6: Expanded final thoughts
        
        ## Section 4: Extra Content
        Line 7: This is completely new section not in the truncated content
        Line 8: Another line that doesn't exist in the truncated version
        """
        
        // Save files
        let originalFileURL = tempDirURL.appendingPathComponent("original.txt")
        let truncatedFileURL = tempDirURL.appendingPathComponent("truncated.txt")
        let modifiedFileURL = tempDirURL.appendingPathComponent("modified.txt")
        
        try originalContent.write(to: originalFileURL, atomically: true, encoding: .utf8)
        try truncatedContent.write(to: truncatedFileURL, atomically: true, encoding: .utf8)
        try modifiedContent.write(to: modifiedFileURL, atomically: true, encoding: .utf8)
        
        print("  Created files:")
        print("    - Original (full source): \(originalFileURL.lastPathComponent)")
        print("    - Truncated Source (sections 2-3): \(truncatedFileURL.lastPathComponent)")
        print("    - Full Modified: \(modifiedFileURL.lastPathComponent)")
        
        // We don't need the full diff for this demonstration - we're only interested in 
        // applying a diff created from truncated content to the full original file
        
        // Create a diff specifically for just the truncated section
        
        // Extract the corresponding section from the modified content (sections 2-3)
        // Safe range finding with optional binding
        guard let modifiedTruncatedStart = modifiedContent.range(of: "## Section 2: Main Content"),
              let modifiedTruncatedEnd = modifiedContent.range(of: "Line 6: Expanded final thoughts") else {
            throw NSError(domain: "DiffDemo", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not find specified ranges in modified content"])
        }
        let modifiedTruncatedSection = modifiedContent[modifiedTruncatedStart.lowerBound..<modifiedTruncatedEnd.upperBound]
        
        // Safe prefix and range finding
        guard let truncatedContentRange = originalContent.range(of: truncatedContent) else {
            throw NSError(domain: "DiffDemo", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not find truncated content in original content"])
        }
        let originalLinesBefore = originalContent.prefix(upTo: truncatedContentRange.lowerBound)
            .split(separator: "\n")
            .count
        
        // Save this "truncated modified" content to a file for inspection
        let truncatedModifiedFileURL = tempDirURL.appendingPathComponent("truncated-modified.txt")
        try String(modifiedTruncatedSection).write(to: truncatedModifiedFileURL, atomically: true, encoding: .utf8)
        print("    - Truncated Modified: \(truncatedModifiedFileURL.lastPathComponent)")
        
        print("  Extracted corresponding section from modified content")
       
        // Create diff from truncated source to truncated modified section with proper metadata
        // This is the key step: creating a diff that can be applied to the full file
        let truncatedModifiedContent = String(modifiedTruncatedSection)
        print("  Creating diff: truncated source → truncated modified")
        
        let truncatedDiff = MultiLineDiff.createDiff(
            source: truncatedContent,
            destination: truncatedModifiedContent,
            includeMetadata: true,
            sourceStartLine: originalLinesBefore
        )
        
        // Save metadata about the truncated section to a file for inspection
        let truncatedDiffFileURL = tempDirURL.appendingPathComponent("TruncatedDiff.json")
        try MultiLineDiff.saveDiffToFile(truncatedDiff, fileURL: truncatedDiffFileURL)
        print("  Saved truncated diff to: \(truncatedDiffFileURL.path)")
        
        print("  Created truncated diff with \(truncatedDiff.operations.count) operations")
        
        // Approach 1: Create a modified version of the original file that updates only section 2 and 3
        let partiallyModifiedOutput = originalContent.replacingOccurrences(
            of: truncatedContent,
            with: String(modifiedTruncatedSection)
        )
        
        // We're only focusing on applying a truncated diff to a full file
        // No need to create a whole-file replacement diff
        
        // This is the key operation we want to demonstrate:
        // Apply the truncated diff to the full original file
        // This only updates the sections that were in the truncated content
        let resultFromTruncated = try MultiLineDiff.applyDiff(
            to: originalContent, 
            diff: truncatedDiff, 
            allowTruncatedSource: true
        )
        
        // We're only demonstrating the truncated diff application
        // No whole-file replacement is needed for this test
        
        // Just check the truncated diff result
        print("  Partial update matches expected: \(partiallyModifiedOutput == resultFromTruncated ? "✅" : "❌")")
        
        // Save the result of applying the truncated diff to the output file
        let outputFileURL = tempDirURL.appendingPathComponent("output.txt")
        try resultFromTruncated.data(using: .utf8)?.write(to: outputFileURL)
        print("  Applied truncated diff to the original file and wrote result to output.txt")
        
        // Verify the result
        let outputContent = try String(contentsOf: outputFileURL, encoding: .utf8)
        
        print("\n  Output Content:")
        print(outputContent)
        
        print("\n  Modified Content:")
        print(modifiedContent)
        
        // More detailed comparison to show what actually changed
        let originalLines = originalContent.split(separator: "\n")
        let outputLines = outputContent.split(separator: "\n")
        
        print("\n  Detailed Line Comparison (Output vs Original):")
        for (index, line) in outputLines.enumerated() {
            if index < originalLines.count {
                let changed = line != originalLines[index]
                let marker = changed ? "🔄" : "  "
                print("    Line \(index): \(marker) \(line)")
                
                // For changed lines, show the original below for comparison
                if changed {
                    print("             was: \(originalLines[index])")
                }
            } else {
                print("    Line \(index): ➕ (New line) \(line)")
            }
        }
        
        // Identify which sections were from the truncated content
        print("\n  Truncated Section in Output (should be modified):")
        // Find line number where truncated content starts in original
        let truncatedSectionStartLine = originalContent.prefix(upTo: originalContent.range(of: truncatedContent)!.lowerBound)
            .split(separator: "\n")
            .count
        
        let truncatedEndLine = truncatedSectionStartLine + truncatedContent.split(separator: "\n").count - 1
        
        for (index, line) in outputLines.enumerated() {
            if index >= truncatedSectionStartLine && index <= truncatedEndLine {
                print("    Line \(index): ✅ (TRUNCATED SECTION) \(line)")
            }
        }
        
        // For truncated diffs, we want to verify that:
        // 1. The original sections not in the truncated diff were preserved
        // 2. The sections in the truncated diff were properly updated
        
        // For verification, create an expected output by directly updating just the truncated section
        let expectedOutput = originalContent.replacingOccurrences(
            of: truncatedContent,
            with: String(modifiedTruncatedSection)
        )
        
        // Compare the result from applying the truncated diff with our expected output
        let truncatedDiffWorkedCorrectly = outputContent == expectedOutput
        
        print("  RESULT OF APPLYING TRUNCATED DIFF:")
        print("  - Matches expected output (original with only truncated part updated): \(truncatedDiffWorkedCorrectly ? "✅" : "❌")")
        
        if truncatedDiffWorkedCorrectly {
            print("  SUCCESS: Truncated diff was correctly applied to full file (only changing the truncated section)")
        } else {
            print("  FAILURE: Truncated diff application failed")
            print("  Differences detected")
        }
        
        print("\n  Files available at:")
        print("    - Original: \(originalFileURL.path)")
        print("    - Truncated Source: \(truncatedFileURL.path)")
        print("    - Truncated Modified: \(truncatedModifiedFileURL.path)")
        print("    - Full Modified: \(modifiedFileURL.path)")
        print("    - Output: \(outputFileURL.path)")
        print("    - Truncated Diff: \(truncatedDiffFileURL.path)")
        
    } catch {
        print("  ERROR: \(error)")
    }
}

// Update the main function to call the new demonstration
func main() throws {
    let startTime = getCurrentTimeMs()
    print("🚀 MultiLineDiff Runner Started at: \(Date())")
    print("-----------------------------------")
    
    // Test empty strings
    runTest("Empty Strings") {
        let result = MultiLineDiff.createDiff(source: "", destination: "")
        return result.operations.isEmpty
    }
    
    // Test source only
    runTest("Source Only") {
        let source = "Hello, world!"
        let destination = ""
        
        let result = MultiLineDiff.createDiff(source: source, destination: destination)
        
        guard result.operations.count == 1 else { return false }
        if case .delete(let count) = result.operations[0] {
            return count == source.count
        }
        return false
    }
    
    // Run demonstrations
    print("=== MultiLineDiff Demonstrations ===\n")
    
    print("1. File-based diff operations:")
    demonstrateCodeFileDiff()
    
    print("\n2. Large file handling:")
    demonstrateLargeFileDiffWithPatterns()
    
    print("\n3. Algorithm comparison (Brus vs Todd):")
    demonstrateAlgorithmComparison()
    
    print("\n4. Base64 operations:")
    demonstrateBase64Diff()
    
    print("\n5. Truncated diff operations:")
    demonstrateTruncatedDiff()
    
    let endTime = getCurrentTimeMs()
    let totalExecutionTime = Double(endTime - startTime) / 1000.0
    
    print("-----------------------------------")
    print("🏁 MultiLineDiff Runner Completed")
    print("Start Time: \(Date(timeIntervalSince1970: Double(startTime) / 1000.0))")
    print("End Time: \(Date(timeIntervalSince1970: Double(endTime) / 1000.0))")
    print("Total Execution Time: \(String(format: "%.3f", totalExecutionTime)) seconds")
}

// Run the main function
do {
    try main()
} catch {
    print("Error in main function: \(error)")
}

