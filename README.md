# 🔍 MultiLineDiff

[![Swift 6.1](https://img.shields.io/badge/Swift-6.1-orange.svg)](https://swift.org)
[![Website](https://img.shields.io/badge/website-xcf.ai-blue.svg)](https://xcf.ai)
[![Version](https://img.shields.io/badge/version-1.3.2-green.svg)](https://github.com/codefreezeai/swift-multi-line-diff)
[![GitHub stars](https://img.shields.io/github/stars/codefreezeai/swift-multi-line-diff.svg?style=social)](https://github.com/codefreezeai/swift-multi-line-diff/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/codefreezeai/swift-multi-line-diff.svg?style=social)](https://github.com/codefreezeai/swift-multi-line-diff/network)

**Advanced multi-line string diffing with semantic-aware algorithms and intelligent application detection.**

A powerful, performance-optimized Swift package that provides sophisticated multi-line string comparison and modification capabilities. Features dual-algorithm support with automatic source type detection, comprehensive metadata, and enterprise-grade reliability.

## ✨ Key Features

- **🔥 Dual Algorithm Support**: Choose between performance-optimized Brus and semantic-aware Todd algorithms
- **🎯 Guaranteed Accuracy**: Both algorithms produce 100% identical results with different granularities  
- **🧠 Intelligent Source Detection**: Automatically detects full vs truncated sources
- **📊 Rich Metadata**: Comprehensive diff context and verification information
- **⚡ High Performance**: Optimized for large files with sub-millisecond processing
- **🔐 Production Ready**: Comprehensive error handling and crash prevention
- **🌐 Universal Compatibility**: Pure Swift implementation, no external dependencies

## 📈 Quick Example

```swift
import MultiLineDiff

let source = """
Hello, world!
This is line 2
Keep this line
"""

let destination = """
Hello, Swift!
This is line 2
Modified line
New line added
"""

// Create diff
let diff = MultiLineDiff.createDiff(source: source, destination: destination)

// Apply diff
let result = try MultiLineDiff.applyDiff(to: source, diff: diff)
print(result == destination) // true
```

## 🎯 Visual Diff Examples

### Example 1: Simple Text Changes
```swift
Source:      "Hello, world!"
Destination: "Hello, Swift!"

Operations:
┌─────────────────────────────────────┐
│ RETAIN(7)  │ DELETE(5) │ INSERT(6)  │
│ "Hello, "  │ "world"   │ "Swift"    │
└─────────────────────────────────────┘

Result: "Hello, Swift!"
```

### Example 2: Multi-Line Code Changes
```swift
// SOURCE
func calculate(a: Int, b: Int) -> Int {
    return a + b
}

// DESTINATION  
func calculate(a: Int, b: Int) -> Int {
    // Enhanced calculation
    let result = a + b
    return result
}

// OPERATIONS (Todd Algorithm - Line Granular)
┌────────────────────────────────────────────────────────────┐
│ RETAIN(40)          │ INSERT(31)             │ RETAIN(17)  │
│ func calculate(...  │ ... Enhanced calc      │ return...   │
│ return              │ let result = a + b\n   │             │
└────────────────────────────────────────────────────────────┘
```

### Example 3: Algorithm Comparison - Real Differences

**Multi-Line Source:**
```swift
func processUser() {
    let user = getCurrentUser()
    print("Processing user")
    validateUser(user)
    return user
}
```

**Multi-Line Destination:**
```swift
func processUser() -> User {
    let user = getCurrentUser()
    print("Processing user data")
    let validated = validateUser(user)
    saveUserData(validated)
    return validated
}
```

**Brus Algorithm (4 Bulk Operations)**
```swift
┌────────────────────────────────────────────────────────────────────────────────-──┐
│ 1. RETAIN(19)         │ 2. DELETE(101)         │ 3. INSERT(163)    │ 4. RETAIN(2) │
│ func processUser() {  │ Delete original body   │ -> User {\n       │ \n}          │
│ \n    let user =      │ {\n    let user...     │    let user = ... │              │
│                       │ return user\n}         │ return validated  │              │
└───────────────────────────────────────────────────────────────────────────────────┘

🔥 Result: 4 operations, ultra-fast bulk replacement
```

**Todd Algorithm (6 Line-Aware Operations)**  
```swift
┌─────────────────────────────────────────────────────────────────────┐
│ 1. DELETE(21)          │ 2. INSERT(29)          │ 3. RETAIN(32)     │
│ func processUser() {   │ func processUser()     │ let user =        │
│                        │ -> User {\n            │ getCurrentUser()  │
│─────────────────────────────────────────────────────────────────────│
│ 4. DELETE(68)          │ 5. INSERT(122)         │ 6. RETAIN(1)      │
│ \n    print(\Process   │ \n    print(\Process   │ \n                │
│ ing user\)\n...return  │ ing user data\)...     │ return validated  │
│ user                   │ return validated       │                   │
└─────────────────────────────────────────────────────────────────────┘

🧠 Result: 6 operations, line-by-line semantic processing
```

**Key Differences:**
- **Brus**: Treats entire change as 4 bulk character operations
- **Todd**: Processes with 6+ semantic operations, more granular  
- **Both**: Produce identical final code ✅
- **Use Case**: Brus for speed, Todd for detailed change tracking

## 📊 Performance Comparison

| Algorithm | Speed (Small Files) | Speed (Large Files) | Operations | Use Case |
|-----------|--------------------|--------------------|------------|----------|
| **Brus** | ⚡ 0.11ms | ⚡ 17ms | 📦 Bulk (3-5) | Speed Critical |
| **Todd** | 🏃 0.22ms | 🏃 45ms | 🔬 Granular (1000s) | Semantic Aware |

Both algorithms guarantee **100% identical final results**.

## 🔧 Installation

### Swift Package Manager
Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/toddbruss/swift-multi-line-diff.git", from: "1.3.2")
]
```

### Xcode
1. **File** → **Add Package Dependencies**
2. Enter: `https://github.com/toddbruss/swift-multi-line-diff.git`
3. Click **Add Package**

## 🚀 Basic Usage

### Creating and Applying Diffs

```swift
import MultiLineDiff

// Simple text diff
let source = "Hello, world!"
let destination = "Hello, Swift!"

// Create diff (auto-selects best algorithm)
let diff = MultiLineDiff.createDiff(source: source, destination: destination)

// Apply diff
let result = try MultiLineDiff.applyDiff(to: source, diff: diff)
print(result) // "Hello, Swift!"
```

### Algorithm Selection

```swift
// Use high-performance Brus algorithm
let brusDiff = MultiLineDiff.createDiff(
    source: source, 
    destination: destination,
    algorithm: .brus
)

// Use semantic-aware Todd algorithm  
let toddDiff = MultiLineDiff.createDiff(
    source: source,
    destination: destination, 
    algorithm: .todd
)

// Both produce identical final results
let brusResult = try MultiLineDiff.applyDiff(to: source, diff: brusDiff)
let toddResult = try MultiLineDiff.applyDiff(to: source, diff: toddDiff)
print(brusResult == toddResult) // true
```

### Working with Files

```swift
// Load source and destination files
let sourceURL = URL(fileURLWithPath: "source.txt")
let destURL = URL(fileURLWithPath: "destination.txt")

let sourceContent = try String(contentsOf: sourceURL)
let destContent = try String(contentsOf: destURL)

// Create diff
let diff = MultiLineDiff.createDiff(source: sourceContent, destination: destContent)

// Save diff to file
let diffURL = URL(fileURLWithPath: "changes.json")
try MultiLineDiff.saveDiffToFile(diff, fileURL: diffURL)

// Load and apply diff later
let loadedDiff = try MultiLineDiff.loadDiffFromFile(fileURL: diffURL)
let result = try MultiLineDiff.applyDiff(to: sourceContent, diff: loadedDiff)
```

## 🎯 Advanced Features

### Truncated Source Handling

Perfect for applying diffs to partial documents:

```swift
// Full document
let fullDocument = """
Header content
## Section 1
Content here
## Section 2  
More content
Footer content
"""

// Extract just section 2
let section2 = "## Section 2\nMore content"

// Create diff for section modification
let modifiedSection = "## Section 2\nUpdated content\nNew paragraph"

let diff = MultiLineDiff.createDiff(
    source: section2,
    destination: modifiedSection,
    includeMetadata: true,
    sourceStartLine: 3 // Section starts at line 3 (optional)
)

// Apply to full document (automatically handles section matching)
let updatedDocument = try MultiLineDiff.applyDiff(to: fullDocument, diff: diff)
```

### Base64 Encoding for Storage

```swift
// Create and encode diff
let base64Diff = try MultiLineDiff.createBase64Diff(
    source: source,
    destination: destination
)

// Store in database, send over network, etc.
print("Diff: \(base64Diff)")

// Apply encoded diff
let result = try MultiLineDiff.applyBase64Diff(to: source, base64Diff: base64Diff)
```

### Metadata and Verification

```swift
// Create diff with rich metadata
let diff = MultiLineDiff.createDiff(
    source: source,
    destination: destination,
    includeMetadata: true
)

// Access metadata
if let metadata = diff.metadata {
    print("Algorithm used: \(metadata.algorithmUsed)")
    print("Source lines: \(metadata.sourceTotalLines)")
    print("Diff hash: \(metadata.diffHash)")
    print("Context: \(metadata.precedingContext)")
}

// Verify diff integrity
let isValid = MultiLineDiff.verifyDiffIntegrity(diff)
print("Diff is valid: \(isValid)")
```

## 🔬 Algorithm Deep Dive

### Brus Algorithm - Bulk Operations
```swift
┌─────────────────────────────────────────────┐
│                BRUS ALGORITHM               │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐  │
│  │ PREFIX  │────│ MIDDLE  │────│ SUFFIX  │  │
│  │ COMMON  │    │ CHANGES │    │ COMMON  │  │
│  └─────────┘    └─────────┘    └─────────┘  │
│                                             │
│  Fast bulk operations:                      │
│  • RETAIN(prefix_length)                    │
│  • DELETE(removed_content)                  │ 
│  • INSERT(new_content)                      │
│  • RETAIN(suffix_length)                    │
└─────────────────────────────────────────────┘
```

### Todd Algorithm - Line-Aware Processing
```swift
┌──────────────────────────────────────────────┐
│               TODD ALGORITHM                 │
│                                              │
│  Line 1: ────────────────────── RETAIN       │
│  Line 2: ─┬─ DELETE old line                 │
│          └─ INSERT new line                  │
│  Line 1: ────────────────────── RETAIN       │
│  Line 3: ────────────────────── RETAIN       │
│  Line 4: ────────────────────── INSERT (new) │
│                                              │
│  Semantic line operations:                   │
│  • Processes line-by-line                    │
│  • Preserves formatting                      │
│  • Granular operation history                │
│  • Perfect for code diffs                    │
└──────────────────────────────────────────────┘
```

## 📝 Operation Types

### Retain Operation
```swift
.retain(count: Int)
```
Keeps `count` characters from the source unchanged.

### Insert Operation  
```swift
.insert(text: String)
```
Adds new `text` content at the current position.

### Delete Operation
```swift
.delete(count: Int) 
```
Removes `count` characters from the source.

### Example Operation Sequence
```swift
Source: "Hello, world!"
Dest:   "Hello, Swift world!"

Operations:
1. RETAIN(7)     // Keep "Hello, "
2. INSERT(6)     // Add "Swift "  
3. RETAIN(6)     // Keep "world!"

Result: "Hello, Swift world!"
```

## 🎨 Real-World Examples

### Code Refactoring
```swift
// Before
let source = """
class UserService {
    func getUser(id: String) -> User? {
        return database.find(id)
    }
}
"""

// After  
let destination = """
class UserService {
    private let database: Database
    
    init(database: Database) {
        self.database = database
    }
    
    func getUser(id: String) async throws -> User? {
        return try await database.find(id)
    }
}
"""

let diff = MultiLineDiff.createDiff(source: source, destination: destination, algorithm: .todd)
```

### Documentation Updates
```swift
// Update README sections
let originalReadme = try String(contentsOfFile: "README.md")
let updatedSection = """
## New Feature
This amazing new feature does incredible things.
"""

// Create targeted diff for specific section
let diff = MultiLineDiff.createDiff(
    source: "## Old Section\nOld content",
    destination: updatedSection,
    includeMetadata: true,
    sourceStartLine: 42
)

// Apply to full README
let newReadme = try MultiLineDiff.applyDiff(to: originalReadme, diff: diff)
```

### Configuration Changes
```swift
// Environment-specific config updates
let prodConfig = """
{
  "environment": "production",
  "database": "prod-db.example.com",
  "debug": false
}
"""

let devConfig = """
{
  "environment": "development", 
  "database": "localhost:5432",
  "debug": true,
  "features": ["experimental"]
}
"""

let diff = MultiLineDiff.createBase64Diff(source: prodConfig, destination: devConfig)
// Store diff, apply to generate dev config from prod config
```

## 🔍 Error Handling

```swift
do {
    let result = try MultiLineDiff.applyDiff(to: source, diff: diff)
    print("Success: \(result)")
} catch DiffError.invalidRetain(let count, let remaining) {
    print("Cannot retain \(count) chars, only \(remaining) available")
} catch DiffError.invalidDelete(let count, let remaining) {
    print("Cannot delete \(count) chars, only \(remaining) available")  
} catch DiffError.verificationFailed(let expected, let actual) {
    print("Expected \(expected.count) chars, got \(actual.count)")
} catch {
    print("Other error: \(error)")
}
```

## 🏆 Performance Benchmarks

### Large File Performance (10,000 lines)
```swift
📊 Brus Algorithm:
• Create Diff: 17ms
• Apply Diff: 7ms  
• Operations: 3-5 bulk operations
• Memory: O(1) space complexity

📊 Todd Algorithm:  
• Create Diff: 45ms
• Apply Diff: 7ms
• Operations: 1,256 granular operations  
• Memory: O(n) space complexity

🎯 Both achieve 100% accuracy with identical final results
```

### Memory Usage Comparison
```swift
Small Files    (< 1KB):  📱 ~50KB peak memory
Medium Files (< 100KB):  📱 ~200KB peak memory  
Large Files   (< 10MB):  📱 ~2MB peak memory

✅ Crash-safe with comprehensive bounds checking
✅ Handles Unicode, special characters, extreme edge cases
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup
```swift
git clone https://github.com/toddbruss/swift-multi-line-diff.git
cd swift-multi-line-diff
swift test  # Run all tests
swift run   # Run performance demos
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Swift Community for the excellent string processing APIs
- Contributors who helped with testing and optimization
- Everyone who provided feedback on the algorithm design

---

**MultiLineDiff** - Reliable, fast, and feature-rich multi-line string diffing for Swift.

