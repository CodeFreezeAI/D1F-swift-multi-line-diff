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
        print("\(success ? "✅ \(name): SUCCESS" : "❌ \(name): FAILED")")
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
   Line 42
   """
   
    let result = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .todd, sourceStartLine: 0)
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
       let diff = MultiLineDiff.createDiff(source: source, destination: destination)
       let result = try MultiLineDiff.applyDiff(to: source, diff: diff)
       if result != destination {
           print("  ❌ Round trip failed: \"\(result)\" != \"\(destination)\"")
           return false
       }
   }
   
   return true
}



// Example: Working with actual source code files
func demonstrateCodeFileDiff() -> Bool {
   do {
       // Create temporary directory
       let fileManager = FileManager.default
       let tempDirURL = fileManager.temporaryDirectory.appendingPathComponent("CODE_FILE_DIFF_DEMO-\(UUID().uuidString)")
       
       // Create directory
       try fileManager.createDirectory(at: tempDirURL, withIntermediateDirectories: true)
       
       // Original version of the view controller
       let originalCode = """
       import UIKit
       
       class ViewController: UIViewController {
           
           // UI Components
           public let tableView = UITableView()
           public var data: [String] = []
           
           override func viewDidLoad() {
               super.viewDidLoad()
               setupUI()
               loadData()
           }
           
           public func setupUI() {
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
           
           public func loadData() {
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
           public let tableView = UITableView()
           public let searchBar = UISearchBar()
           public var data: [String] = []
           public var filteredData: [String] = []
           
           override func viewDidLoad() {
               super.viewDidLoad()
               setupUI()
               loadData()
           }
           
           public func setupUI() {
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
           
           public func loadData() {
               data = ["Item 1", "Item 2", "Item 3", "Example 4", "Test 5"]
               filteredData = data
               tableView.reloadData()
           }
           
           public func filterContentForSearchText(_ searchText: String) {
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
       let diffFileURL = tempDirURL.appendingPathComponent("ViewControllerDiff.json")
       
       try originalCode.write(to: originalFileURL, atomically: true, encoding: .utf8)
       try updatedCode.write(to: updatedFileURL, atomically: true, encoding: .utf8)
       
       // Create diff between files
       let originalCodeContent = try String(contentsOf: originalFileURL, encoding: .utf8)
       let updatedCodeContent = try String(contentsOf: updatedFileURL, encoding: .utf8)
       
       let diff = MultiLineDiff.createDiff(source: originalCodeContent, destination: updatedCodeContent)
       
       // Save diff to file
       try MultiLineDiff.saveDiffToFile(diff, fileURL: diffFileURL)
       
       // Load diff back from file
       _ = try MultiLineDiff.loadDiffFromFile(fileURL: diffFileURL)
       
       // Apply diff
       let result = try MultiLineDiff.applyDiff(to: originalCodeContent, diff: diff)
       
       // Write result
       try result.write(to: outputFileURL, atomically: true, encoding: .utf8)
       
       // Verify
       let outputContent = try String(contentsOf: outputFileURL, encoding: .utf8)
       let success = outputContent == updatedCodeContent
       
       return success
       
   } catch {
       return false
   }
}

// Example: Working with large files and regular pattern changes
func demonstrateLargeFileDiffWithPatterns() -> Bool {
   do {
       // Create temporary directory
       let fileManager = FileManager.default
       let tempDirURL = fileManager.temporaryDirectory.appendingPathComponent("LARGE_FILE_DIFF_DEMO-\(UUID().uuidString)")
       
       // Create directory
       try fileManager.createDirectory(at: tempDirURL, withIntermediateDirectories: true)
       
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
       originalLines.append("    public func helperMethod() {")
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
       
       // Save diff to file
       try MultiLineDiff.saveDiffToFile(diff, fileURL: diffFileURL)
       
       // Load diff from file
       let loadedDiff = try MultiLineDiff.loadDiffFromFile(fileURL: diffFileURL)
       
       // Apply the loaded diff
       let result = try MultiLineDiff.applyDiff(to: originalContent, diff: loadedDiff)
       
       // Verify result matches expected
       let matches = result == modifiedContent
       
       // Save result
       try result.data(using: .utf8)?.write(to: outputFileURL)
       
       return matches
   } catch {
       return false
   }
}

// Example: Comparing Brus vs. Todd diff algorithm
func demonstrateAlgorithmComparison() -> Bool {
   do {
       // Create temporary directory
       let fileManager = FileManager.default
       let tempDirURL = fileManager.temporaryDirectory.appendingPathComponent("ALGORITHM_COMPARISON_DEMO-\(UUID().uuidString)")
       
       // Create directory
       try fileManager.createDirectory(at: tempDirURL, withIntermediateDirectories: true)
       
       // Original content with multiple sections and extra lines
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
       
       // Performance measurement function
       func measurePerformance(algorithm: DiffAlgorithm, runs: Int) -> (
           createDiffTime: Double, 
           applyDiffTime: Double, 
           totalTime: Double,
           diff: DiffResult
       ) {
           var totalCreateDiffTime: Int64 = 0
           var totalApplyDiffTime: Int64 = 0
           var diff: DiffResult = MultiLineDiff.createDiff(source: "", destination: "")
           
           for _ in 0..<runs {
               // Measure create diff time
               let createDiffStartTime = getCurrentTimeMs()
               diff = MultiLineDiff.createDiff(
                   source: sourceCode, 
                   destination: modifiedCode, 
                   algorithm: algorithm
               )
               let createDiffEndTime = getCurrentTimeMs()
               totalCreateDiffTime += (createDiffEndTime - createDiffStartTime)
               
               // Measure apply diff time
               let applyDiffStartTime = getCurrentTimeMs()
               _ = try? MultiLineDiff.applyDiff(to: sourceCode, diff: diff)
               let applyDiffEndTime = getCurrentTimeMs()
               totalApplyDiffTime += (applyDiffEndTime - applyDiffStartTime)
           }
           
           let averageCreateDiffTime = Double(totalCreateDiffTime) / Double(runs)
           let averageApplyDiffTime = Double(totalApplyDiffTime) / Double(runs)
           let totalAverageTime = averageCreateDiffTime + averageApplyDiffTime
           
           return (
               createDiffTime: averageCreateDiffTime, 
               applyDiffTime: averageApplyDiffTime, 
               totalTime: totalAverageTime,
               diff: diff
           )
       }
       
       // Measure performance for all 5 algorithms
       let runs = 1000
       let brusMeasurement = measurePerformance(algorithm: .zoom, runs: runs)
       let toddMeasurement = measurePerformance(algorithm: .todd, runs: runs)
       let sodaMeasurement = measurePerformance(algorithm: .flash, runs: runs)
       let lineMeasurement = measurePerformance(algorithm: .arrow, runs: runs)
       let drewMeasurement = measurePerformance(algorithm: .drew, runs: runs)
       
       // Analyze operations
       func analyzeOperations(_ diff: DiffResult) -> (
           totalOperations: Int, 
           retainCount: Int, 
           insertCount: Int, 
           deleteCount: Int,
           retainChars: Int,
           insertChars: Int,
           deleteChars: Int
       ) {
           var retainCount = 0
           var insertCount = 0
           var deleteCount = 0
           var retainChars = 0
           var insertChars = 0
           var deleteChars = 0
           
           for op in diff.operations {
               switch op {
               case .retain(let count): 
                   retainCount += 1
                   retainChars += count
               case .insert(let text): 
                   insertCount += 1
                   insertChars += text.count
               case .delete(let count): 
                   deleteCount += 1
                   deleteChars += count
               }
           }
           
           return (
               diff.operations.count, 
               retainCount, 
               insertCount, 
               deleteCount,
               retainChars,
               insertChars,
               deleteChars
           )
       }
       
       let brusStat = analyzeOperations(brusMeasurement.diff)
       let toddStat = analyzeOperations(toddMeasurement.diff)
       let sodaStat = analyzeOperations(sodaMeasurement.diff)
       let lineStat = analyzeOperations(lineMeasurement.diff)
       let drewStat = analyzeOperations(drewMeasurement.diff)
       
       // Print detailed operations for visualization
       func printDetailedOperations(_ diff: DiffResult, algorithmName: String) {
           print("\n=== \(algorithmName) Algorithm - Detailed Operations ===")
           for (index, op) in diff.operations.enumerated() {
               switch op {
               case .retain(let count):
                   print("Operation \(index + 1): RETAIN \(count) chars")
               case .insert(let text):
                   let truncatedText = text.count > 50 ? String(text.prefix(50)) + "..." : text
                   print("Operation \(index + 1): INSERT \(text.count) chars: \"\(truncatedText)\"")
               case .delete(let count):
                   print("Operation \(index + 1): DELETE \(count) chars")
               }
           }
       }
       
       // Print detailed operations for both algorithms
       // printDetailedOperations(brusMeasurement.diff, algorithmName: "Brus")
       // printDetailedOperations(toddMeasurement.diff, algorithmName: "Todd")
       
       // Print detailed comparison
       print("\n=== Diff Algorithm Comparison - All 5 Algorithms ===")
       print("Source Code Length: \(sourceCode.count) chars")
       print("Modified Code Length: \(modifiedCode.count) chars")
       print("Total Runs: \(runs)")
       
       print("\n--- \(AlgorithmNames.zoom) Algorithm ---")
       print("Total Operations: \(brusStat.totalOperations)")
       print("  - Retain Operations: \(brusStat.retainCount) (\(brusStat.retainChars) chars)")
       print("  - Insert Operations: \(brusStat.insertCount) (\(brusStat.insertChars) chars)")
       print("  - Delete Operations: \(brusStat.deleteCount) (\(brusStat.deleteChars) chars)")
       print("  - Create Diff Time: \(String(format: "%.4f", brusMeasurement.createDiffTime)) ms")
       print("  - Apply Diff Time: \(String(format: "%.4f", brusMeasurement.applyDiffTime)) ms")
       print("  - Total Time: \(String(format: "%.4f", brusMeasurement.totalTime)) ms")
       
       print("\n--- \(AlgorithmNames.todd) Algorithm ---")
       print("Total Operations: \(toddStat.totalOperations)")
       print("  - Retain Operations: \(toddStat.retainCount) (\(toddStat.retainChars) chars)")
       print("  - Insert Operations: \(toddStat.insertCount) (\(toddStat.insertChars) chars)")
       print("  - Delete Operations: \(toddStat.deleteCount) (\(toddStat.deleteChars) chars)")
       print("  - Create Diff Time: \(String(format: "%.4f", toddMeasurement.createDiffTime)) ms")
       print("  - Apply Diff Time: \(String(format: "%.4f", toddMeasurement.applyDiffTime)) ms")
       print("  - Total Time: \(String(format: "%.4f", toddMeasurement.totalTime)) ms")
       
       print("\n--- \(AlgorithmNames.flash) Algorithm ---")
       print("Total Operations: \(sodaStat.totalOperations)")
       print("  - Retain Operations: \(sodaStat.retainCount) (\(sodaStat.retainChars) chars)")
       print("  - Insert Operations: \(sodaStat.insertCount) (\(sodaStat.insertChars) chars)")
       print("  - Delete Operations: \(sodaStat.deleteCount) (\(sodaStat.deleteChars) chars)")
       print("  - Create Diff Time: \(String(format: "%.4f", sodaMeasurement.createDiffTime)) ms")
       print("  - Apply Diff Time: \(String(format: "%.4f", sodaMeasurement.applyDiffTime)) ms")
       print("  - Total Time: \(String(format: "%.4f", sodaMeasurement.totalTime)) ms")
       
       print("\n--- \(AlgorithmNames.arrow) Algorithm ---")
       print("Total Operations: \(lineStat.totalOperations)")
       print("  - Retain Operations: \(lineStat.retainCount) (\(lineStat.retainChars) chars)")
       print("  - Insert Operations: \(lineStat.insertCount) (\(lineStat.insertChars) chars)")
       print("  - Delete Operations: \(lineStat.deleteCount) (\(lineStat.deleteChars) chars)")
       print("  - Create Diff Time: \(String(format: "%.4f", lineMeasurement.createDiffTime)) ms")
       print("  - Apply Diff Time: \(String(format: "%.4f", lineMeasurement.applyDiffTime)) ms")
       print("  - Total Time: \(String(format: "%.4f", lineMeasurement.totalTime)) ms")
       
       print("\n--- \(AlgorithmNames.drew) Algorithm ---")
       print("Total Operations: \(drewStat.totalOperations)")
       print("  - Retain Operations: \(drewStat.retainCount) (\(drewStat.retainChars) chars)")
       print("  - Insert Operations: \(drewStat.insertCount) (\(drewStat.insertChars) chars)")
       print("  - Delete Operations: \(drewStat.deleteCount) (\(drewStat.deleteChars) chars)")
       print("  - Create Diff Time: \(String(format: "%.4f", drewMeasurement.createDiffTime)) ms")
       print("  - Apply Diff Time: \(String(format: "%.4f", drewMeasurement.applyDiffTime)) ms")
       print("  - Total Time: \(String(format: "%.4f", drewMeasurement.totalTime)) ms")
       
       // Performance comparison across all algorithms
       let measurements = [
           (AlgorithmNames.zoom, brusMeasurement),
           (AlgorithmNames.todd, toddMeasurement),
           (AlgorithmNames.flash, sodaMeasurement),
           (AlgorithmNames.arrow, lineMeasurement),
           (AlgorithmNames.drew, drewMeasurement)
       ]
       
       let fastestCreateDiff = measurements.min { $0.1.createDiffTime < $1.1.createDiffTime }!
       let fastestApplyDiff = measurements.min { $0.1.applyDiffTime < $1.1.applyDiffTime }!
       let fastestTotalTime = measurements.min { $0.1.totalTime < $1.1.totalTime }!
       
       let slowestCreateDiff = measurements.max { $0.1.createDiffTime < $1.1.createDiffTime }!
       let slowestApplyDiff = measurements.max { $0.1.applyDiffTime < $1.1.applyDiffTime }!
       let slowestTotalTime = measurements.max { $0.1.totalTime < $1.1.totalTime }!
       
       print("\n--- Performance Summary (All 5 Algorithms) ---")
       print("🏆 Fastest Create Diff: \(fastestCreateDiff.0) (\(String(format: "%.4f", fastestCreateDiff.1.createDiffTime)) ms)")
       print("🐌 Slowest Create Diff: \(slowestCreateDiff.0) (\(String(format: "%.4f", slowestCreateDiff.1.createDiffTime)) ms)")
       print("📊 Create Diff Speed Range: \(String(format: "%.4f", slowestCreateDiff.1.createDiffTime - fastestCreateDiff.1.createDiffTime)) ms")
       
       print("🏆 Fastest Apply Diff: \(fastestApplyDiff.0) (\(String(format: "%.4f", fastestApplyDiff.1.applyDiffTime)) ms)")
       print("🐌 Slowest Apply Diff: \(slowestApplyDiff.0) (\(String(format: "%.4f", slowestApplyDiff.1.applyDiffTime)) ms)")
       print("📊 Apply Diff Speed Range: \(String(format: "%.4f", slowestApplyDiff.1.applyDiffTime - fastestApplyDiff.1.applyDiffTime)) ms")
       
       print("🏆 Fastest Total Time: \(fastestTotalTime.0) (\(String(format: "%.4f", fastestTotalTime.1.totalTime)) ms)")
       print("🐌 Slowest Total Time: \(slowestTotalTime.0) (\(String(format: "%.4f", slowestTotalTime.1.totalTime)) ms)")
       print("📊 Total Time Speed Range: \(String(format: "%.4f", slowestTotalTime.1.totalTime - fastestTotalTime.1.totalTime)) ms")
       
       // Speed ratios relative to fastest
       print("\n--- Speed Ratios (relative to fastest) ---")
       for (name, measurement) in measurements {
           let createRatio = measurement.createDiffTime / fastestCreateDiff.1.createDiffTime
           let applyRatio = measurement.applyDiffTime / fastestApplyDiff.1.applyDiffTime
           let totalRatio = measurement.totalTime / fastestTotalTime.1.totalTime
           print("\(name): Create \(String(format: "%.2f", createRatio))x, Apply \(String(format: "%.2f", applyRatio))x, Total \(String(format: "%.2f", totalRatio))x")
       }
       print("")
       
       // Apply all diffs to verify they work
       let brusResult = try MultiLineDiff.applyDiff(to: sourceCode, diff: brusMeasurement.diff)
       let toddResult = try MultiLineDiff.applyDiff(to: sourceCode, diff: toddMeasurement.diff)
       let sodaResult = try MultiLineDiff.applyDiff(to: sourceCode, diff: sodaMeasurement.diff)
       let lineResult = try MultiLineDiff.applyDiff(to: sourceCode, diff: lineMeasurement.diff)
       let drewResult = try MultiLineDiff.applyDiff(to: sourceCode, diff: drewMeasurement.diff)
       
       let brusMatches = brusResult == modifiedCode
       let toddMatches = toddResult == modifiedCode
       let sodaMatches = sodaResult == modifiedCode
       let lineMatches = lineResult == modifiedCode
       let drewMatches = drewResult == modifiedCode
       
       let allResultsMatch = brusResult == toddResult && toddResult == sodaResult && 
                            sodaResult == lineResult && lineResult == drewResult
       
       print("--- Verification Results ---")
       print("✅ All algorithms produce correct results: \(brusMatches && toddMatches && sodaMatches && lineMatches && drewMatches)")
       print("✅ All algorithms produce identical results: \(allResultsMatch)")

       return brusMatches && toddMatches && sodaMatches && lineMatches && drewMatches && allResultsMatch

   } catch {
       return false
   }
}

func demonstrateBase64Diff() -> Bool {
   do {
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
       _ = try MultiLineDiff.diffFromBase64(base64Diff)
       _ = try MultiLineDiff.decodeDiffFromJSONString(jsonString)
       
       // Format comparison
       _ = base64Diff.data(using: .utf8)?.count ?? 0
       _ = jsonString.data(using: .utf8)?.count ?? 0
       
       // Apply base64 diff
       let result = try MultiLineDiff.applyBase64Diff(to: source, base64Diff: base64Diff)
       let success = result == destination
       
       return success
       
   } catch {
       return false
   }
}

// Example: Working with truncated diffs - demonstrating both use cases
func demonstrateTruncatedDiff() -> Bool {
    
    
    do {
      
        // Original content with multiple sections and extra lines
        let originalContent = """
        # Document Header
        This is the document header with important context.
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
        
        let truncatedModifiedContent = """
        ## Section 2: New Content
        Line 3: UPDATED main section content
        Line 4: Comprehensive explanation of the main section
        
        ## Section 3: Conclusion
        Line 5: Enhanced remarks
        Line 6: Expanded thoughts
        """
        
        // Modified content with changes (matches the new structure)
        let modifiedContent = """
        # Document Header
        This is the document header with important context.
        Additional header information and metadata.
        
        ## Section 1: Initial Content
        Line 1: Original first section content
        Line 2: More details about the first section
        Line 2a: Some additional context in the first section
        Line 2b: Even more information that wasn't here before
        
        ## Section 2: New Content
        Line 3: UPDATED main section content
        Line 4: Comprehensive explanation of the main section
        
        ## Section 3: Conclusion
        Line 5: Enhanced remarks
        Line 6: Expanded thoughts
        
        ## Section 4: Extra Content
        Line 7: This is completely new section not in the truncated content
        Line 8: Another line that doesn't exist in the truncated version
        """
        
        let truncatedDiff = MultiLineDiff.createDiff(
            source: truncatedContent,
            destination: truncatedModifiedContent,
            algorithm: .todd,
            includeMetadata: true
        )
        
               // Apply the truncated diff to the full original file
        let resultFromTruncated = try MultiLineDiff.applyDiff(
            to: originalContent,
            diff: truncatedDiff
        )
        
        // Check if the result matches the partially modified output
        let truncatedDiffWorkedCorrectly = modifiedContent == resultFromTruncated
    
        return truncatedDiffWorkedCorrectly
        
    } catch {
        return false
    }
}

// Update the main function to call the new demonstration
func main() throws {
    let startTime = getCurrentTimeMs()
    
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
   runTest("File-based diff operations") {
       return demonstrateCodeFileDiff()
   }
   
   runTest("Large file handling") {
       return demonstrateLargeFileDiffWithPatterns()
   }
   
   runTest("Algorithm comparison (All 5 Algorithms)") {
       return demonstrateAlgorithmComparison()
   }
   
   runTest("Base64 operations") {
       return demonstrateBase64Diff()
   }
   
    runTest("Truncated diff operations") {
        return demonstrateTruncatedDiff()
    }
    
    print("\n" + String(repeating: "=", count: 50))
    print("Running test: Enhanced Truncated Diff with Dual Context")
    runTest("Enhanced Truncated Diff with Dual Context") {
        return demonstrateEnhancedTruncatedDiff()
     }

    print("\n" + String(repeating: "=", count: 50))
    print("Running test: SmartDiff Base64 Methods")
    runTest("SmartDiff Base64 Methods") {
        demonstrateSmartDiffBase64Methods()
        return true
    }

    print("\n" + String(repeating: "=", count: 50))
    print("Running test: README Example 3 Algorithm Verification")
    runTest("README Example 3 Algorithm Verification") {
        demonstrateReadmeExample3()
        return true
    }
    
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

