# Swift Multi Line Diff 1.0.5

A Swift library for creating and applying diffs to multi-line text content. Supports Unicode/UTF-8 strings and handles multi-line content properly. Designed specifically for Vibe AI Coding integrity and safe code transformations.

## Features

- Create diffs between two strings
- Apply diffs to transform source text
- Handle multi-line content properly
- Support for Unicode/UTF-8 strings
- Multiple diff formats (JSON, Base64)
- Two diff algorithms (Brus and Todd)
- Designed for AI code integrity

## Why Base64?

MultiLineDiff uses base64 encoding for several critical reasons:

1. **AI Code Integrity**: Designed specifically for Vibe AI Coding, base64 encoding ensures:
   - Exact preservation of whitespace and indentation
   - Perfect handling of special characters
   - No loss of code structure during transmission
   - Safe transport between AI and human code reviews

2. **Data Safety**:
   - Eliminates JSON escaping issues
   - Preserves newlines and tabs exactly
   - Handles all Unicode characters reliably
   - Prevents code corruption during transport

3. **Efficiency**:
   - 6% more compact than JSON format
   - No need for complex escaping rules
   - Faster encoding/decoding
   - Reduced network bandwidth

## Usage

### Basic Diff Operations

```swift
let source = "Hello, world!"
let destination = "Hello, Swift!"

// Create a diff
let diff = MultiLineDiff.createDiffBrus(source: source, destination: destination)

// Apply the diff
let result = try MultiLineDiff.applyDiff(to: source, diff: diff)
assert(result == destination)
```

### Base64 Diff Operations (Recommended)

The recommended way to create and apply diffs, especially for AI code transformations:

```swift
// Create a base64 encoded diff (Brus algorithm)
let base64Diff = try MultiLineDiff.createBase64Diff(source: source, destination: destination)

// Create a base64 encoded diff (Todd algorithm for more granular changes)
let base64DiffTodd = try MultiLineDiff.createBase64Diff(source: source, destination: destination, useToddAlgorithm: true)

// Apply the base64 diff
let result = try MultiLineDiff.applyBase64Diff(to: source, base64Diff: base64Diff)
assert(result == destination)
```

### JSON Diff Operations

For cases where structured storage is needed:

```swift
// Create a diff and encode to JSON
let diff = MultiLineDiff.createDiffBrus(source: source, destination: destination)
let jsonString = try MultiLineDiff.encodeDiffToJSONString(diff)

// Decode from JSON and apply
let decodedDiff = try MultiLineDiff.decodeDiffFromJSONString(jsonString)
let result = try MultiLineDiff.applyDiff(to: source, diff: decodedDiff)
assert(result == destination)
```

### File Operations

```swift
// Save diff to file
try MultiLineDiff.saveDiffToFile(diff, fileURL: fileURL)

// Load diff from file
let loadedDiff = try MultiLineDiff.loadDiffFromFile(fileURL: fileURL)
```

### Advanced Usage: Todd Algorithm

For more granular diffs, especially with source code:

```swift
let source = """
class Example {
    func method() {
        print("Hello")
    }
}
"""

let destination = """
class Example {
    // Added comment
    func method() {
        print("Hello, world!")
    }
}
"""

// Create diff using Todd algorithm
let diff = MultiLineDiff.createDiffTodd(source: source, destination: destination)
```

## Diff Formats

### Base64 Format (Recommended)
The base64 format is the most compact and efficient way to store diffs. It directly encodes the diff operations without any additional structure, making it perfect for AI code transformations. The format:
- Preserves exact whitespace and indentation
- Handles all special characters reliably
- Is safe for network transmission
- Reduces storage size

Example base64 diff:
```
W3sicmV0YWluIjoxMH0seyJkZWxldGUiOjV9LHsiaW5zZXJ0IjoiSGVsbG8sIFN3aWZ0IWJ9
```

### JSON Format
The JSON format wraps the base64-encoded operations in a structured format:
```json
{
    "base64": "encoded_operations_string"
}
```

Both formats preserve all whitespace and special characters exactly.

## Performance Considerations

- The Brus algorithm is optimized for simple text changes and is generally faster
- The Todd algorithm provides more detailed diffs but may be slower for large files
- Base64 encoding provides the most compact storage format (6% smaller than JSON)
- JSON format adds structure but increases storage size slightly

## AI Code Integrity

MultiLineDiff is specifically designed for Vibe AI Coding integrity:

1. **Safe Transformations**:
   - Preserves code structure exactly
   - Maintains indentation and formatting
   - Handles all programming language constructs

2. **Reliable Transport**:
   - Base64 encoding ensures safe transmission
   - No corruption of whitespace or special characters
   - Perfect preservation of code style

3. **Verification**:
   - Easy to verify code changes
   - Supports both simple and complex transformations
   - Maintains coding standards

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. 

(c) 2025 Todd Bruss
