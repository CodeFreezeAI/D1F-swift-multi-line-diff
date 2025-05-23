# MultiLineDiff

[![Swift 6.1](https://img.shields.io/badge/Swift-6.1-orange.svg)](https://swift.org)
[![Website](https://img.shields.io/badge/website-xcf.ai-blue.svg)](https://xcf.ai)
[![Version](https://img.shields.io/badge/version-1.1.3-green.svg)](https://github.com/toddbruss/swift-multi-line-diff)

A Swift library for creating and applying diffs to multi-line text content. Supports Unicode/UTF-8 strings and handles multi-line content properly. Designed specifically for Vibe AI Coding integrity and safe code transformations.

## 🌟 Key Features

- Create diffs between two strings
- Apply diffs to transform source text
- Handle multi-line content properly
- Support for Unicode/UTF-8 strings
- Multiple diff formats (JSON, Base64)
- Two diff algorithms (Brus and Todd)
- Designed for AI code integrity
- **NEW: Truncated Diff Support** 🆕

## 🖥️ Platform Compatibility

- **macOS**: 13.0+
- **Swift**: 6.1+

## 🚀 Truncated Diff Support

MultiLineDiff supports applying diffs to truncated sources, making it incredibly flexible for partial document transformations.

### Key Truncated Diff Capabilities

- Apply diffs to partial documents
- Preserve context and metadata
- Intelligent section replacement
- Automatic line number interpolation

#### Truncated Diff Usage: Line Number Handling

When working with truncated sources, follow these guidelines for `sourceStartLine`:

1. **If You Know the Exact Line Number**:
```swift
let diff = MultiLineDiff.createDiff(
    source: truncatedContent,
    destination: modifiedContent,
    includeMetadata: true,
    sourceStartLine: 42  // Recommended: Use the actual line number if known
)
```

2. **If Line Number is Unknown**:
```swift
let diff = MultiLineDiff.createDiff(
    source: truncatedContent,
    destination: modifiedContent,
    includeMetadata: true,
    sourceStartLine: 1  // Default: Algorithm will interpolate using metadata
)
```

**Recommended Practices**:
- **Best Practice**: Always specify the exact line number if known
- **Fallback**: Use `sourceStartLine: 1` when the exact line is uncertain
- The library uses metadata and context to intelligently locate the correct section
- Always set `includeMetadata: true` for truncated diffs

### Line Number Interpolation

When `sourceStartLine: 1` is used, the library:
- Analyzes preceding and following context
- Uses metadata to determine the most likely section
- Intelligently applies the diff to the correct location

### Example: Line Number Scenarios

```swift
// Scenario 1: Known Exact Line
let knownLineDiff = MultiLineDiff.createDiff(
    source: truncatedChapter2,
    destination: updatedChapter2,
    includeMetadata: true,
    sourceStartLine: 15  // Exact line number in full document
)

// Scenario 2: Unknown Line Number
let defaultLineDiff = MultiLineDiff.createDiff(
    source: truncatedChapter2,
    destination: updatedChapter2,
    includeMetadata: true,
    sourceStartLine: 1  // Default: Intelligent interpolation
)
```

### Full Document Diff Application

```swift
let originalDocument = """
Chapter 1: Introduction
...
Chapter 2: Core Concepts
This section explains the fundamental principles.
More detailed explanation here.
...
"""

let truncatedSection = """
Chapter 2: Core Concepts
This section explains the fundamental principles.
More detailed explanation here.
"""

let updatedSection = """
Chapter 2: Core Concepts
This section provides a comprehensive explanation of fundamental principles.
Enhanced and more detailed insights.
"""

// Intelligent diff application
let diff = MultiLineDiff.createDiff(
    source: truncatedSection,
    destination: updatedSection,
    includeMetadata: true,
    sourceStartLine: 1  // Default intelligent interpolation
)

// Apply diff to full document
let updatedDocument = try MultiLineDiff.applyDiff(
    to: originalDocument, 
    diff: diff,
    allowTruncatedSource: true
)
```

The library handles the complexity of locating and applying the diff, even with partial or truncated sources.

## Base64 Diff Encoding

Compact and safe diff representation with built-in base64 encoding:

```swift
// Create a base64 encoded diff
let base64Diff = try MultiLineDiff.createBase64Diff(
    source: originalCode, 
    destination: modifiedCode
)

// Apply base64 encoded diff
let reconstructedCode = try MultiLineDiff.applyBase64Diff(
    to: originalCode, 
    base64Diff: base64Diff
)
```

## 🚀 Performance Optimizations for Swift 6.1

### Speed Optimization
- **Compile-Time Inlining**: Utilizes Swift 6.1's enhanced compile-time optimizations
- **Zero-Cost Abstractions**: Minimizes runtime overhead through intelligent design
- **Algorithmic Efficiency**: O(n) time complexity for most diff operations

### Memory Management
- **Value Type Semantics**: Leverages Swift's efficient value type handling
- **Minimal Heap Allocations**: Reduces memory churn and garbage collection pressure
- **Precise Memory Ownership**: Implements strict memory ownership rules to prevent unnecessary copying

## Performance Comparison

| Metric | MultiLineDiff | Traditional Diff Libraries |
|--------|---------------|----------------------------|
| Speed | ⚡️ Ultra-Fast | 🐌 Slower |
| Memory Usage | 💡 Low | 🧠 Higher |
| Scalability | 🚀 Excellent | 📉 Limited |

## 📦 Diff Representation Formats

### Diff Operation Types

```swift
enum DiffOperation {
    case retain(Int)     // Keep existing characters
    case delete(Int)     // Remove characters
    case insert(String)  // Add new characters
}
```

### Detailed Diff Visualization

```swift
let sourceCode = """
class Example {
    func oldMethod() {
        print("Hello")
    }
}
"""

let destinationCode = """
class Example {
    func newMethod() {
        print("Hello, World!")
    }
}
"""

// Create diff operations
let diffOperations = MultiLineDiff.createDiff(source: sourceCode, destination: destinationCode)

// Apply the diff operations
let result = try MultiLineDiff.applyDiff(to: sourceCode, diff: diffOperations)

// Verify the transformation
assert(result == destinationCode, "Applied diff should match destination code")
```

### Base64 Diff Decoding Example

```swift
// Decode Base64 Diff
func decodeBase64Diff(_ base64String: String) -> String {
    guard let decodedData = Data(base64Encoded: base64String),
          let jsonString = String(data: decodedData, encoding: .utf8) else {
        return "Decoding failed"
    }
    return jsonString
}

// Example of Base64 Diff Decoding
let decodedDiffOperations = decodeBase64Diff(base64Diff)
```

## 🔍 Diff Operation Insights

### Operation Symbols

| Symbol | Operation | Description |
|--------|-----------|-------------|
| `====` | Retain    | Keep text as is |
| `----` | Delete    | Remove text |
| `++++` | Insert    | Add new text |
| `▼`    | Position  | Current operation point |
| `┌─┐`  | Section   | Groups related changes |
| `└─┘`  | Border    | Section boundary |

### Basic Examples

```swift
Source:      "Hello, world!"
Destination: "Hello, Swift!"
Operation:    ====== ----- ++++++   // "Hello, " retained, "world" deleted, "Swift" inserted
             |||||| xxxxx ++++++
             Hello, world Swift
```

### Multi-Line Example

```swift
┌─ Source
│ func oldMethod() {
│     print("Hello")
│ }
└─────────────────

┌─ Destination
│ func newMethod() {
│     print("Hello, World!")
│ }
└─────────────────

┌─ Operations
│ func ==== ---- ++++ ==== () {    // retain "func ", delete "old", insert "new", retain "Method"
│     ---- +++++++++++++++++++     // delete old print statement, insert new print statement
│ }====                            // retain closing brace
└─────────────────
```

### More Complex Example

```swift
┌─ Source
│ func calculateTotal(items: [Product]) -> Double {
│     var total = 0.0
│     for item in items {
│         total += item.price
│     }
│     return total
│ }
└─────────────────

┌─ Destination
│ func calculateTotal(items: [Product]) -> Double {
│     return items.reduce(0.0) { $0 + $1.price }
│ }
└─────────────────

┌─ Operations
│ ==================================== {    // retain signature
│ ┌─ Delete old implementation and insert new implementation
│ │ --- var total = 0.0
│ │ --- for item in items {
│ │ ---     total += item.price
│ │ --- }
│ │ --- return total
│ │ +++ return items.reduce(0.0) { $0 + $1.price }
│ └─ 
│ }====                                     // retain closing brace
└─────────────────
```

### Algorithm Comparison

```swift
┌─ Todd Algorithm (.todd)
│ ==== function signature preserved
│ ---- old implementation removed
│ ++++ new implementation added
│ ==== closing brace retained
└─────────────────

┌─ Brus Algorithm (.brus)
│ ==== matching prefix
│ ---- bulk content removal
│ ++++ new content insertion
│ ==== matching suffix
└─────────────────
```

### When to Use Each Algorithm

```swift
// Todd Algorithm (.todd) best for:
// - Code refactoring
// - Semantic changes
// - Structure preservation

// Brus Algorithm (.brus) best for:
// - Simple text changes
// - Performance critical operations
// - Character-based modifications
```

## 🚀 Why Base64?

1. **Compact Representation**: Reduces diff size
2. **Safe Transmission**: Avoids escaping issues
3. **Universal Compatibility**: Works across different systems
4. **AI-Friendly**: Ideal for code transformation pipelines

## 🔍 Algorithm Complexity Analysis

### Brus Algorithm Big O Notation

| Metric | Complexity | Explanation | Visual Representation |
|--------|------------|-------------|----------------------|
| **Time Complexity** | O(n) | Linear time complexity | 🟢🟢🟢 Low |
| **Space Complexity** | O(1) | Constant space usage | 🟢🟢🟡 Moderate |
| **Best Case** | Ω(1) | Minimal changes between strings | 🟢🟢🟢 Fast |
| **Worst Case** | O(n) | Complete string replacement | 🟢🟢🟡 Efficient |
| **Average Case** | Θ(n) | Proportional to input string length | 🟢🟢🟡 Moderate |

#### Performance Gradient
```
Complexity:     🟢🟢🟢
Memory Usage:   🟢🟢🟡
Speed:          🟢🟢🟢
```

### Todd Algorithm Big O Notation

| Metric | Complexity | Explanation | Visual Representation |
|--------|------------|-------------|----------------------|
| **Time Complexity** | O(n log n) | Logarithmic-linear time complexity | 🟢🟠🟡 Moderate |
| **Space Complexity** | O(n) | Linear space usage | 🟢🟢🟡 Moderate |
| **Best Case** | Ω(n) | Minimal structural changes | 🟢🟢🟡 Effective |
| **Worst Case** | O(n²) | Highly complex text transformations | 🟢🟠🟡 High |
| **Average Case** | Θ(n log n) | Semantic analysis overhead | 🟢🟠🟡 Moderate |

#### Performance Gradient
```
Complexity:     🟢🟠🟡
Memory Usage:   🟢🟢🟡
Speed:          🟢🟠🟡
```

### Comparative Performance Visualization

```
Brus Algorithm:  🟢🟢🟢
Todd Algorithm:  🟢🟢🟢
```

## 📦 Usage Examples

### Basic Single-Line Diff

```swift
let source = "Hello, world!"
let destination = "Hello, Swift!"

// Create a diff
let diff = MultiLineDiff.createDiff(source: source, destination: destination)

// Apply the diff
let result = try MultiLineDiff.applyDiff(to: source, diff: diff)
assert(result == destination)
```

### Multi-Line Code Diff Example

```swift
let sourceCode = """
class Example {
    func oldMethod() {
        print("Hello")
        // Some old comment
    }
}
"""

let destinationCode = """
class Example {
    // New method implementation
    func newMethod() {
        print("Hello, World!")
        // Improved logging
    }
}
"""

// Create a multi-line diff
let multiLineDiff = MultiLineDiff.createDiff(
    source: sourceCode, 
    destination: destinationCode,
    algorithm: .todd  // Use Todd algorithm for more semantic diff
)

// Apply the multi-line diff
let updatedCode = try MultiLineDiff.applyDiff(
    to: sourceCode, 
    diff: multiLineDiff
)
print(updatedCode)
```

### Choosing Diff Algorithms

```swift
// Automatically choose the best algorithm
let recommendedAlgorithm = MultiLineDiff.suggestDiffAlgorithm(
    source: sourceCode, 
    destination: destinationCode
)

// Explicitly select an algorithm
let brusDiff = MultiLineDiff.createDiff(
    source: sourceCode, 
    destination: destinationCode, 
    algorithm: .brus
)

let toddDiff = MultiLineDiff.createDiff(
    source: sourceCode, 
    destination: destinationCode, 
    algorithm: .todd
)
```

### Base64 Encoded Diffs (Recommended for AI Transformations)

```swift
// Create a base64 encoded diff
let base64Diff = try MultiLineDiff.createBase64Diff(
    source: sourceCode, 
    destination: destinationCode
)

// Apply a base64 encoded diff
let reconstructedCode = try MultiLineDiff.applyBase64Diff(
    to: sourceCode, 
    base64Diff: base64Diff
)
```

### File-Based Diff Operations

```swift
// Save diff to a file
try MultiLineDiff.saveDiffToFile(
    multiLineDiff, 
    fileURL: URL(fileURLWithPath: "/path/to/diff.json")
)

// Load diff from a file
let loadedDiff = try MultiLineDiff.loadDiffFromFile(
    fileURL: URL(fileURLWithPath: "/path/to/diff.json")
)
```

## 🎯 Practical Scenarios

### Code Refactoring
- Rename methods
- Change method signatures
- Restructure class hierarchies

### Version Control
- Generate compact diffs
- Store minimal change information
- Efficient code comparison

### AI-Assisted Coding
- Safe code transformations
- Precise change tracking
- Semantic diff analysis

## 📝 License

MIT

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. 

(c) 2025 Todd Bruss

## 📦 Diff Operation Examples

### Basic Diff Operations

```swift
enum DiffOperation {
    case retain(Int)     // Keep existing characters
    case delete(Int)     // Remove characters
    case insert(String)  // Add new characters
}
```

### Retain Operation Example

```swift
Source:      "Hello, world!"
Destination: "Hello, Swift!"
Operation:    ====== ▼        // Retain "Hello, "
             |||||| |
             Hello, w
```

### Delete Operation Example

```swift
Source:      "Hello, world!"
Destination: "Hello!"
Operation:    ====== -----    // Delete "world"
             |||||| xxxxx
             Hello, world
```

### Insert Operation Example

```swift
Source:      "Hello!"
Destination: "Hello, world!"
Operation:    ====== ++++++   // Insert ", world"
             |||||| ------
             Hello, world
```

### Replace (Delete and Insert) Operation Example

```swift
Source:      "Hello, world!"
Destination: "Hello, Swift!"
Operation:    ====== ----- ++++++   // "Hello, " retained, "world" deleted, "Swift" inserted
             |||||| xxxxx ++++++
             Hello, world Swift
```

### Multi-Line Diff Example

```swift
// Source
func oldMethod() {
    print("Hello")
}

// Destination
func newMethod() {
    print("Hello, World!")
}

// Operation Breakdown:
func ==== ---- ++++ ==== () {     // retain "func ", delete "old", insert "new", retain "Method"
    ---- +++++++++++++++++++     // delete old print statement, insert new print statement
}====                            // retain closing brace

// Visual Representation:
┌─ Source
│ func oldMethod() {
│     print("Hello")
│ }
└─────────────────
   ↓ Transform ↓
┌─ Destination
│ func newMethod() {
│     print("Hello, World!")
│ }
└─────────────────
```

### Real-World Complex Example

```swift
// Source
func calculateTotal(items: [Product]) -> Double {
    var total = 0.0
    for item in items {
        total += item.price
    }
    return total
}

// Destination
func calculateTotal(items: [Product]) -> Double {
    return items.reduce(0.0) { $0 + $1.price }
}

// Operation Visualization:
┌─ Retain signature
│ func calculateTotal(items: [Product]) -> Double {
└─ ===============================================

┌─ Delete old implementation and insert new implementation
│ --- var total = 0.0
│ --- for item in items {
│ ---     total += item.price
│ --- }
│ --- return total
│ +++ return items.reduce(0.0) { $0 + $1.price }
└─ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

┌─ Retain closing
│ }
└─ =
```

### Operation Legend

| Symbol | Operation | Description |
|--------|-----------|-------------|
| `====` | Retain    | Keep text as is |
| `----` | Delete    | Remove text |
| `++++` | Insert    | Add new text |
| `▼`    | Position  | Current operation point |
| `┌─┐`  | Section   | Groups related changes |
| `└─┘`  | Border    | Section boundary |

### Base64 Operations (Built-in)

```swift
// Source Code
let sourceCode = """
func oldMethod() {
    print("Hello")
}
"""

let destinationCode = """
func newMethod() {
    print("Hello, World!")
}
"""

// Create base64 diff (automatically encodes)
let base64Diff = try MultiLineDiff.createBase64Diff(
    source: sourceCode,
    destination: destinationCode,
    useToddAlgorithm: true  // Optional: use Todd algorithm
)

// Apply base64 diff (automatically decodes)
let result = try MultiLineDiff.applyBase64Diff(
    to: sourceCode,
    base64Diff: base64Diff
)

// Verify transformation
assert(result == destinationCode)

// The base64 string contains encoded operations:
print(base64Diff)
// Example output:
// W3sicmV0YWluIjo1fSx7ImRlbGV0ZSI6M30seyJpbnNlcnQiOiJuZXcifSx7InJldGFpbiI6N31d...

// Operations represented in the base64:
// ✅ Retain "func "
// ❌ Delete "old"
// ➕ Insert "new"
// ✅ Retain "Method"
// ❌ Delete old print statement
// ➕ Insert new print statement
// ✅ Retain closing brace
```

### File Operations with Base64

```swift
// Save base64 diff to file
let fileURL = URL(fileURLWithPath: "diff.base64")
try base64Diff.write(to: fileURL, atomically: true, encoding: .utf8)

// Load and apply base64 diff from file
let loadedBase64 = try String(contentsOf: fileURL, encoding: .utf8)
let reconstructed = try MultiLineDiff.applyBase64Diff(
    to: sourceCode,
    base64Diff: loadedBase64
)
```
