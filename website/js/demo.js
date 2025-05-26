// Demo functionality for MultiLineDiff Website
document.addEventListener('DOMContentLoaded', function() {
    initDemo();
});

function initDemo() {
    const generateBtn = document.getElementById('generate-diff');
    const loadExampleBtn = document.getElementById('load-example');
    const clearDestBtn = document.getElementById('clear-dest');
    const algorithmSelect = document.getElementById('algorithm-select');
    const formatSelect = document.getElementById('format-select');
    const sourceInput = document.getElementById('source-input');
    const destInput = document.getElementById('dest-input');
    const diffOutput = document.getElementById('diff-output');
    const outputStats = document.getElementById('output-stats');

    // Example code snippets
    const examples = {
        swift: {
            source: `func greet(name: String) -> String {
    return "Hello, \\(name)!"
}

class Calculator {
    private var result: Double = 0
    
    func add(_ value: Double) {
        result += value
    }
    
    func getResult() -> Double {
        return result
    }
}`,
            destination: `func greet(name: String, greeting: String = "Hello") -> String {
    return "\\(greeting), \\(name)!"
}

class Calculator {
    private var result: Double = 0
    private var history: [Double] = []
    
    func add(_ value: Double) -> Double {
        result += value
        history.append(value)
        return result
    }
    
    func getResult() -> Double {
        return result
    }
    
    func getHistory() -> [Double] {
        return history
    }
    
    func reset() {
        result = 0
        history.removeAll()
    }
}`
        },
        javascript: {
            source: `function calculateTotal(items) {
    let total = 0;
    for (let item of items) {
        total += item.price;
    }
    return total;
}

class ShoppingCart {
    constructor() {
        this.items = [];
    }
    
    addItem(item) {
        this.items.push(item);
    }
    
    getTotal() {
        return calculateTotal(this.items);
    }
}`,
            destination: `function calculateTotal(items, taxRate = 0) {
    let subtotal = 0;
    for (let item of items) {
        subtotal += item.price * item.quantity;
    }
    const tax = subtotal * taxRate;
    return subtotal + tax;
}

class ShoppingCart {
    constructor(taxRate = 0.08) {
        this.items = [];
        this.taxRate = taxRate;
        this.discounts = [];
    }
    
    addItem(item) {
        if (!item.quantity) {
            item.quantity = 1;
        }
        this.items.push(item);
    }
    
    removeItem(itemId) {
        this.items = this.items.filter(item => item.id !== itemId);
    }
    
    applyDiscount(discount) {
        this.discounts.push(discount);
    }
    
    getSubtotal() {
        return calculateTotal(this.items);
    }
    
    getTotal() {
        let total = calculateTotal(this.items, this.taxRate);
        for (let discount of this.discounts) {
            total -= discount.amount;
        }
        return Math.max(0, total);
    }
}`
        },
        python: {
            source: `def calculate_fibonacci(n):
    if n <= 1:
        return n
    return calculate_fibonacci(n-1) + calculate_fibonacci(n-2)

class NumberProcessor:
    def __init__(self):
        self.numbers = []
    
    def add_number(self, num):
        self.numbers.append(num)
    
    def get_sum(self):
        return sum(self.numbers)`,
            destination: `def calculate_fibonacci(n, memo={}):
    if n in memo:
        return memo[n]
    if n <= 1:
        return n
    memo[n] = calculate_fibonacci(n-1, memo) + calculate_fibonacci(n-2, memo)
    return memo[n]

class NumberProcessor:
    def __init__(self, max_size=1000):
        self.numbers = []
        self.max_size = max_size
        self._sum_cache = None
    
    def add_number(self, num):
        if len(self.numbers) >= self.max_size:
            raise ValueError("Maximum capacity reached")
        self.numbers.append(num)
        self._sum_cache = None  # Invalidate cache
    
    def remove_number(self, num):
        if num in self.numbers:
            self.numbers.remove(num)
            self._sum_cache = None
    
    def get_sum(self):
        if self._sum_cache is None:
            self._sum_cache = sum(self.numbers)
        return self._sum_cache
    
    def get_average(self):
        if not self.numbers:
            return 0
        return self.get_sum() / len(self.numbers)
    
    def clear(self):
        self.numbers.clear()
        self._sum_cache = None`
        }
    };

    // Load example button
    if (loadExampleBtn) {
        loadExampleBtn.addEventListener('click', () => {
            const exampleKeys = Object.keys(examples);
            const randomExample = examples[exampleKeys[Math.floor(Math.random() * exampleKeys.length)]];
            
            if (sourceInput) sourceInput.value = randomExample.source;
            if (destInput) destInput.value = randomExample.destination;
            
            // Add loading animation
            loadExampleBtn.classList.add('loading');
            setTimeout(() => {
                loadExampleBtn.classList.remove('loading');
                loadExampleBtn.textContent = 'Example Loaded!';
                setTimeout(() => {
                    loadExampleBtn.textContent = 'Load Example';
                }, 1500);
            }, 500);
        });
    }

    // Clear destination button
    if (clearDestBtn) {
        clearDestBtn.addEventListener('click', () => {
            if (destInput) {
                destInput.value = '';
                destInput.focus();
            }
        });
    }

    // Generate diff button
    if (generateBtn) {
        generateBtn.addEventListener('click', () => {
            generateDiff();
        });
    }

    // Auto-generate on input change (debounced)
    const debouncedGenerate = debounce(generateDiff, 1000);
    
    if (sourceInput) {
        sourceInput.addEventListener('input', debouncedGenerate);
    }
    
    if (destInput) {
        destInput.addEventListener('input', debouncedGenerate);
    }

    if (algorithmSelect) {
        algorithmSelect.addEventListener('change', generateDiff);
    }

    if (formatSelect) {
        formatSelect.addEventListener('change', generateDiff);
    }

    function generateDiff() {
        const source = sourceInput?.value || '';
        const destination = destInput?.value || '';
        const algorithm = algorithmSelect?.value || 'megatron';
        const format = formatSelect?.value || 'ai';

        if (!source.trim() || !destination.trim()) {
            showPlaceholder();
            return;
        }

        // Show loading state
        if (diffOutput) {
            diffOutput.innerHTML = '<div class="loading-spinner"></div><p>Generating diff...</p>';
            diffOutput.classList.add('loading');
        }

        // Simulate diff generation (in real implementation, this would call the actual MultiLineDiff library)
        setTimeout(() => {
            const result = simulateDiffGeneration(source, destination, algorithm, format);
            displayDiffResult(result);
        }, 800);
    }

    function simulateDiffGeneration(source, destination, algorithm, format) {
        // This is a simulation - in a real implementation, you would call the actual MultiLineDiff library
        const sourceLines = source.split('\n');
        const destLines = destination.split('\n');
        
        // Calculate basic stats
        const stats = {
            algorithm: algorithm,
            format: format,
            sourceLines: sourceLines.length,
            destLines: destLines.length,
            operations: Math.floor(Math.random() * 50) + 5,
            createTime: getAlgorithmTime(algorithm, 'create'),
            applyTime: getAlgorithmTime(algorithm, 'apply')
        };

        // Generate ASCII diff simulation
        let diffContent = '';
        
        if (format === 'ai' || format === 'terminal') {
            diffContent = generateASCIIDiff(sourceLines, destLines);
        } else if (format === 'json') {
            diffContent = generateJSONDiff(sourceLines, destLines);
        } else if (format === 'base64') {
            diffContent = generateBase64Diff(sourceLines, destLines);
        }

        return {
            content: diffContent,
            stats: stats
        };
    }

    function generateASCIIDiff(sourceLines, destLines) {
        let diff = '';
        const maxLines = Math.max(sourceLines.length, destLines.length);
        
        for (let i = 0; i < maxLines; i++) {
            const sourceLine = sourceLines[i];
            const destLine = destLines[i];
            
            if (sourceLine === destLine) {
                // Unchanged line
                if (sourceLine !== undefined) {
                    diff += `📎 ${sourceLine}\n`;
                }
            } else {
                // Changed line
                if (sourceLine !== undefined) {
                    diff += `❌ ${sourceLine}\n`;
                }
                if (destLine !== undefined) {
                    diff += `✅ ${destLine}\n`;
                }
            }
        }
        
        return diff.trim();
    }

    function generateJSONDiff(sourceLines, destLines) {
        const operations = [];
        
        // Simulate operations
        operations.push({ "=": 5 }); // retain 5 chars
        operations.push({ "-": 3 }); // delete 3 chars
        operations.push({ "+": "new content" }); // insert content
        operations.push({ "=": 10 }); // retain 10 chars
        
        const metadata = {
            "str": 0,
            "cnt": sourceLines.length,
            "alg": "megatron",
            "app": "requiresFullSource",
            "tim": 0.0234
        };

        return JSON.stringify({
            "df": operations,
            "md": metadata
        }, null, 2);
    }

    function generateBase64Diff(sourceLines, destLines) {
        const jsonDiff = generateJSONDiff(sourceLines, destLines);
        return btoa(jsonDiff);
    }

    function getAlgorithmTime(algorithm, operation) {
        const times = {
            flash: { create: 14.5, apply: 6.6 },
            zoom: { create: 23.9, apply: 9.1 },
            optimus: { create: 43.7, apply: 6.6 },
            starscream: { create: 45.1, apply: 6.9 },
            megatron: { create: 47.8, apply: 7.0 }
        };
        
        return times[algorithm]?.[operation] || 25.0;
    }

    function displayDiffResult(result) {
        if (!diffOutput) return;

        diffOutput.classList.remove('loading');
        
        // Display the diff content
        const format = formatSelect?.value || 'ai';
        
        if (format === 'ai' || format === 'terminal') {
            const cssClass = format === 'terminal' ? 'ascii-diff terminal-colors' : 'ascii-diff';
            diffOutput.innerHTML = `<pre class="${cssClass}"><code class="language-swift">${escapeHtml(result.content)}</code></pre>`;
            
            // Apply syntax highlighting for ASCII diff
            highlightASCIIDiff(diffOutput.querySelector('.ascii-diff'));
            
            // Apply Prism.js syntax highlighting for AI format
            if (format === 'ai' && window.Prism) {
                Prism.highlightElement(diffOutput.querySelector('code'));
            }
        } else {
            diffOutput.innerHTML = `<pre><code class="language-json">${escapeHtml(result.content)}</code></pre>`;
            
            // Apply Prism.js highlighting
            if (window.Prism) {
                Prism.highlightElement(diffOutput.querySelector('code'));
            }
        }

        // Update stats
        updateOutputStats(result.stats);

        // Add success animation
        diffOutput.classList.add('animate-fade-in');
    }

    function highlightASCIIDiff(element) {
        if (!element) return;
        
        // For terminal colors, apply simple line-based highlighting
        if (element.classList.contains('terminal-colors')) {
            const codeElement = element.querySelector('code');
            if (codeElement) {
                const lines = codeElement.textContent.split('\n');
                const highlightedLines = lines.map(line => {
                    if (line.startsWith('📎')) {
                        return `<span class="retain">${escapeHtml(line)}</span>`;
                    } else if (line.startsWith('❌')) {
                        return `<span class="delete">${escapeHtml(line)}</span>`;
                    } else if (line.startsWith('✅')) {
                        return `<span class="insert">${escapeHtml(line)}</span>`;
                    }
                    return escapeHtml(line);
                });
                codeElement.innerHTML = highlightedLines.join('\n');
            }
        }
        // For AI format, let Prism.js handle the syntax highlighting
        // The emoji symbols will be part of the Swift syntax highlighting
    }

    function updateOutputStats(stats) {
        if (!outputStats) return;

        const algorithmEmojis = {
            flash: '⚡',
            optimus: '🤖',
            megatron: '🧠',
            starscream: '🌟',
            zoom: '🔍'
        };

        const formatEmojis = {
            ai: '🤖',
            terminal: '🌈',
            json: '📊',
            base64: '🔐'
        };

        outputStats.innerHTML = `
            <span class="stat-badge">${algorithmEmojis[stats.algorithm] || '🔧'} ${stats.algorithm}</span>
            <span class="stat-badge">${formatEmojis[stats.format] || '📄'} ${stats.format}</span>
            <span class="stat-badge">⚡ ${stats.createTime}ms</span>
            <span class="stat-badge">📊 ${stats.operations} ops</span>
        `;
    }

    function showPlaceholder() {
        if (!diffOutput) return;
        
        diffOutput.innerHTML = `
            <div class="placeholder">
                <div class="placeholder-icon">📊</div>
                <p>Enter source and destination code to generate a diff</p>
            </div>
        `;
        
        if (outputStats) {
            outputStats.innerHTML = '';
        }
    }

    function escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    // Utility function (reuse from main.js if available)
    function debounce(func, wait, immediate) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                timeout = null;
                if (!immediate) func(...args);
            };
            const callNow = immediate && !timeout;
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
            if (callNow) func(...args);
        };
    }

    // Initialize with placeholder
    showPlaceholder();

    // Add keyboard shortcuts
    document.addEventListener('keydown', (e) => {
        // Ctrl/Cmd + Enter to generate diff
        if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
            e.preventDefault();
            generateDiff();
        }
        
        // Ctrl/Cmd + L to load example
        if ((e.ctrlKey || e.metaKey) && e.key === 'l') {
            e.preventDefault();
            if (loadExampleBtn) loadExampleBtn.click();
        }
    });

    // Add copy to clipboard functionality
    function addCopyButton() {
        const copyBtn = document.createElement('button');
        copyBtn.className = 'btn btn-small copy-btn';
        copyBtn.innerHTML = '📋 Copy';
        copyBtn.style.position = 'absolute';
        copyBtn.style.top = '10px';
        copyBtn.style.right = '10px';
        
        copyBtn.addEventListener('click', () => {
            const content = diffOutput.textContent;
            navigator.clipboard.writeText(content).then(() => {
                copyBtn.innerHTML = '✅ Copied!';
                setTimeout(() => {
                    copyBtn.innerHTML = '📋 Copy';
                }, 2000);
            });
        });

        if (diffOutput && diffOutput.querySelector('pre')) {
            diffOutput.style.position = 'relative';
            diffOutput.appendChild(copyBtn);
        }
    }

    // Add copy button when diff is generated
    const originalDisplayDiffResult = displayDiffResult;
    displayDiffResult = function(result) {
        originalDisplayDiffResult(result);
        setTimeout(addCopyButton, 100);
    };
}

// Export for use in other modules
window.DemoModule = {
    generateDiff: () => {
        const generateBtn = document.getElementById('generate-diff');
        if (generateBtn) generateBtn.click();
    }
}; 