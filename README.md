# MultiLineDiff

[![Swift 6.1](https://img.shields.io/badge/Swift-6.1-orange.svg)](https://swift.org)
[![Website](https://img.shields.io/badge/website-xcf.ai-blue.svg)](https://xcf.ai)
[![Version](https://img.shields.io/badge/version-1.2.0-green.svg)](https://github.com/toddbruss/swift-multi-line-diff)
[![GitHub stars](https://img.shields.io/github/stars/codefreezeai/swift-multi-line-diff.svg?style=social)](https://github.com/codefreezeai/swift-multi-line-diff/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/codefreezeai/swift-multi-line-diff.svg?style=social)](https://github.com/codefreezeai/swift-multi-line-diff/network)

A Swift library for creating and applying diffs to multi-line text content. Supports Unicode/UTF-8 strings and handles multi-line content properly. Designed specifically for Vibe AI Coding integrity and safe code transformations.

## 🌟 Key Features

- Create diffs between two strings
- Apply diffs to transform source text
- Handle multi-line content properly
- Support for Unicode/UTF-8 strings
- Multiple diff formats (JSON, Base64)
- Two diff algorithms (Brus and Todd)
- **Automatic algorithm fallback with verification** 🛡️
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
    sourceStartLine: 2
)

// Apply diff to full document
let updatedDocument = try MultiLineDiff.applyDiff(
    to: originalDocument, 
    diff: diff,
    allowTruncatedSource: true
)
```

The library handles the complexity of locating and applying the diff, even with partial or truncated sources.

## 🛡️ Reliability & Automatic Verification

MultiLineDiff includes a built-in verification system that ensures diff reliability through automatic algorithm fallback.

### Automatic Algorithm Fallback

When using the Todd algorithm (`.todd`), the library now includes a sophisticated verification mechanism:

1. **Create Diff**: Generate diff using Todd algorithm
2. **Verify Integrity**: Apply the diff to source and verify result matches destination
3. **Automatic Fallback**: If verification fails, automatically fallback to Brus algorithm
4. **Transparent Operation**: Users get reliable results without manual intervention

### How Verification Works

```swift
// When you request Todd algorithm
let diff = MultiLineDiff.createDiff(
    source: sourceCode,
    destination: destinationCode,
    algorithm: .todd  // Todd algorithm with automatic fallback
)

// Internal process:
// 1. Generate Todd diff
// 2. Apply Todd diff to source
// 3. Check: result == destination?
//    ✅ Yes → Return Todd diff (more granular)
//    ❌ No  → Automatically use Brus diff (more reliable)
```

### Verification Benefits

- **Zero False Positives**: Diffs are guaranteed to work correctly
- **Best of Both Worlds**: Get Todd's sophistication when possible, Brus's reliability when needed
- **Transparent Fallback**: No additional code required from developers
- **Metadata Tracking**: `algorithmUsed` metadata reflects actual algorithm used

### Fallback Scenarios

The system automatically falls back to Brus algorithm when:
- Todd diff produces incorrect transformation results
- Todd diff operations cannot be applied to source
- Complex text structures that challenge Todd's semantic analysis

### Example with Fallback Tracking

```swift
let diff = MultiLineDiff.createDiff(
    source: complexSource,
    destination: complexDestination,
    algorithm: .todd,
    includeMetadata: true
)

// Check which algorithm was actually used
if let actualAlgorithm = diff.metadata?.algorithmUsed {
    switch actualAlgorithm {
    case .todd:
        print("✅ Todd algorithm succeeded - granular diff")
    case .brus:
        print("🔄 Fallback to Brus algorithm - reliable diff")
    }
}

// Either way, the diff is guaranteed to work correctly
let result = try MultiLineDiff.applyDiff(to: complexSource, diff: diff)
assert(result == complexDestination) // Always passes
```

### Verification Performance Impact

- **Minimal Overhead**: Verification adds ~0.1ms for typical diffs
- **Early Exit**: If Todd succeeds (most cases), no additional processing
- **Smart Caching**: Verification results are internally optimized

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
| Memory Usage | 🧠 Low | 🤯 Higher |
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
// Todd Algorithm (.todd) - RECOMMENDED for most use cases
// ✅ Built-in verification and automatic fallback
// ✅ Best for: Code refactoring, semantic changes, structure preservation
// ✅ Fallback protection: Automatically uses Brus if Todd fails
// ✅ Zero risk: Guaranteed to produce working diffs

// Brus Algorithm (.brus) - For specific performance needs
// ⚡ Best for: Simple text changes, performance critical operations
// ⚡ Character-based modifications where speed is paramount
// ⚡ No fallback needed: Always reliable for basic transformations
```

### Algorithm Reliability Comparison

| Algorithm | Verification | Fallback | Granularity | Performance | Recommended |
|-----------|-------------|----------|-------------|-------------|-------------|
| **Todd (.todd)** | ✅ Built-in | ✅ Auto-Brus | 🎯 High | ⚡ Good | ✅ **Yes** |
| **Brus (.brus)** | ❌ None | ❌ None | 🎯 Basic | ⚡ Fast | ⚡ Performance-only |

**New in v1.2**: Todd algorithm now includes automatic verification and fallback, making it the safest choice for all scenarios.

## 🚀 Why Base64?

1. **Compact Representation**: Reduces diff size
2. **Safe Transmission**: Avoids escaping issues
3. **Universal Compatibility**: Works across different systems
4. **AI-Friendly**: Ideal for code transformation pipelines

## 🔍 Algorithm Complexity Analysis

*Based on actual performance measurements from MultiLineDiffRunner*

### Brus - Simple - Algorithm Big O Notation

| Metric | Complexity | Explanation | Real Performance | Visual |
|--------|------------|-------------|------------------|----------------------|
| **Time Complexity** | O(n) | Linear time complexity | **0.128ms create** | 🟢🟢🟢  |
| **Space Complexity** | O(1) | Constant space usage | **Minimal memory** | 🟢🟢🟢  |
| **Apply Performance** | O(n) | Direct character operations | **0.001ms apply** | 🟢🟢🟢  |
| **Total Operations** | Low | Simple retain/insert/delete | **~4 operations** | 🟢🟢🟢  |
| **Best Case** | Ω(1) | Identical strings | **<0.01ms** | 🟢🟢🟢  |
| **Worst Case** | O(n) | Complete string replacement | **~0.5ms** | 🟢🟢🟢  |

#### Performance Profile
```
Creation Speed:  🟢🟢🟢 (0.128ms)
Application:     🟢🟢🟢 (0.001ms) 
Memory Usage:    🟢🟢🟢 (Minimal)
Operation Count: 🟢🟢🟢 (4 ops)
```

### Todd - Smart - Algorithm Big O Notation

| Metric | Complexity | Explanation | Real Performance | Visual |
|--------|------------|-------------|------------------|----------------------|
| **Time Complexity** | O(n log n) | LCS-based semantic analysis | **0.374ms create** | 🟢🟡🔴  |
| **Space Complexity** | O(n) | Linear space for LCS table | **Higher memory** | 🟢🟡🔴  |
| **Apply Performance** | O(n) | Sequential operation application | **0.004ms apply** | 🟢🟢🟡  |
| **Total Operations** | High | Granular semantic operations | **~22 operations** | 🟢🟡🔴  |
| **Best Case** | Ω(n) | Simple structural changes | **~0.2ms** | 🟢🟡🔴  |
| **Worst Case** | O(n²) | Complex text transformations | **~1.0ms** | 🟡🔴🔴  |

#### Performance Profile
```
Creation Speed:  🟢🟡🔴 (0.374ms) - 2.9x slower than Brus
Application:     🟢🟢🟡 (0.004ms) - 4x slower than Brus
Memory Usage:    🟢🟡🔴 (Higher for LCS)
Operation Count: 🟢🟡🔴 (22 ops - 5.5x more detailed)
```

### Real-World Performance Comparison

*Measured on 664-character source code transformation*

| Algorithm | Create Time | Apply Time | Total Time | Operations | Speed Factor |
|-----------|-------------|------------|------------|------------|--------------|
| **Brus** | 0.128ms | 0.001ms | **0.129ms** | 4 | **1.0x** ⚡ |
| **Todd** | 0.374ms | 0.004ms | **0.378ms** | 22 | **2.9x slower** |

### Performance Visualization

```
Speed Comparison (Total Time):
Brus: ███████████████ 0.129ms
Todd: ██████████████████████████████████████████████████ 0.378ms

Operation Granularity:
Brus: ████ (4 operations - simple)
Todd: ██████████████████████████████████████████████████ (22 operations - detailed)
```

### When Each Algorithm Excels

#### Brus Algorithm - Speed Champion 🏃‍♂️
- **Ultra-fast creation**: 2.9x faster than Todd
- **Lightning apply**: 4x faster than Todd  
- **Minimal operations**: ~75% fewer operations
- **Best for**: Performance-critical applications, simple changes

#### Todd Algorithm - Precision Master 🎯
- **Granular operations**: 5.5x more detailed
- **Semantic awareness**: Preserves code structure
- **With fallback**: Zero-risk reliability
- **Best for**: Code transformations, complex changes

### Performance Recommendations

| Use Case | Recommended | Reason |
|----------|-------------|---------|
| **Real-time editing** | Brus | 0.129ms total time |
| **Bulk processing** | Brus | 2.9x speed advantage |
| **Code refactoring** | Todd + Fallback | Precision + reliability |
| **AI transformations** | Todd + Fallback | Semantic awareness |
| **Simple text edits** | Brus | Unnecessary overhead avoided |

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

// Todd algorithm with automatic fallback (recommended)
let reliableDiff = MultiLineDiff.createDiff(
    source: sourceCode, 
    destination: destinationCode, 
    algorithm: .todd  // Automatically falls back to Brus if needed
)

// Explicitly select Brus algorithm (always reliable)
let brusDiff = MultiLineDiff.createDiff(
    source: sourceCode, 
    destination: destinationCode, 
    algorithm: .brus
)
```

### Algorithm Selection Guide

| Scenario | Recommended Algorithm | Fallback Behavior |
|----------|----------------------|-------------------|
| **AI Code Transformations** | `.todd` | ✅ Automatic fallback to `.brus` |
| **Production Systems** | `.todd` | ✅ Automatic fallback to `.brus` |
| **Performance Critical** | `.brus` | ❌ No fallback needed |
| **Simple Text Changes** | `.brus` | ❌ No fallback needed |

**Best Practice**: Use `.todd` algorithm for most scenarios - you get sophisticated diffs when possible, with automatic reliability guarantees through fallback.

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

┌─ Retain closing
│ }
└─ =
```
