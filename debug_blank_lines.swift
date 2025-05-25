import Foundation

// Simulate the efficientLines implementation
extension String {
    var efficientLines: [Substring] {
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

// Test the blank line issue
let testWithBlankLine = """
## Section 3
This section has been UPDATED.
It contains REVISED information.

## Section 4
This is the last section.
"""

print("Original text:")
print("'\(testWithBlankLine)'")
print()

print("Lines with efficientLines:")
let lines = testWithBlankLine.efficientLines
for (i, line) in lines.enumerated() {
    print("  \(i): '\(line)' (length: \(line.count))")
}
print()

print("Joined back:")
let joinedBack = lines.map(String.init).joined()
print("'\(joinedBack)'")
print()

print("Are they equal? \(testWithBlankLine == joinedBack)")

// Test the specific case that's failing
let section3Lines = """
## Section 3
This section will be modified.
It contains important information.
""".efficientLines

let modifiedSection = """
## Section 3
This section has been UPDATED.
It contains REVISED information.
"""

print()
print("=== SIMULATING THE RECONSTRUCTION ===")
print("Original section 3 lines:")
for (i, line) in section3Lines.enumerated() {
    print("  \(i): '\(line)' (length: \(line.count))")
}

print()
print("Modified section text:")
print("'\(modifiedSection)'")

print()
print("Modified section split into lines:")
let modifiedLines = modifiedSection.efficientLines
for (i, line) in modifiedLines.enumerated() {
    print("  \(i): '\(line)' (length: \(line.count))")
}

print()
print("Now simulating reconstruction...")
print("If we have fullLines = [header, blank, section3line1, section3line2, section3line3, blank, section4, ...]")
print("And we replace section 3 range with modifiedLines...")

// Simulate the full document reconstruction
var fullLines: [Substring] = [
    "# Test Document\n",
    "\n",
    "## Section 1\n",
    "This is the content of section 1.\n",
    "It has multiple lines.\n",
    "\n",
    "## Section 2\n", 
    "This is the content of section 2.\n",
    "With some details here.\n",
    "\n",
    "## Section 3\n",
    "This section will be modified.\n",
    "It contains important information.\n",
    "\n",
    "## Section 4\n",
    "This is the last section.\n",
    "The end.\n"
]

print()
print("Full document lines before replacement:")
for (i, line) in fullLines.enumerated() {
    if i >= 9 && i <= 14 {
        print("  \(i): '\(line)' (length: \(line.count)) <- SECTION 3 AREA")
    } else {
        print("  \(i): '\(line)' (length: \(line.count))")
    }
}

// Find section 3 range (lines 10-12, the actual section content)
let sectionRange = 10..<13
print()
print("Section range to replace: \(sectionRange)")
print("Lines being replaced:")
for i in sectionRange {
    print("  \(i): '\(fullLines[i])' (length: \(fullLines[i].count))")
}

// Replace with modified lines 
fullLines.replaceSubrange(sectionRange, with: modifiedLines)

print()
print("Full document lines after replacement:")
for (i, line) in fullLines.enumerated() {
    print("  \(i): '\(line)' (length: \(line.count))")
}

print()
print("Final result:")
let finalResult = fullLines.map(String.init).joined()
print("'\(finalResult)'") 