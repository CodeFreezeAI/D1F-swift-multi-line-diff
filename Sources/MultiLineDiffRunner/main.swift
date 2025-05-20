import Foundation
import MultiLineDiff

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
    let result = MultiLineDiff.createDiffBrus(source: "", destination: "")
    return result.operations.isEmpty
}

// Test source only
runTest("Source Only") {
    let source = "Hello, world!"
    let destination = ""
    
    let result = MultiLineDiff.createDiffBrus(source: source, destination: destination)
    
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
    
    let result = MultiLineDiff.createDiffBrus(source: source, destination: destination)
    
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
    
    let result = MultiLineDiff.createDiffBrus(source: source, destination: destination)
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
    
    let result = MultiLineDiff.createDiffBrus(source: source, destination: destination)
    let applied = try MultiLineDiff.applyDiff(to: source, diff: result)
    
    return applied == destination
}

// Test Unicode content
runTest("Unicode Content") {
    let source = "Hello, 世界!"
    let destination = "Hello, 世界! 🚀"
    
    let result = MultiLineDiff.createDiffBrus(source: source, destination: destination)
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
        let diff = MultiLineDiff.createDiffBrus(source: source, destination: destination)
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
        let tempDirURL = fileManager.temporaryDirectory.appendingPathComponent("MultiLineDiffDemo-\(UUID().uuidString)")
        
        // Create directory
        try fileManager.createDirectory(at: tempDirURL, withIntermediateDirectories: true)
        print("  Created temp directory at: \(tempDirURL.path)")
        
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
        
        let diff = MultiLineDiff.createDiffBrus(source: originalCodeContent, destination: updatedCodeContent)
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
        let tempDirURL = fileManager.temporaryDirectory.appendingPathComponent("MultiLineDiffLargeDemo-\(UUID().uuidString)")
        
        // Create directory
        try fileManager.createDirectory(at: tempDirURL, withIntermediateDirectories: true)
        print("  Created temp directory at: \(tempDirURL.path)")
        
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
        let diff = MultiLineDiff.createDiffBrus(source: originalContent, destination: modifiedContent)
        
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

// Execute real-world examples
demonstrateCodeFileDiff()
demonstrateLargeFileDiffWithPatterns()

// Example: Comparing bruss vs. Todd diff algorithm
func demonstrateToddDiff() {
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
            // Brus validation
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
            var isActive: Bool = true
            
            init(name: String, email: String, age: Int, isActive: Bool = true) {
                self.id = UUID()
                self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                self.email = email.lowercased()
                self.age = max(0, age)
                self.isActive = isActive
            }
            
            func greet() -> String {
                if isActive {
                    return "Hello, my name is \\(name)!"
                } else {
                    return "Account inactive"
                }
            }
            
            func toJSON() -> [String: Any] {
                return [
                    "id": id.uuidString,
                    "name": name,
                    "email": email,
                    "age": age,
                    "isActive": isActive
                ]
            }
        }
        
        // Helper functions
        func validateEmail(_ email: String) -> Bool {
            // Improved validation
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\\\.[A-Za-z]{2,}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            return emailPredicate.evaluate(with: email)
        }
        
        func createUser(name: String, email: String, age: Int, isActive: Bool = true) -> User? {
            guard validateEmail(email) else {
                return nil
            }
            guard age >= 0 else {
                return nil
            }
            return User(name: name, email: email, age: age, isActive: isActive)
        }
        """
        
        // Create temporary directory
        let fileManager = FileManager.default
        let tempDirURL = fileManager.temporaryDirectory.appendingPathComponent("MultiLineDiffToddDemo-\(UUID().uuidString)")
        
        // Create directory
        try fileManager.createDirectory(at: tempDirURL, withIntermediateDirectories: true)
        print("  Created temp directory at: \(tempDirURL.path)")
        
        // Save files
        let originalFileURL = tempDirURL.appendingPathComponent("User.swift")
        let modifiedFileURL = tempDirURL.appendingPathComponent("User.modified.swift")
        
        try sourceCode.data(using: .utf8)?.write(to: originalFileURL)
        try modifiedCode.data(using: .utf8)?.write(to: modifiedFileURL)
        
        // Create diffs with both algorithms
        let brussDiff = MultiLineDiff.createDiffBrus(source: sourceCode, destination: modifiedCode)
        let toddDiff = MultiLineDiff.createDiffTodd(source: sourceCode, destination: modifiedCode)
        
        // Save diffs to files
        let brussDiffFileURL = tempDirURL.appendingPathComponent("bruss_diff.json")
        let toddDiffFileURL = tempDirURL.appendingPathComponent("todd_diff.json")
        
        try MultiLineDiff.saveDiffToFile(brussDiff, fileURL: brussDiffFileURL)
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
        
        let brussOpCounts = countOperations(brussDiff)
        let toddOpCounts = countOperations(toddDiff)
        
        // Print comparison
        print("\n  Brus Diff Algorithm:")
        print("    -  Total operations: \(brussDiff.operations.count)")
        print("    - Retain operations: \(brussOpCounts.retain)")
        print("    - Insert operations: \(brussOpCounts.insert)")
        print("    - Delete operations: \(brussOpCounts.delete)")
        
        print("\n  Todd Diff Algorithm:")
        print("    -  Total operations: \(toddDiff.operations.count)")
        print("    - Retain operations: \(toddOpCounts.retain)")
        print("    - Insert operations: \(toddOpCounts.insert)")
        print("    - Delete operations: \(toddOpCounts.delete)")
        
        // Apply both diffs to verify they work
        let brussResult = try MultiLineDiff.applyDiff(to: sourceCode, diff: brussDiff)
        let toddResult = try MultiLineDiff.applyDiffTodd(to: sourceCode, diff: toddDiff)
        
        let brussMatches = brussResult == modifiedCode
        let toddMatches = toddResult == modifiedCode
        let bothFilesMatch = toddResult == brussResult
        
        print("\n  Results:")
        print("    - Brus diff correctly transforms source: \(brussMatches ? "✅" : "❌")")
        print("    - Todd diff correctly transforms source: \(toddMatches ? "✅" : "❌")")
        print("    - Todd = Brus results are a dead match!: \(bothFilesMatch ? "✅" : "❌")")

        print("\n  Files available at:")
        print("    - Original: \(originalFileURL.path)")
        print("    - Modified: \(modifiedFileURL.path)")
        print("    - Brus Diff: \(brussDiffFileURL.path)")
        print("    - Todd Diff: \(toddDiffFileURL.path)")

    } catch {
        print("  ❌ ERROR: \(error)")
    }
}

// Execute the Todd diff comparison
demonstrateToddDiff() 
