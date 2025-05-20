# MultiLineDiff

A Swift package for creating and applying diffs to multi-line Unicode/UTF-8 text strings.

## Features

- Generate diffs between two strings using two advanced diff algorithms:
  - The Brus Diff Algorithm: A simple and reliable approach for text transformations
  - The Todd Diff Algorithm: A more granular method for detailed multi-line changes
- Apply diffs to transform one string into another
- Full support for multi-line text
- Support for Unicode/UTF-8 characters
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

### Creating a Diff

```swift
import MultiLineDiff

let sourceText = """
This is line one.
This is line two.
This is line three.
"""

let destinationText = """
This is line one.
This is a modified line two.
This is line three.
This is a new line four.
"""

// Create a diff using the Brus method
let brussDiff = MultiLineDiff.createDiffBrus(source: sourceText, destination: destinationText)

// Create a diff using the Todd method (more granular)
let toddDiff = MultiLineDiff.createDiffTodd(source: sourceText, destination: destinationText)
```

### Applying a Diff

```swift
import MultiLineDiff

// Apply the Brus diff to transform the source text into the destination text
do {
    let resultText = try MultiLineDiff.applyDiff(to: sourceText, diff: brussDiff)
    // resultText will be equal to destinationText
} catch {
    print("Error applying Brus diff: \(error)")
}

// Apply the Todd diff (with the same method)
do {
    let resultText = try MultiLineDiff.applyDiffTodd(to: sourceText, diff: toddDiff)
    // resultText will be equal to destinationText
} catch {
    print("Error applying Todd diff: \(error)")
}
```

### Working with Diff Operations

The `DiffResult` contains a series of operations that transform the source string into the destination string:

```swift
import MultiLineDiff

let diff = MultiLineDiff.createDiffBrus(source: "Hello, world!", destination: "Hello, Swift!")

// Inspect the operations
for operation in diff.operations {
    print(operation.description)
}

// Output:
// retain 7 characters
// delete 5 characters
// insert "Swift"
// retain 1 character
```

## How It Works

The library provides two distinct diff algorithms:

### Brus Diff Method
The Brus algorithm uses a simple but effective approach that:
1. Finds common prefixes and suffixes between strings
2. Represents the middle differences as delete and insert operations
3. Combines these operations into a sequence that can transform the source into the destination

### Todd Diff Method
The Todd algorithm offers a more granular approach:
1. Performs line-by-line and character-level analysis
2. Creates nested diffs with more detailed change tracking
3. Supports complex multi-line transformations with high precision

Both methods are:
- Reliable for all text, including multi-line and Unicode content
- Efficient for most text operations
- Easy to understand and maintain

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. 
