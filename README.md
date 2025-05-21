# Swift Multi Line Diff

A Swift package for creating and applying diffs to multi-line Unicode/UTF-8 text strings, with support for JSON serialization.

## Features

- Generate diffs between two strings using two advanced diff algorithms:
  - The Brus Diff Algorithm: A simple and reliable approach for text transformations
  - The Todd Diff Algorithm: A more granular method for detailed multi-line changes
- Apply diffs to transform one string into another
- Full support for multi-line text
- Support for Unicode/UTF-8 characters
- JSON serialization for storing and sharing diffs
- Clean, Simple API
- Comprehensive test suite

## Requirements

- Swift 6.1 or later

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/MultiLineDiff.git", from: "1.0.0")
]
```

## Usage

### Basic Usage

```swift
import MultiLineDiff

// Simple text changes
let source = "Hello, world!"
let destination = "Hello, Swift!"

// Create and apply a diff
let diff = MultiLineDiff.createDiffBrus(source: source, destination: destination)
let result = try? MultiLineDiff.applyDiff(to: source, diff: diff) // "Hello, Swift!"

// Multi-line changes
let code = """
func greet() {
    print("Hello")
}
"""

let updatedCode = """
func greet(_ name: String) {
    print("Hello, \\(name)!")
}
"""

// Use Todd's algorithm for code changes
let codeDiff = MultiLineDiff.createDiffTodd(source: code, destination: updatedCode)
```

### Working with Diffs

```swift
// Create a diff
let diff = MultiLineDiff.createDiffBrus(
    source: "Hello, world!",
    destination: "Hello, Swift!"
)

// Inspect operations
diff.operations.forEach { op in
    switch op {
    case .retain(let count): print("Keep \(count) chars")
    case .delete(let count): print("Delete \(count) chars")
    case .insert(let text): print("Insert \"\(text)\"")
    }
}
```

### JSON Handling

```swift
// Save diff to JSON
let diff = MultiLineDiff.createDiffBrus(source: "old", destination: "new")
let json = try? MultiLineDiff.encodeDiffToJSONString(diff)

// Load from JSON
if let json = json {
    let loadedDiff = try? MultiLineDiff.decodeDiffFromJSONString(json)
}

// File operations
let fileURL = URL(fileURLWithPath: "diff.json")
try? MultiLineDiff.saveDiffToFile(diff, fileURL: fileURL)
let loadedDiff = try? MultiLineDiff.loadDiffFromFile(fileURL: fileURL)
```

### Error Handling

```swift
do {
    let diff = MultiLineDiff.createDiffBrus(source: "old", destination: "new")
    let result = try MultiLineDiff.applyDiff(to: "old", diff: diff)
} catch let error as DiffError {
    switch error {
    case .invalidRetain(let count, _):
        print("Can't retain \(count) chars")
    case .invalidDelete(let count, _):
        print("Can't delete \(count) chars")
    case .incompleteApplication(let remaining):
        print("\(remaining) chars not processed")
    case .encodingFailed:
        print("JSON encoding failed")
    case .decodingFailed:
        print("JSON decoding failed")
    }
}
```

### Multi-line Example

```swift
let source = """
struct User {
    let name: String
    let age: Int
    
    func description() -> String {
        return "\(name) is \(age) years old"
    }
}
"""

let destination = """
struct User {
    let name: String
    let age: Int
    let email: String  // Added field
    
    func description() -> String {
        return "\(name) (\(email)) is \(age) years old"
    }
    
    func isAdult() -> Bool {  // Added method
        return age >= 18
    }
}
"""

// Brus algorithm - simple but effective
let brusDiff = MultiLineDiff.createDiffBrus(source: source, destination: destination)
// Result: One large delete and insert operation for the changed region

// Todd algorithm - line-by-line analysis
let toddDiff = MultiLineDiff.createDiffTodd(source: source, destination: destination)
// Result: Precise operations showing:
// - Unchanged struct header and first two fields
// - Inserted email field
// - Modified description method
// - Added isAdult method

// Both produce the same result when applied
let brusResult = try? MultiLineDiff.applyDiff(to: source, diff: brusDiff)
let toddResult = try? MultiLineDiff.applyDiff(to: source, diff: toddDiff)
assert(brusResult == toddResult) // true
```

## How It Works

### Brus Diff Method
The Brus algorithm uses a simple but effective approach that:
1. Finds common prefixes and suffixes between strings
2. Represents the middle differences as delete and insert operations
3. Combines these operations into a sequence that can transform the source into the destination
4. Best for simple text changes and performance-critical operations

### Todd Diff Method
The Todd algorithm offers a more granular approach:
1. Performs line-by-line analysis
2. Creates nested diffs with more detailed change tracking
3. Supports complex multi-line transformations with high precision
4. Best for source code and structured text changes

Both methods are:
- Reliable for all text, including multi-line and Unicode content
- Efficient for most text operations
- Easy to understand and maintain

## Performance Considerations

- The Brus algorithm is optimized for simple text changes and is generally faster
- The Todd algorithm provides more detailed diffs but may be slower for large files
- Both algorithms use efficient string handling and memory management
- JSON operations are optimized for minimal memory usage

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. 
