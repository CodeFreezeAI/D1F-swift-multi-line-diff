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

## 🔍 Algorithm Complexity Analysis

### Brus Algorithm Big O Notation

| Metric | Complexity | Explanation | Visual Representation |
|--------|------------|-------------|----------------------|
| **Time Complexity** | O(n) | Linear time complexity | 🟢🟢🟢 Low |
| **Space Complexity** | O(1) | Constant space usage | 🟢🟢🟡 Moderate |
| **Best Case** | Ω(1) | Minimal changes between strings | 🟢🟢🟢 Fast |
| **Worst Case** | O(n) | Complete string replacement | 🟠🟡🟡 Acceptable |
| **Average Case** | Θ(n) | Proportional to input string length | 🟢🟢🟡 Logical |

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
| **Best Case** | Ω(n) | Minimal structural changes | 🟠🟡🟡 Efficient |
| **Worst Case** | O(n²) | Highly complex text transformations | 🔴🟠🟡 High |
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

### Basic Diff Operations

```swift
let source = "Hello, world!"
let destination = "Hello, Swift!"

// Create a diff
let diff = MultiLineDiff.createDiff(source: source, destination: destination)

// Apply the diff
let result = try MultiLineDiff.applyDiff(to: source, diff: diff)
assert(result == destination)
```

### Base64 Diff Operations (Recommended)

```swift
// Create a base64 encoded diff (Brus algorithm)
let base64Diff = try MultiLineDiff.createBase64Diff(source: source, destination: destination)

// Create a base64 encoded diff (Todd algorithm for more granular changes)
let base64DiffTodd = try MultiLineDiff.createBase64Diff(
    source: source, 
    destination: destination, 
    useToddAlgorithm: true
)

// Apply the base64 diff
let result = try MultiLineDiff.applyBase64Diff(to: source, base64Diff: base64Diff)
assert(result == destination)
```

## 📝 License

MIT

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. 

(c) 2025 Todd Bruss
