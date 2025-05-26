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
   
    let result = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .megatron, sourceStartLine: 0)
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
       let toddMeasurement = measurePerformance(algorithm: .megatron, runs: runs)
       let sodaMeasurement = measurePerformance(algorithm: .flash, runs: runs)
       let lineMeasurement = measurePerformance(algorithm: .starscream, runs: runs)
       let drewMeasurement = measurePerformance(algorithm: .optimus, runs: runs)
       
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
       
       print("\n--- \(AlgorithmNames.megatron) Algorithm ---")
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
       
       print("\n--- \(AlgorithmNames.starscream) Algorithm ---")
       print("Total Operations: \(lineStat.totalOperations)")
       print("  - Retain Operations: \(lineStat.retainCount) (\(lineStat.retainChars) chars)")
       print("  - Insert Operations: \(lineStat.insertCount) (\(lineStat.insertChars) chars)")
       print("  - Delete Operations: \(lineStat.deleteCount) (\(lineStat.deleteChars) chars)")
       print("  - Create Diff Time: \(String(format: "%.4f", lineMeasurement.createDiffTime)) ms")
       print("  - Apply Diff Time: \(String(format: "%.4f", lineMeasurement.applyDiffTime)) ms")
       print("  - Total Time: \(String(format: "%.4f", lineMeasurement.totalTime)) ms")
       
       print("\n--- \(AlgorithmNames.optimus) Algorithm ---")
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
           (AlgorithmNames.megatron, toddMeasurement),
           (AlgorithmNames.flash, sodaMeasurement),
           (AlgorithmNames.starscream, lineMeasurement),
           (AlgorithmNames.optimus, drewMeasurement)
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
            algorithm: .megatron,
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

func demonstrateTerminalDiffOutput() {
    print("\n" + String(repeating: "=", count: 60))
    print("🖥️  TERMINAL DIFF OUTPUT DEMONSTRATION")
    print(String(repeating: "=", count: 60))
    
    let sourceCode = """
    class UserManager {
        private var users: [String: User] = [:]
        
        func addUser(name: String, email: String) -> Bool {
            guard !name.isEmpty && !email.isEmpty else {
                return false
            }
            
            let user = User(name: name, email: email)
            users[email] = user
            return true
        }
        
        func getUser(by email: String) -> User? {
            return users[email]
        }
        
        func removeUser(email: String) {
            users.removeValue(forKey: email)
        }
        
        func getAllUsers() -> [User] {
            return Array(users.values)
        }
    }
    
    struct User {
        let name: String
        let email: String
    }
    """
    
    let destinationCode = """
    class UserManager {
        private var users: [String: User] = [:]
        private var userCount: Int = 0
        
        func addUser(name: String, email: String, age: Int = 0) -> Result<User, UserError> {
            guard !name.isEmpty && !email.isEmpty else {
                return .failure(.invalidInput)
            }
            
            guard !users.keys.contains(email) else {
                return .failure(.userAlreadyExists)
            }
            
            let user = User(id: UUID(), name: name, email: email, age: age)
            users[email] = user
            userCount += 1
            return .success(user)
        }
        
        func getUser(by email: String) -> User? {
            return users[email]
        }
        
        func removeUser(email: String) -> Bool {
            guard users[email] != nil else { return false }
            users.removeValue(forKey: email)
            userCount -= 1
            return true
        }
        
        func getAllUsers() -> [User] {
            return Array(users.values).sorted { $0.name < $1.name }
        }
        
        var count: Int {
            return userCount
        }
    }
    
    struct User {
        let id: UUID
        let name: String
        let email: String
        let age: Int
    }
    
    enum UserError: Error {
        case invalidInput
        case userAlreadyExists
    }
    """
    
    print("\n📝 ASCII DIFF OUTPUT:")
    print(String(repeating: "-", count: 40))
    let asciiDiff = MultiLineDiff.generateASCIIDiff(
        source: sourceCode,
        destination: destinationCode,
        algorithm: .megatron
    )
    print(asciiDiff)
    
    print("\n🌈 COLORED TERMINAL DIFF OUTPUT:")
    print(String(repeating: "-", count: 40))
    let coloredDiff = MultiLineDiff.generateColoredTerminalDiff(
        source: sourceCode,
        destination: destinationCode,
        algorithm: .megatron
    )
    print(coloredDiff)
    
    print("\n✨ HIGHLIGHTED TERMINAL DIFF OUTPUT:")
    print(String(repeating: "-", count: 40))
    let highlightedDiff = MultiLineDiff.generateHighlightedTerminalDiff(
        source: sourceCode,
        destination: destinationCode,
        algorithm: .megatron
    )
    print(highlightedDiff)
    
    print("\n📊 DIFF SUMMARY:")
    print(String(repeating: "-", count: 40))
    let summary = MultiLineDiff.generateDiffSummary(
        source: sourceCode,
        destination: destinationCode,
        algorithm: .megatron
    )
    print(summary)
    
    print("\n🤖 AI-FRIENDLY ASCII DIFF (for sending to AI models):")
    print(String(repeating: "-", count: 40))
    print("```swift")
    print(asciiDiff.trimmingCharacters(in: .whitespacesAndNewlines))
    print("```")
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
    
    print("\n" + String(repeating: "=", count: 50))
    print("Running test: Terminal Diff Output Demonstration")
    demonstrateTerminalDiffOutput()
    
    print("\n" + String(repeating: "=", count: 60))
    print("🎯 FINAL OUTPUT DEMONSTRATION FOR AI AND TERMINAL")
    print(String(repeating: "=", count: 60))
    
    let simpleSource = """
    class UserManager {
        private var users: [String: User] = [:]
        
        func addUser(name: String, email: String) -> Bool {
            guard !name.isEmpty && !email.isEmpty else {
                return false
            }
            
            let user = User(name: name, email: email)
            users[email] = user
            return true
        }
    }
    """
    
    let simpleDestination = """
    class UserManager {
        private var users: [String: User] = [:]
        private var userCount: Int = 0
        
        func addUser(name: String, email: String, age: Int = 0) -> Result<User, UserError> {
            guard !name.isEmpty && !email.isEmpty else {
                return .failure(.invalidInput)
            }
            
            let user = User(id: UUID(), name: name, email: email, age: age)
            users[email] = user
            userCount += 1
            return .success(user)
        }
    }
    """
    
    print("\n🤖 WHAT AI MODELS WILL RECEIVE (ASCII):")
    print("```swift")
    let aiOutput = MultiLineDiff.generateASCIIDiff(
        source: simpleSource,
        destination: simpleDestination,
        algorithm: .megatron
    )
    print(aiOutput)
    print("```")
    
    print("\n🖥️  WHAT TERMINAL USERS WILL SEE (COLORED):")
    print("Legend: \u{001B}[34m= retain (blue)\u{001B}[0m | \u{001B}[32m+ insert (green)\u{001B}[0m | \u{001B}[31m- delete (red)\u{001B}[0m")
    print(String(repeating: "-", count: 50))
    let terminalOutput = MultiLineDiff.generateColoredTerminalDiff(
        source: simpleSource,
        destination: simpleDestination,
        algorithm: .megatron
    )
    print(terminalOutput)
    
    print("\n" + String(repeating: "=", count: 60))
    print("🆕 NEW DISPLAY METHODS DEMONSTRATION")
    print(String(repeating: "=", count: 60))
    
    // Demonstrate the new displayDiff method
    print("\n📋 Using displayDiff method:")
    let diff = MultiLineDiff.createDiff(
        source: simpleSource,
        destination: simpleDestination,
        algorithm: .flash
    )
    
    print("\n🤖 AI Format (using displayDiff):")
    let aiDisplayOutput = MultiLineDiff.displayDiff(
        diff: diff,
        source: simpleSource,
        format: .ai
    )
    print("```swift")
    print(aiDisplayOutput)
    print("```")
    
    print("\n🖥️ Terminal Format (using displayDiff):")
    let terminalDisplayOutput = MultiLineDiff.displayDiff(
        diff: diff,
        source: simpleSource,
        format: .terminal
    )
    print(terminalDisplayOutput)
    
    // Demonstrate the new createAndDisplayDiff convenience method
    print("\n🚀 Using createAndDisplayDiff convenience method:")
    
    print("\n🤖 AI Format (one-liner):")
    let aiConvenienceOutput = MultiLineDiff.createAndDisplayDiff(
        source: simpleSource,
        destination: simpleDestination,
        format: .ai,
        algorithm: .starscream
    )
    print("```swift")
    print(aiConvenienceOutput)
    print("```")
    
    print("\n🖥️ Terminal Format (one-liner):")
    let terminalConvenienceOutput = MultiLineDiff.createAndDisplayDiff(
        source: simpleSource,
        destination: simpleDestination,
        format: .terminal,
        algorithm: .starscream
    )
    print(terminalConvenienceOutput)
    
    print("\n💡 Usage Examples:")
    print("   // For AI models:")
    print("   let aiDiff = MultiLineDiff.createAndDisplayDiff(")
    print("       source: oldCode, destination: newCode, format: .ai)")
    print("   ")
    print("   // For terminal display:")
    print("   let coloredDiff = MultiLineDiff.createAndDisplayDiff(")
    print("       source: oldCode, destination: newCode, format: .terminal)")
    print("   print(coloredDiff)")
    
    print("\n" + String(repeating: "=", count: 60))
    print("🎯 ASCII DIFF PARSING DEMONSTRATION")
    print(String(repeating: "=", count: 60))
    
    // Demonstrate the grand finale: parsing ASCII diffs submitted by AI
    let originalSourceCode = """
    func calculate() -> Int {
        return 42
    }
    """
    
    // Simulate an AI submitting this diff
    let aiSubmittedDiff = """
    = func calculate() -> Int {
    -     return 42
    +     return 100
    = }
    """
    
    print("\n🤖 AI SUBMITS THIS DIFF:")
    print("```swift")
    print(aiSubmittedDiff)
    print("```")
    
    do {
        // Parse the AI's diff
        let parsedDiff = try MultiLineDiff.parseDiffFromASCII(aiSubmittedDiff)
        
        print("\n📋 PARSED OPERATIONS:")
        for (i, op) in parsedDiff.operations.enumerated() {
            switch op {
            case .retain(let count):
                print("   \(i): RETAIN(\(count) chars)")
            case .delete(let count):
                print("   \(i): DELETE(\(count) chars)")
            case .insert(let text):
                print("   \(i): INSERT(\(text.count) chars): \"\(text)\"")
            }
        }
        
        // Apply the parsed diff
        let result = try MultiLineDiff.applyDiff(to: originalSourceCode, diff: parsedDiff)
        
        print("\n✅ RESULT AFTER APPLYING AI'S DIFF:")
        print("```swift")
        print(result)
        print("```")
        
        // Verify it worked
        let expectedResult = """
        func calculate() -> Int {
            return 100
        }
        """
        
        let success = result == expectedResult
        print("\n🎯 SUCCESS: \(success ? "✅" : "❌")")
        
        if success {
            print("🚀 AI can now submit diffs in readable ASCII format!")
            print("🔄 Round-trip workflow: Create → Display → Parse → Apply")
        } else {
            print("❌ Result doesn't match expected output")
            print("Expected: '\(expectedResult)'")
            print("Got: '\(result)'")
        }
        
    } catch {
        print("❌ Error parsing or applying ASCII diff: \(error)")
    }
    
    let endTime = getCurrentTimeMs()
    let totalExecutionTime = Double(endTime - startTime) / 1000.0
    
    print("-----------------------------------")
    print("🏁 MultiLineDiff Runner Completed")
    print("Start Time: \(Date(timeIntervalSince1970: Double(startTime) / 1000.0))")
    print("End Time: \(Date(timeIntervalSince1970: Double(endTime) / 1000.0))")
    print("Total Execution Time: \(String(format: "%.3f", totalExecutionTime)) seconds")
    
    // MARK: - ASCII Diff Workflow Demonstration
    
    print("\n" + String(repeating: "=", count: 60))
    print("🎯 ASCII DIFF WORKFLOW DEMONSTRATION")
    print(String(repeating: "=", count: 60))
    
    // Example 1: Simple function change
    let source1 = """
    func greet() {
        print("Hello")
    }
    """
    
    let destination1 = """
    func greet() {
        print("Hello, World!")
    }
    """
    
    print("\n📝 Example 1: Simple Function Change")
    print("Source:")
    print(source1)
    print("\nDestination:")
    print(destination1)
    
    do {
        let demo1 = try MultiLineDiff.demonstrateASCIIWorkflow(
            source: source1,
            destination: destination1,
            algorithm: .megatron
        )
        
        print("\n📄 Generated ASCII Diff:")
        print(demo1.asciiDiff)
        
        print("\n📊 Summary:")
        print(demo1.summary)
        
    } catch {
        print("❌ Demo 1 failed: \(error)")
    }
    
    // Example 2: Class modification
    let source2 = """
    class Calculator {
        func add(a: Int, b: Int) -> Int {
            return a + b
        }
    }
    """
    
    let destination2 = """
    class Calculator {
        func add(a: Int, b: Int) -> Int {
            return a + b
        }
        
        func multiply(a: Int, b: Int) -> Int {
            return a * b
        }
    }
    """
    
    print("\n" + String(repeating: "-", count: 50))
    print("📝 Example 2: Class Method Addition")
    print("Source:")
    print(source2)
    print("\nDestination:")
    print(destination2)
    
    do {
        let demo2 = try MultiLineDiff.demonstrateASCIIWorkflow(
            source: source2,
            destination: destination2,
            algorithm: .flash
        )
        
        print("\n📄 Generated ASCII Diff:")
        print(demo2.asciiDiff)
        
        print("\n📊 Summary:")
        print(demo2.summary)
        
    } catch {
        print("❌ Demo 2 failed: \(error)")
    }
    
    // Example 3: AI-style diff submission
    print("\n" + String(repeating: "-", count: 50))
    print("🤖 Example 3: AI Diff Submission Simulation")
    
    let aiSourceCode = """
    func calculate() -> Int {
        return 42
    }
    """
    
    let aiDiffSubmission = """
    = func calculate() -> Int {
    -     return 42
    +     return 100
    = }
    """
    
    print("AI receives source code:")
    print(aiSourceCode)
    print("\nAI submits this diff:")
    print(aiDiffSubmission)
    
    do {
        print("\n🔄 Applying AI's diff...")
        let aiResult = try MultiLineDiff.applyASCIIDiff(
            to: aiSourceCode,
            asciiDiff: aiDiffSubmission
        )
        
        print("✅ Result:")
        print(aiResult)
        
        let expectedResult = """
        func calculate() -> Int {
            return 100
        }
        """
        
        let success = aiResult == expectedResult
        print("\n🎯 Success: \(success ? "✅" : "❌")")
        
        if success {
            print("🚀 AI can now submit diffs in readable ASCII format!")
        }
        
    } catch {
        print("❌ AI demo failed: \(error)")
    }
    
    print("\n" + String(repeating: "=", count: 60))
    print("🎉 ASCII DIFF DEMONSTRATIONS COMPLETED")
    print(String(repeating: "=", count: 60))

    // Run the UserManager test
    runUserManagerASCIIDiffTest()

    // MARK: - AI Generated Diff Test

    func testAIGeneratedDiff() {
        print("\n🤖 AI Generated Diff Test")
        print(String(repeating: "=", count: 50))
        
        let fullSourceCode = """
        import Foundation
        
        class Calculator {
            private var history: [String] = []
            
            func add(a: Int, b: Int) -> Int {
                let result = a + b
                history.append("\\(a) + \\(b) = \\(result)")
                return result
            }
            
            func subtract(a: Int, b: Int) -> Int {
                let result = a - b
                history.append("\\(a) - \\(b) = \\(result)")
                return result
            }
            
            func getHistory() -> [String] {
                return history
            }
            
            func clearHistory() {
                history.removeAll()
            }
        }
        """
        
        // AI submits a COMPLETE diff covering the entire source
        let aiSubmittedDiff = """
        = import Foundation
        = 
        = class Calculator {
        =     private var history: [String] = []
        =     
        -     func add(a: Int, b: Int) -> Int {
        +     func add(a: Int, b: Int) -> Int {
        +         print("Adding \\(a) and \\(b)")
        =         let result = a + b
        =         history.append("\\(a) + \\(b) = \\(result)")
        =         return result
        =     }
        =     
        =     func subtract(a: Int, b: Int) -> Int {
        =         let result = a - b
        =         history.append("\\(a) - \\(b) = \\(result)")
        =         return result
        =     }
        =     
        =     func getHistory() -> [String] {
        =         return history
        =     }
        =     
        =     func clearHistory() {
        =         history.removeAll()
        =     }
        = }
        """
        
        print("📝 Full Source Code:")
        print(fullSourceCode)
        
        print("\n🤖 AI Submitted Diff:")
        print(aiSubmittedDiff)
        
        do {
            // Step 1: Create AI-generated diff with metadata
            print("\n🔄 Step 1: Creating AI-generated diff with metadata...")
            let aiDiff = try MultiLineDiff.createAIGeneratedDiff(
                originalSource: fullSourceCode,
                aiSubmittedDiff: aiSubmittedDiff,
                contextLines: 3
            )
            
            print("✅ Created AI diff with \(aiDiff.operations.count) operations")
            
            // Display metadata
            if let metadata = aiDiff.metadata {
                print("\n📊 AI Diff Metadata:")
                print("   Algorithm: \(metadata.algorithmUsed?.displayName ?? "Unknown")")
                print("   Start Line: \(metadata.sourceStartLine ?? 0)")
                print("   Total Lines: \(metadata.sourceTotalLines ?? 0)")
                print("   Preceding Context: \"\(metadata.precedingContext?.prefix(30) ?? "None")...\"")
                print("   Following Context: \"\(metadata.followingContext?.prefix(30) ?? "None")...\"")
                print("   Application Type: \(metadata.applicationType?.rawValue ?? "Unknown")")
            }
            
            // Step 2: Apply the AI-generated diff
            print("\n🔄 Step 2: Applying AI-generated diff...")
            let result = try MultiLineDiff.applyAIGeneratedDiff(
                to: fullSourceCode,
                aiDiffResult: aiDiff
            )
            
            print("\n✅ Result:")
            print(result)
            
            // Step 3: Verify the change was applied correctly
            let expectedChange = "print(\"Adding \\(a) and \\(b)\")"
            let success = result.contains(expectedChange)
            
            print("\n🎯 Verification:")
            print("   Contains expected change: \(success ? "✅" : "❌")")
            print("   Expected: \(expectedChange)")
            
            if success {
                print("\n🎉 AI-generated diff test completed successfully!")
                print("🚀 AI can now submit diffs with rich metadata tracking!")
            } else {
                print("\n❌ AI-generated diff test failed!")
            }
            
        } catch {
            print("❌ Error: \(error)")
        }
        
        print("\n" + String(repeating: "=", count: 50))
        print("🏁 AI Generated Diff Test Completed")
    }

    // Run the AI Generated Diff test
    testAIGeneratedDiff()

    // MARK: - ASCII Diff Round-Trip Demonstration

    func demonstrateASCIIRoundTrip() {
        print("\n🔄 ASCII Diff Round-Trip Demonstration")
        print(String(repeating: "=", count: 60))
        
        let sourceCode = """
        class UserManager {
            private var users: [String: User] = [:]
            
            func addUser(name: String, email: String) -> Bool {
                guard !name.isEmpty && !email.isEmpty else {
                    return false
                }
                
                let user = User(name: name, email: email)
                users[email] = user
                return true
            }
            
            func getUser(by email: String) -> User? {
                return users[email]
            }
        }
        
        struct User {
            let name: String
            let email: String
        }
        """
        
        let destinationCode = """
        class UserManager {
            private var users: [String: User] = [:]
            private var userCount: Int = 0
            
            func addUser(name: String, email: String, age: Int = 0) -> Result<User, UserError> {
                guard !name.isEmpty && !email.isEmpty else {
                    return .failure(.invalidInput)
                }
                
                let user = User(id: UUID(), name: name, email: email, age: age)
                users[email] = user
                userCount += 1
                return .success(user)
            }
            
            func getUser(by email: String) -> User? {
                return users[email]
            }
            
            var count: Int {
                return userCount
            }
        }
        
        struct User {
            let id: UUID
            let name: String
            let email: String
            let age: Int
        }
        
        enum UserError: Error {
            case invalidInput
            case userAlreadyExists
        }
        """
        
        print("📝 Source Code:")
        print(sourceCode)
        
        print("\n📝 Destination Code:")
        print(destinationCode)
        
        do {
            // STEP 1: Create diff and convert to ASCII
            print("\n🔄 STEP 1: Creating diff and converting to ASCII...")
            let originalDiff = MultiLineDiff.createDiff(
                source: sourceCode,
                destination: destinationCode,
                algorithm: .megatron
            )
            
            let asciiDiff1 = MultiLineDiff.displayDiff(
                diff: originalDiff,
                source: sourceCode,
                format: .ai
            )
            
            print("✅ Generated ASCII diff (\(asciiDiff1.count) characters)")
            print("\n📄 ASCII Diff #1 (Original):")
            print(asciiDiff1)
            
            // STEP 2: Parse ASCII diff back to operations
            print("\n🔄 STEP 2: Parsing ASCII diff back to operations...")
            let parsedDiff = try MultiLineDiff.parseDiffFromASCII(asciiDiff1)
            print("✅ Parsed \(parsedDiff.operations.count) operations")
            
            print("\n📊 Parsed Operations:")
            for (i, op) in parsedDiff.operations.enumerated() {
                switch op {
                case .retain(let count):
                    print("   \(i + 1). RETAIN(\(count) chars)")
                case .delete(let count):
                    print("   \(i + 1). DELETE(\(count) chars)")
                case .insert(let text):
                    let preview = text.count > 50 ? String(text.prefix(50)) + "..." : text
                    print("   \(i + 1). INSERT(\(text.count) chars): \"\(preview)\"")
                }
            }
            
            // STEP 3: Apply parsed diff to verify it works
            print("\n🔄 STEP 3: Applying parsed diff to source...")
            let appliedResult = try MultiLineDiff.applyDiff(to: sourceCode, diff: parsedDiff)
            let step3Success = appliedResult == destinationCode
            print("✅ Applied diff successfully: \(step3Success ? "✅" : "❌")")
            
            // STEP 4: Convert parsed diff back to ASCII (round-trip)
            print("\n🔄 STEP 4: Converting parsed diff back to ASCII...")
            let asciiDiff2 = MultiLineDiff.displayDiff(
                diff: parsedDiff,
                source: sourceCode,
                format: .ai
            )
            
            print("✅ Generated ASCII diff #2 (\(asciiDiff2.count) characters)")
            print("\n📄 ASCII Diff #2 (Round-Trip):")
            print(asciiDiff2)
            
            // STEP 5: Compare the two ASCII diffs
            print("\n🔄 STEP 5: Comparing ASCII diffs...")
            let asciiMatches = asciiDiff1 == asciiDiff2
            print("✅ ASCII diffs match: \(asciiMatches ? "✅" : "❌")")
            
            if !asciiMatches {
                print("\n🔍 Differences found:")
                print("Original length: \(asciiDiff1.count)")
                print("Round-trip length: \(asciiDiff2.count)")
                
                let lines1 = asciiDiff1.components(separatedBy: .newlines)
                let lines2 = asciiDiff2.components(separatedBy: .newlines)
                
                for (i, (line1, line2)) in zip(lines1, lines2).enumerated() {
                    if line1 != line2 {
                        print("Line \(i + 1) differs:")
                        print("  Original:   '\(line1)'")
                        print("  Round-trip: '\(line2)'")
                        break
                    }
                }
            }
            
            // STEP 6: Parse the round-trip ASCII and apply it
            print("\n🔄 STEP 6: Testing round-trip ASCII diff...")
            let finalParsedDiff = try MultiLineDiff.parseDiffFromASCII(asciiDiff2)
            let finalResult = try MultiLineDiff.applyDiff(to: sourceCode, diff: finalParsedDiff)
            let finalSuccess = finalResult == destinationCode
            print("✅ Round-trip diff works: \(finalSuccess ? "✅" : "❌")")
            
            // STEP 7: Summary
            print("\n🎯 ROUND-TRIP SUMMARY:")
            print("   📊 Original operations: \(originalDiff.operations.count)")
            print("   📊 Parsed operations: \(parsedDiff.operations.count)")
            print("   📊 Final operations: \(finalParsedDiff.operations.count)")
            print("   📄 ASCII diff 1 length: \(asciiDiff1.count)")
            print("   📄 ASCII diff 2 length: \(asciiDiff2.count)")
            print("   ✅ Step 3 success: \(step3Success)")
            print("   ✅ ASCII diffs match: \(asciiMatches)")
            print("   ✅ Final result correct: \(finalSuccess)")
            
            let overallSuccess = step3Success && asciiMatches && finalSuccess
            
            if overallSuccess {
                print("\n🎉 COMPLETE SUCCESS!")
                print("🚀 ASCII diff round-trip workflow is working perfectly!")
                print("🔄 Source → ASCII → Operations → ASCII → Operations → Result")
                print("✅ All steps completed successfully with 100% accuracy!")
            } else {
                print("\n❌ ROUND-TRIP FAILED!")
                print("🔍 Some steps did not complete successfully")
            }
            
        } catch {
            print("❌ Error during round-trip: \(error)")
        }
        
        print("\n" + String(repeating: "=", count: 60))
        print("🏁 ASCII Diff Round-Trip Demonstration Completed")
    }

    // Run the ASCII Round-Trip demonstration
    demonstrateASCIIRoundTrip()
}

// MARK: - Enhanced ASCII Parser Metadata Showcase

func showcaseEnhancedASCIIParser() {
    print("\n🎯 Enhanced ASCII Parser Metadata Showcase")
    print(String(repeating: "=", count: 70))
    print("🚀 Demonstrating the new enhanced metadata capabilities!")
    
    // Create a comprehensive ASCII diff example
    let asciiDiff = """
    📎 class Calculator {
    📎     private var result: Double = 0
    📎     private var history: [String] = []
    📎     
    ❌     func add(_ value: Double) {
    ❌         result += value
    ❌     }
    ❌     
    ❌     func subtract(_ value: Double) {
    ❌         result -= value
    ❌     }
    ✅     func add(_ value: Double) -> Double {
    ✅         result += value
    ✅         history.append("Added \\(value)")
    ✅         return result
    ✅     }
    ✅     
    ✅     func subtract(_ value: Double) -> Double {
    ✅         result -= value
    ✅         history.append("Subtracted \\(value)")
    ✅         return result
    ✅     }
    ✅     
    ✅     func multiply(_ value: Double) -> Double {
    ✅         result *= value
    ✅         history.append("Multiplied by \\(value)")
    ✅         return result
    ✅     }
    📎     
    📎     func getResult() -> Double {
    📎         return result
    📎     }
    ✅     
    ✅     func getHistory() -> [String] {
    ✅         return history
    ✅     }
    ✅     
    ✅     func clearHistory() {
    ✅         history.removeAll()
    ✅     }
    📎 }
    """
    
    print("\n📄 ASCII Diff Input:")
    print(asciiDiff)
    
    do {
        print("\n🔄 Parsing ASCII diff with enhanced metadata...")
        let diffResult = try MultiLineDiff.parseDiffFromASCII(asciiDiff)
        
        print("✅ Successfully parsed \(diffResult.operations.count) operations")
        
        // Showcase the enhanced metadata
        guard let metadata = diffResult.metadata else {
            print("❌ No metadata found!")
            return
        }
        
        print("\n✨ ENHANCED METADATA SHOWCASE:")
        print(String(repeating: "-", count: 50))
        
        // 1. Source Start Line
        print("\n1. 🎯 SOURCE START LINE (NEW!):")
        let displayStartLine = (metadata.sourceStartLine ?? -1) + 1
        print("   Where modifications begin: Line \(displayStartLine)")
        print("   This tells us exactly where the changes start in the source!")
        
        // 2. Source and Destination Content Side-by-Side
        print("\n2. 📝 SOURCE & DESTINATION CONTENT RECONSTRUCTION:")
        if let sourceContent = metadata.sourceContent,
           let destContent = metadata.destinationContent {
            
            print("   📄 SOURCE (\(sourceContent.count) chars) | 📄 DESTINATION (\(destContent.count) chars)")
            print("   " + String(repeating: "─", count: 80))
            
            // Parse the original ASCII diff to understand what each line represents
            let asciiLines = asciiDiff.components(separatedBy: .newlines)
            var lineNum = 1
            
            for asciiLine in asciiLines {
                // Skip completely empty lines (no content at all)
                if asciiLine.isEmpty {
                    continue
                }
                
                let lineContent: String
                let symbol: String
                
                if asciiLine.hasPrefix("📎 ") {
                    symbol = "📎"
                    lineContent = String(asciiLine.dropFirst(2))
                } else if asciiLine.hasPrefix("❌ ") {
                    symbol = "❌"
                    lineContent = String(asciiLine.dropFirst(2))
                } else if asciiLine.hasPrefix("✅ ") {
                    symbol = "✅"
                    lineContent = String(asciiLine.dropFirst(2))
                } else if asciiLine.hasPrefix("📎") && asciiLine.count == 1 {
                    // Handle lines that are just the symbol (empty content lines)
                    symbol = "📎"
                    lineContent = ""
                } else {
                    // Handle lines without symbols (shouldn't happen in well-formed input)
                    continue
                }
                
                let marker = lineNum == (metadata.sourceStartLine ?? -1) + 1 ? " ← MODS START" : ""
                let lineNumStr = String(format: "%4d", lineNum)
                
                switch symbol {
                case "📎":
                    // Retained line - appears in both source and destination
                    let sourceDisplay = lineContent.padding(toLength: 60, withPad: " ", startingAt: 0)
                    print("   \(lineNumStr): \(sourceDisplay) | \(lineNumStr): \(lineContent)\(marker)")
                    
                case "❌":
                    // Deleted line - only in source
                    let sourceDisplay = lineContent.padding(toLength: 60, withPad: " ", startingAt: 0)
                    print("   \(lineNumStr)- \(sourceDisplay) | \(lineNumStr):\(marker)")
                    
                case "✅":
                    // Inserted line - only in destination
                    let emptySource = "".padding(toLength: 60, withPad: " ", startingAt: 0)
                    print("   \(lineNumStr): \(emptySource) | \(lineNumStr)+ \(lineContent)\(marker)")
                    
                default:
                    break
                }
                
                lineNum += 1
            }
            
            print("   " + String(repeating: "─", count: 80))
            print("   Legend: - = Deleted/Changed, + = Added/Changed, : = Unchanged")
        }
        
        // 3. Context Information
        print("\n3. 📍 CONTEXT INFORMATION:")
        print("   Preceding context: '\(metadata.precedingContext ?? "None")'")
        print("   Following context: '\(metadata.followingContext ?? "None")'")
        print("   Total source lines: \(metadata.sourceTotalLines ?? 0)")
        
        // 4. Algorithm and Application Info
        print("\n4. 🔧 ALGORITHM & APPLICATION INFO:")
        print("   Algorithm used: \(metadata.algorithmUsed?.displayName ?? "Unknown")")
        print("   Application type: \(metadata.applicationType?.rawValue ?? "Unknown")")
        
        // 5. Operations Breakdown
        print("\n5. ⚙️ OPERATIONS BREAKDOWN:")
        for (i, operation) in diffResult.operations.enumerated() {
            switch operation {
            case .retain(let count):
                print("   \(i + 1). RETAIN \(count) characters")
            case .delete(let count):
                print("   \(i + 1). DELETE \(count) characters")
            case .insert(let text):
                let preview = text.count > 50 ? String(text.prefix(50)) + "..." : text
                print("   \(i + 1). INSERT \(text.count) characters: '\(preview)'")
            }
        }
        
        // 6. Practical Use Cases Demo
        print("\n6. 💡 PRACTICAL USE CASES:")
        
        // AI Validation
        print("\n   🤖 AI VALIDATION:")
        let hasValidSource = metadata.sourceContent?.contains("func add") ?? false
        let hasValidDest = metadata.destinationContent?.contains("return result") ?? false
        let hasLocation = metadata.sourceStartLine != nil
        print("   ✅ Source validation: \(hasValidSource)")
        print("   ✅ Destination validation: \(hasValidDest)")
        print("   ✅ Location tracking: \(hasLocation)")
        
        // Location Tracking
        print("\n   📍 LOCATION TRACKING:")
        if let startLine = metadata.sourceStartLine {
            print("   ✅ Changes begin at line \(startLine + 1)")
            print("   ✅ Can precisely locate modifications in large files")
            print("   ✅ Perfect for patch application and conflict detection")
        }
        
        // Context Matching
        print("\n   🔍 CONTEXT MATCHING:")
        if let preceding = metadata.precedingContext,
           let following = metadata.followingContext {
            print("   ✅ Can find location using: '\(preceding)' ... '\(following)'")
            print("   ✅ Robust matching even in modified files")
        }
        
        // Verification
        print("\n   ✅ VERIFICATION:")
        let verificationResult = DiffMetadata.verifyDiffChecksum(
            diff: diffResult,
            storedSource: metadata.sourceContent,
            storedDestination: metadata.destinationContent
        )
        print("   ✅ Diff verification: \(verificationResult ? "PASSED" : "FAILED")")
        
        // 7. Apply the diff to demonstrate it works
        print("\n7. 🚀 DIFF APPLICATION TEST:")
        
        // First, let's reconstruct what the original source should be
        let originalSource = metadata.sourceContent ?? ""
        print("   Applying diff to reconstructed source...")
        
        let appliedResult = try MultiLineDiff.applyDiff(to: originalSource, diff: diffResult)
        let expectedResult = metadata.destinationContent ?? ""
        let applicationSuccess = appliedResult == expectedResult
        
        print("   ✅ Application success: \(applicationSuccess)")
        print("   📊 Original length: \(originalSource.count)")
        print("   📊 Result length: \(appliedResult.count)")
        print("   📊 Expected length: \(expectedResult.count)")
        
        if applicationSuccess {
            print("\n🎉 COMPLETE SUCCESS!")
            print("🚀 Enhanced ASCII parser metadata is working perfectly!")
            print("\n💫 KEY ACHIEVEMENTS:")
            print("   ✅ Source/destination content reconstruction")
            print("   ✅ Precise modification location tracking")
            print("   ✅ Context information for file positioning")
            print("   ✅ Complete verification capabilities")
            print("   ✅ AI integration ready")
            print("   ✅ Backward compatibility maintained")
        } else {
            print("\n❌ Application test failed!")
            print("🔍 Investigating differences...")
            
            let resultLines = appliedResult.components(separatedBy: .newlines)
            let expectedLines = expectedResult.components(separatedBy: .newlines)
            
            for (i, (result, expected)) in zip(resultLines, expectedLines).enumerated() {
                if result != expected {
                    print("   Line \(i) differs:")
                    print("   Result:   '\(result)'")
                    print("   Expected: '\(expected)'")
                    break
                }
            }
        }
        
        // 8. Summary Statistics
        print("\n8. 📊 SUMMARY STATISTICS:")
        print("   📄 ASCII diff lines: \(asciiDiff.components(separatedBy: .newlines).count)")
        print("   ⚙️ Operations generated: \(diffResult.operations.count)")
        print("   📝 Source lines: \(metadata.sourceTotalLines ?? 0)")
        print("   🎯 Modification start: Line \((metadata.sourceStartLine ?? -1) + 1)")
        print("   📊 Source characters: \(metadata.sourceContent?.count ?? 0)")
        print("   📊 Destination characters: \(metadata.destinationContent?.count ?? 0)")
        print("   🔧 Algorithm: \(metadata.algorithmUsed?.displayName ?? "Unknown")")
        
    } catch {
        print("❌ Error during ASCII parsing: \(error)")
    }
    
    print("\n" + String(repeating: "=", count: 70))
    print("🏁 Enhanced ASCII Parser Metadata Showcase Completed")
}

// MARK: - Enhanced ASCII Parser with Exact Line Numbers

func showcaseEnhancedASCIIParserExactLines() {
    print("\n🎯 Enhanced ASCII Parser with Exact Line Numbers")
    print(String(repeating: "=", count: 70))
    print("🚀 Demonstrating source and destination on exact line positions!")
    
    // Create a comprehensive ASCII diff example
    let asciiDiff = """
    📎 class Calculator {
    📎     private var result: Double = 0
    📎     private var history: [String] = []
    📎     
    ❌     func add(_ value: Double) {
    ❌         result += value
    ❌     }
    ❌     
    ❌     func subtract(_ value: Double) {
    ❌         result -= value
    ❌     }
    ✅     func add(_ value: Double) -> Double {
    ✅         result += value
    ✅         history.append("Added \\(value)")
    ✅         return result
    ✅     }
    ✅     
    ✅     func subtract(_ value: Double) -> Double {
    ✅         result -= value
    ✅         history.append("Subtracted \\(value)")
    ✅         return result
    ✅     }
    ✅     
    ✅     func multiply(_ value: Double) -> Double {
    ✅         result *= value
    ✅         history.append("Multiplied by \\(value)")
    ✅         return result
    ✅     }
    📎     
    📎     func getResult() -> Double {
    📎         return result
    📎     }
    ✅     
    ✅     func getHistory() -> [String] {
    ✅         return history
    ✅     }
    ✅     
    ✅     func clearHistory() {
    ✅         history.removeAll()
    ✅     }
    📎 }
    """
    
    print("\n📄 ASCII Diff Input:")
    print(asciiDiff)
    
    do {
        print("\n🔄 Parsing ASCII diff with enhanced metadata...")
        let diffResult = try MultiLineDiff.parseDiffFromASCII(asciiDiff)
        
        print("✅ Successfully parsed \(diffResult.operations.count) operations")
        
        // Showcase the enhanced metadata
        guard let metadata = diffResult.metadata else {
            print("❌ No metadata found!")
            return
        }
        
        print("\n✨ ENHANCED METADATA SHOWCASE:")
        print(String(repeating: "-", count: 50))
        
        // 1. Source Start Line
        print("\n1. 🎯 SOURCE START LINE (NEW!):")
        let displayStartLine = (metadata.sourceStartLine ?? -1) + 1
        print("   Where modifications begin: Line \(displayStartLine)")
        print("   This tells us exactly where the changes start in the source!")
        
        // 2. Source and Destination Content Side-by-Side with Exact Line Numbers
        print("\n2. 📝 SOURCE & DESTINATION CONTENT RECONSTRUCTION (EXACT LINES):")
        if let sourceContent = metadata.sourceContent,
           let destContent = metadata.destinationContent {
            
            print("   📄 SOURCE (\(sourceContent.count) chars) | 📄 DESTINATION (\(destContent.count) chars)")
            print("   " + String(repeating: "─", count: 80))
            
            // Parse the original ASCII diff to understand what each line represents
            let asciiLines = asciiDiff.components(separatedBy: .newlines)
            var sourceLineNum = 1
            var destLineNum = 1
            
            for asciiLine in asciiLines {
                // Skip completely empty lines (no content at all)
                if asciiLine.isEmpty {
                    continue
                }
                
                let lineContent: String
                let symbol: String
                
                if asciiLine.hasPrefix("📎 ") {
                    symbol = "📎"
                    lineContent = String(asciiLine.dropFirst(2))
                } else if asciiLine.hasPrefix("❌ ") {
                    symbol = "❌"
                    lineContent = String(asciiLine.dropFirst(2))
                } else if asciiLine.hasPrefix("✅ ") {
                    symbol = "✅"
                    lineContent = String(asciiLine.dropFirst(2))
                } else if asciiLine.hasPrefix("📎") && asciiLine.count == 1 {
                    // Handle lines that are just the symbol (empty content lines)
                    symbol = "📎"
                    lineContent = ""
                } else {
                    // Handle lines without symbols (shouldn't happen in well-formed input)
                    continue
                }
                
                let sourceMarker = sourceLineNum == (metadata.sourceStartLine ?? -1) + 1 ? " ← MODS START" : ""
                let destMarker = destLineNum == (metadata.sourceStartLine ?? -1) + 1 ? " ← MODS START" : ""
                
                switch symbol {
                case "📎":
                    // Retained line - appears in both source and destination at same line numbers
                    let sourceDisplay = lineContent.padding(toLength: 60, withPad: " ", startingAt: 0)
                    let sourceNumStr = String(format: "%4d", sourceLineNum)
                    let destNumStr = String(format: "%4d", destLineNum)
                    print("   \(sourceNumStr): \(sourceDisplay) | \(destNumStr): \(lineContent)\(sourceMarker)")
                    sourceLineNum += 1
                    destLineNum += 1
                    
                case "❌":
                    // Deleted line - only in source, destination shows empty at different line
                    let sourceDisplay = lineContent.padding(toLength: 60, withPad: " ", startingAt: 0)
                    let sourceNumStr = String(format: "%4d", sourceLineNum)
                    let emptyDest = "".padding(toLength: 60, withPad: " ", startingAt: 0)
                    print("   \(sourceNumStr)- \(sourceDisplay) | ----: \(emptyDest)\(sourceMarker)")
                    sourceLineNum += 1
                    // Don't increment destLineNum for deleted lines
                    
                case "✅":
                    // Inserted line - only in destination, source shows empty at different line
                    let emptySource = "".padding(toLength: 60, withPad: " ", startingAt: 0)
                    let destNumStr = String(format: "%4d", destLineNum)
                    print("   ----: \(emptySource) | \(destNumStr)+ \(lineContent)\(destMarker)")
                    destLineNum += 1
                    // Don't increment sourceLineNum for inserted lines
                    
                default:
                    break
                }
            }
            
            print("   " + String(repeating: "─", count: 80))
            print("   Legend: - = Deleted/Changed, + = Added/Changed, : = Unchanged, ---- = No line")
        }
        
        print("\n💡 This view shows the exact line numbers where content appears in source vs destination!")
        print("🔍 Notice how deleted lines don't consume destination line numbers")
        print("🔍 Notice how inserted lines don't consume source line numbers")
        
    } catch {
        print("❌ Error during ASCII parsing: \(error)")
    }
    
    print("\n" + String(repeating: "=", count: 70))
    print("🏁 Enhanced ASCII Parser with Exact Line Numbers Completed")
}

// Run the main function
do {
    try main()
    
    // Run the enhanced ASCII parser showcase
    showcaseEnhancedASCIIParser()
    
    // Run the exact line numbers version
    showcaseEnhancedASCIIParserExactLines()
    
} catch {
    print("Error in main function: \(error)")
}

// MARK: - UserManager ASCII Diff Test

func runUserManagerASCIIDiffTest() {
    print("\n🚀 UserManager ASCII Diff Test")
    print(String(repeating: "=", count: 50))
    
    let sourceCode = """
    class UserManager {
        private var users: [String: User] = [:]
        
        func addUser(name: String, email: String) -> Bool {
            guard !name.isEmpty && !email.isEmpty else {
                return false
            }
            
            let user = User(name: name, email: email)
            users[email] = user
            return true
        }
        
        func getUser(by email: String) -> User? {
            return users[email]
        }
        
        func removeUser(email: String) {
            users.removeValue(forKey: email)
        }
    }
    
    struct User {
        let name: String
        let email: String
    }
    """
    
    let destinationCode = """
    class UserManager {
        private var users: [String: User] = [:]
        private var userCount: Int = 0
        
        func addUser(name: String, email: String, age: Int = 0) -> Result<User, UserError> {
            guard !name.isEmpty && !email.isEmpty else {
                return .failure(.invalidInput)
            }
            
            let user = User(id: UUID(), name: name, email: email, age: age)
            users[email] = user
            userCount += 1
            return .success(user)
        }
        
        func getUser(by email: String) -> User? {
            return users[email]
        }
        
        func removeUser(email: String) -> Bool {
            guard users[email] != nil else { return false }
            users.removeValue(forKey: email)
            userCount -= 1
            return true
        }
        
        func getAllUsers() -> [User] {
            return Array(users.values).sorted { $0.name < $1.name }
        }
        
        var count: Int {
            return userCount
        }
    }
    
    struct User {
        let id: UUID
        let name: String
        let email: String
        let age: Int
    }
    
    enum UserError: Error {
        case invalidInput
        case userAlreadyExists
    }
    """
    
    print("\n📝 Source Code:")
    print(sourceCode)
    
    print("\n📝 Destination Code:")
    print(destinationCode)
    
    do {
        // Step 1: Create diff and display as ASCII
        print("\n🔄 Step 1: Creating diff and converting to ASCII...")
        let diff = MultiLineDiff.createDiff(
            source: sourceCode,
            destination: destinationCode,
            algorithm: .megatron
        )
        
        let asciiDiff = MultiLineDiff.displayDiff(
            diff: diff,
            source: sourceCode,
            format: .ai
        )
        
        print("✅ Generated ASCII diff (\(asciiDiff.count) characters)")
        print("\n📄 ASCII Diff:")
        print(asciiDiff)
        
        // Step 2: Parse the ASCII diff back
        print("\n🔄 Step 2: Parsing ASCII diff back to operations...")
        let parsedDiff = try MultiLineDiff.parseDiffFromASCII(asciiDiff)
        print("✅ Parsed \(parsedDiff.operations.count) operations")
        
        // Step 3: Apply the parsed diff
        print("\n🔄 Step 3: Applying parsed diff to source...")
        let result = try MultiLineDiff.applyDiff(to: sourceCode, diff: parsedDiff)
        print("✅ Applied diff successfully")
        
        // Step 4: Verify result
        print("\n🔄 Step 4: Verifying result...")
        let success = result == destinationCode
        print("✅ Result matches destination: \(success)")
        
        if success {
            print("\n🎉 ASCII diff workflow completed successfully!")
            print("🚀 The ASCII diff parsing is working perfectly!")
        } else {
            print("\n❌ Workflow failed!")
            print("Expected length: \(destinationCode.count)")
            print("Result length: \(result.count)")
            
            // Show first difference
            let expectedLines = destinationCode.components(separatedBy: .newlines)
            let resultLines = result.components(separatedBy: .newlines)
            
            for (i, (expected, actual)) in zip(expectedLines, resultLines).enumerated() {
                if expected != actual {
                    print("First difference at line \(i + 1):")
                    print("Expected: '\(expected)'")
                    print("Actual:   '\(actual)'")
                    break
                }
            }
        }
        
        // Step 5: Test AI submission workflow with complete diff
        print("\n" + String(repeating: "-", count: 50))
        print("🤖 AI Submission Test (Complete Diff)")
        
        // Use the same complete ASCII diff that was generated above
        print("AI submits the complete diff:")
        print(asciiDiff)
        
        print("\n🔄 Applying AI's complete diff...")
        let aiResult = try MultiLineDiff.applyASCIIDiff(
            to: sourceCode,
            asciiDiff: asciiDiff
        )
        
        print("✅ AI diff applied successfully!")
        print("Result contains 'userCount': \(aiResult.contains("userCount"))")
        print("Result contains 'Result<User, UserError>': \(aiResult.contains("Result<User, UserError>"))")
        print("Result contains '.failure(.invalidInput)': \(aiResult.contains(".failure(.invalidInput)"))")
        print("Result matches destination: \(aiResult == destinationCode)")
        
        // Step 6: Test simple AI submission workflow
        print("\n" + String(repeating: "-", count: 50))
        print("🤖 Simple AI Submission Test")
        
        let simpleSource = """
        func greet() {
            print("Hello")
        }
        """
        
        let simpleAIDiff = """
        = func greet() {
        -     print("Hello")
        +     print("Hello, World!")
        = }
        """
        
        print("Simple source:")
        print(simpleSource)
        print("\nAI submits simple diff:")
        print(simpleAIDiff)
        
        print("\n🔄 Applying simple AI diff...")
        let simpleResult = try MultiLineDiff.applyASCIIDiff(
            to: simpleSource,
            asciiDiff: simpleAIDiff
        )
        
        print("✅ Simple AI diff applied successfully!")
        print("Result:")
        print(simpleResult)
        
        let expectedSimple = """
        func greet() {
            print("Hello, World!")
        }
        """
        
        print("Matches expected: \(simpleResult == expectedSimple)")
        
        print("\n🎯 AI workflow tests completed!")
        
    } catch {
        print("❌ Error: \(error)")
    }
    
    print("\n" + String(repeating: "=", count: 50))
    print("🏁 UserManager ASCII Diff Test Completed")
}

