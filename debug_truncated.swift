import Foundation

// Simulate the efficientLines implementation
extension String {
    var oldEfficientLines: [Substring] {
        return self.split(separator: "\n", omittingEmptySubsequences: false)
    }
    
    var newEfficientLines: [Substring] {
        guard !isEmpty else { return [] }
        
        var lines: [Substring] = []
        var currentIndex = startIndex
        
        while currentIndex < endIndex {
            if let newlineIndex = self[currentIndex...].firstIndex(of: "\n") {
                let lineEndIndex = index(after: newlineIndex)
                lines.append(self[currentIndex..<lineEndIndex])
                currentIndex = lineEndIndex
            } else {
                lines.append(self[currentIndex...])
                break
            }
        }
        
        return lines
    }
}

// Debug the truncated diff issue
let testString = "Line1\nLine2\nLine3"
print("Original string: '\(testString)'")
print()

print("OLD style lines (split without preserving newlines):")
let oldLines = testString.oldEfficientLines
for (i, line) in oldLines.enumerated() {
    print("  \(i): '\(line)' (length: \(line.count))")
}
print()

print("NEW style lines (efficientLines with preserved newlines):")
let newLines = testString.newEfficientLines
for (i, line) in newLines.enumerated() {
    print("  \(i): '\(line)' (length: \(line.count))")
}
print()

print("ISSUE: When truncated diff joins NEW lines with separator '\\n':")
let problemJoin = newLines.joined(separator: "\n")
print("Result: '\(problemJoin)'")
print("Length: \(problemJoin.count)")
print("Notice: DOUBLE newlines because each line already ends with \\n!")
print()

print("When split again (as truncated diff does):")
let splitResult = problemJoin.split(separator: "\n", omittingEmptySubsequences: false)
for (i, line) in splitResult.enumerated() {
    print("  \(i): '\(line)' (length: \(line.count))")
}
print("Notice: EMPTY strings between lines!")
print()

print("SOLUTION: Use different join strategy for lines with newlines")
let fixedJoin = newLines.map(String.init).joined()
print("Fixed result: '\(fixedJoin)'")
print("Length: \(fixedJoin.count)") 