# MultiLineDiff 1.0.6

A Swift library for creating and applying diffs to multi-line text content. Supports Unicode/UTF-8 strings and handles multi-line content properly. Designed specifically for Vibe AI Coding integrity and safe code transformations.

## 🌟 Key Features

- Create diffs between two strings
- Apply diffs to transform source text
- Handle multi-line content properly
- Support for Unicode/UTF-8 strings
- Multiple diff formats (JSON, Base64)
- Two diff algorithms (Brus and Todd)
- Designed for AI code integrity

## 🚀 Performance Optimizations for Swift 6.1

### Speed Optimization
- **Compile-Time Inlining**: Utilizes Swift 6.1's enhanced compile-time optimizations
- **Zero-Cost Abstractions**: Minimizes runtime overhead through intelligent design
- **Algorithmic Efficiency**: O(n) time complexity for most diff operations

### Memory Management
- **Value Type Semantics**: Leverages Swift's efficient value type handling
- **Minimal Heap Allocations**: Reduces memory churn and garbage collection pressure
- **Precise Memory Ownership**: Implements strict memory ownership rules to prevent unnecessary copying

### Comparative Performance

| Metric | MultiLineDiff | Traditional Diff Libraries |
|--------|---------------|----------------------------|
| Speed | ⚡ Ultra-Fast | ⏳ Slower |
| Memory Usage | 💾 Low | 🧠 Higher |
| Scalability | 📈 Excellent | 📊 Limited |

## 📦 Diff Representation Formats

### Diff Operation Types

```swift
enum DiffOperation {
    case retain(Int)     // Keep existing characters
    case delete(Int)     // Remove characters
    case insert(String)  // Add new characters
    case replace(String) // Replace with new content
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
let diffOperations = MultiLineDiff.createDiff(
    source: sourceCode, 
    destination: destinationCode
)

// Diff Operations Breakdown
print("Diff Operations:")
// Typical output might look like:
// 1. Retain first 15 characters of the class definition
// 2. Replace "oldMethod()" with "newMethod()"
// 3. Replace print statement
```

### Base64 Diff Decoding Example

```swift
// Create Base64 encoded diff
let base64Diff = try MultiLineDiff.createBase64Diff(
    source: sourceCode, 
    destination: destinationCode
)

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
print("Decoded Diff:")
print(decodedDiffOperations)

// Typical decoded output might look like:
// [
//   {"retain": 15},
//   {"replace": "newMethod() {\n        print(\"Hello, World!\")\n    }"}
// ]
```

### Diff Visualization

```
Original Code:
class Example {
    func oldMethod() {
        print("Hello")
    }
}

Diff Operations:
1. ✅ Retain "class Example {\n    "  (15 chars)
2. 🔄 Replace "func oldMethod()" with "func newMethod()"
3. 🔄 Replace print statement with more detailed version

Transformed Code:
class Example {
    func newMethod() {
        print("Hello, World!")
    }
}
```

### Practical Diff Decoding

```swift
// Full decoding and application process
let reconstructedCode = try MultiLineDiff.applyBase64Diff(
    to: sourceCode, 
    base64Diff: base64Diff
)

// Verify the transformation
assert(reconstructedCode == destinationCode, "Diff application failed")
```

## 🔍 Diff Operation Insights

### Operation Types

| Operation | Symbol | Meaning |
|-----------|--------|---------|
| Retain    | ✅ | Keep existing content |
| Delete    | ❌ | Remove content |
| Insert    | ➕ | Add new content |
| Replace   | 🔄 | Swap out content |

### Basic Examples

```swift
Source:      "Hello, world!"
Destination: "Hello, Swift!"
Operations:   ✅✅✅✅✅✅ 🔄     // "Hello, " retained, "world" replaced with "Swift"
```

### Multi-Line Example

```swift
// Source
func oldMethod() {
    print("Hello")
}

// Destination
func newMethod() {
    print("Hello, World!")
}

// Operations:
func ✅🔄✅ () {          // "func " retained, "old" → "new", "Method" retained
    🔄                   // print statement replaced
}✅                      // closing brace retained
```

### Real-World Complex Example (Algorithm Comparison)

```swift
// Source Code
func calculateTotal(items: [Product]) -> Double {
    var total = 0.0
    for item in items {
        total += item.price
    }
    return total
}

// Destination Code
func calculateTotal(items: [Product]) -> Double {
    return items.reduce(0.0) { $0 + $1.price }
}

// Todd Algorithm (.todd) - Semantic Understanding
┌─ Analysis
│ ✅ Signature preserved (semantic match)
│ 🔄 Loop construct transformed to functional approach
│ ❌ Imperative accumulator removed
│ ➕ Functional reduce operation added
└─ Result: More granular, semantic-aware changes

// Brus Algorithm (.brus) - Character-based
┌─ Analysis
│ ✅ Matching prefix
│ ❌ Bulk content removal
│ ➕ New content insertion
│ ✅ Matching suffix
└─ Result: Simpler, character-based changes

// Visual Comparison
Todd Algorithm:
┌─ Signature
│ func calculateTotal(items: [Product]) -> Double {
│ ✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅
└─ Semantic preservation

┌─ Implementation
│ ❌ var total = 0.0
│ ❌ for item in items {
│ ❌     total += item.price
│ ❌ }
│ ❌ return total
│ ➕ return items.reduce(0.0) { $0 + $1.price }
└─ Semantic transformation

Brus Algorithm:
┌─ Content
│ ✅ func calculateTotal(items: [Product]) -> Double {
│ ❌ [entire old implementation]
│ ➕ [entire new implementation]
│ ✅ }
└─ Character-based changes

// Performance Impact
Todd (.todd):
- More operations but semantically meaningful
- Better for code refactoring
- Preserves code structure

Brus (.brus):
- Fewer operations but less granular
- Better for simple text changes
- Faster for basic transformations
```

### When to Use Each Algorithm

```swift
// Automatic algorithm selection
let algorithm = MultiLineDiff.suggestDiffAlgorithm(
    source: sourceCode,
    destination: destinationCode
)

// Result will be:
// .todd for:
// - Code refactoring
// - Semantic changes
// - Structure preservation

// .brus for:
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
| **Worst Case** | O(n) | Complete string replacement | 🟠🟡🟡 Efficient |
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
| **Space Complexity** | O(n) | Linear space usage | 🟢🟠🟡 Moderate |
| **Best Case** | Ω(n) | Minimal structural changes | 🟢🟠🟡 Effective |
| **Worst Case** | O(n²) | Highly complex text transformations | 🟠🟡🟡 High |
| **Average Case** | Θ(n log n) | Semantic analysis overhead | 🟢🟠🟡 Moderate |

#### Performance Gradient
```
Complexity:     🟢🟠🟡
Memory Usage:   🟢🟠🟡
Speed:          🟠🟡🟡
```

### Comparative Performance Visualization

```
Brus Algorithm:  🟢🟢🟢
Todd Algorithm:  🟢🟠🟡
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
    case replace(String) // Replace with new content
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

### Replace Operation Example

```swift
Source:      "Hello, world!"
Destination: "Hello, Swift!"
Operation:    ====== ~~~~~    // Replace "world" with "Swift"
             |||||| -----
             Hello, world
                    Swift
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
func ===~~~~~=== () {     // retain "func ", replace "old" with "new", retain "Method"
    ~~~~~~~~~~~~~~~~~~~~  // replace entire print statement
}===                     // retain closing brace

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

┌─ Replace implementation
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
| `~~~~` | Replace   | Change text |
| `||||` | Match     | Shows matching characters |
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
// W3sicmV0YWluIjo1fSx7InJlcGxhY2UiOiJuZXcifSx7InJldGFpbiI6N31d...

// Operations represented in the base64:
// ✅ Retain "func "
// 🔄 Replace "old" with "new"
// ✅ Retain "Method"
// 🔄 Replace print statement
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
