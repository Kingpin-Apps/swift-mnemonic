# Word Expansion

Automatically complete partial words in mnemonic phrases for improved user experience.

## Overview

Word expansion allows users to enter partial words that are automatically completed to full BIP-39 words. This feature improves user experience by reducing typing and helping users recall mnemonic words from partial inputs.

## Basic Word Expansion

```swift
import SwiftMnemonic

let mnemonic = try Mnemonic(language: .english)

// Expand single words
let expanded1 = mnemonic.expandWord(prefix: "aba")    // "abandon"
let expanded2 = mnemonic.expandWord(prefix: "acc")    // "access"
let expanded3 = mnemonic.expandWord(prefix: "acti")   // "action"

print("'aba' expands to: '\(expanded1)'")
print("'acc' expands to: '\(expanded2)'")
print("'acti' expands to: '\(expanded3)'")
```

## Expanding Full Phrases

```swift
let mnemonic = try Mnemonic(language: .english)

// Expand a phrase with partial words
let partialPhrase = "aba abo acc act add"
let expandedPhrase = mnemonic.expand(mnemonic: partialPhrase)

print("Original: \(partialPhrase)")
print("Expanded: \(expandedPhrase)")
// Output: "abandon about access action add"
```

## Handling Ambiguous Prefixes

```swift
let mnemonic = try Mnemonic(language: .english)

// These prefixes have multiple matches
let ambiguous1 = mnemonic.expandWord(prefix: "ac")   // Returns "ac" (ambiguous)
let ambiguous2 = mnemonic.expandWord(prefix: "act")  // Returns "act" (ambiguous)
let unique = mnemonic.expandWord(prefix: "acti")     // Returns "action" (unique)

print("Ambiguous 'ac': '\(ambiguous1)'")     // Multiple matches, returns original
print("Ambiguous 'act': '\(ambiguous2)'")    // Multiple matches, returns original  
print("Unique 'acti': '\(unique)'")          // Single match, returns expanded
```

## Advanced Word Expansion

```swift
class AdvancedWordExpander {
    private let mnemonic: Mnemonic
    
    init(language: Language = .english) throws {
        self.mnemonic = try Mnemonic(language: language)
    }
    
    func expandWithDetails(_ prefix: String) -> ExpansionResult {
        let matches = mnemonic.wordlist.filter { $0.hasPrefix(prefix) }
        
        switch matches.count {
        case 0:
            return .noMatch(prefix: prefix, suggestion: findSimilarWords(prefix))
        case 1:
            return .uniqueMatch(expanded: matches[0], confidence: 1.0)
        default:
            return .multipleMatches(
                prefix: prefix,
                matches: matches,
                confidence: calculateConfidence(prefix: prefix, matches: matches)
            )
        }
    }
    
    private func findSimilarWords(_ prefix: String) -> [String] {
        // Find words that are similar but don't start with the prefix
        return mnemonic.wordlist.filter { word in
            !word.hasPrefix(prefix) && levenshteinDistance(prefix, word) <= 2
        }.prefix(3).map(String.init)
    }
    
    private func calculateConfidence(prefix: String, matches: [String]) -> Double {
        // Higher confidence for longer prefixes
        let prefixScore = min(Double(prefix.count) / 6.0, 1.0)
        
        // Lower confidence for more matches
        let matchScore = 1.0 / Double(matches.count)
        
        return prefixScore * matchScore
    }
    
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1)
        let b = Array(s2)
        
        var distances = Array(0...b.count)
        
        for (i, charA) in a.enumerated() {
            var newDistances = [i + 1]
            
            for (j, charB) in b.enumerated() {
                let cost = charA == charB ? 0 : 1
                let deletion = distances[j + 1] + 1
                let insertion = newDistances[j] + 1
                let substitution = distances[j] + cost
                
                newDistances.append(min(deletion, insertion, substitution))
            }
            
            distances = newDistances
        }
        
        return distances.last ?? 0
    }
}

enum ExpansionResult {
    case uniqueMatch(expanded: String, confidence: Double)
    case multipleMatches(prefix: String, matches: [String], confidence: Double)
    case noMatch(prefix: String, suggestion: [String])
    
    var description: String {
        switch self {
        case .uniqueMatch(let expanded, let confidence):
            return "✅ '\(expanded)' (confidence: \(Int(confidence * 100))%)"
        case .multipleMatches(let prefix, let matches, let confidence):
            return "❓ '\(prefix)' matches \(matches.count) words: \(matches.prefix(3).joined(separator: ", ")) (confidence: \(Int(confidence * 100))%)"
        case .noMatch(let prefix, let suggestions):
            let suggestionText = suggestions.isEmpty ? "none" : suggestions.joined(separator: ", ")
            return "❌ No match for '\(prefix)'. Similar words: \(suggestionText)"
        }
    }
}

// Usage
let expander = try AdvancedWordExpander(language: .english)

let testPrefixes = ["aba", "ac", "acti", "xyz", "abou"]

for prefix in testPrefixes {
    let result = expander.expandWithDetails(prefix)
    print("'\(prefix)': \(result.description)")
}
```

## Real-Time Expansion UI

```swift
import SwiftUI
import Combine

class WordExpansionManager: ObservableObject {
    @Published var currentWord = ""
    @Published var expandedWord: String?
    @Published var suggestions: [String] = []
    @Published var isAmbiguous = false
    
    private let mnemonic: Mnemonic
    private var cancellables = Set<AnyCancellable>()
    
    init(language: Language = .english) throws {
        self.mnemonic = try Mnemonic(language: language)
        setupWordExpansion()
    }
    
    private func setupWordExpansion() {
        $currentWord
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] word in
                self?.expandWord(word)
            }
            .store(in: &cancellables)
    }
    
    private func expandWord(_ word: String) {
        guard !word.isEmpty else {
            expandedWord = nil
            suggestions = []
            isAmbiguous = false
            return
        }
        
        let matches = mnemonic.wordlist.filter { $0.hasPrefix(word.lowercased()) }
        
        switch matches.count {
        case 0:
            expandedWord = nil
            suggestions = findSimilarWords(word)
            isAmbiguous = false
            
        case 1:
            expandedWord = matches[0]
            suggestions = []
            isAmbiguous = false
            
        default:
            expandedWord = nil
            suggestions = Array(matches.prefix(5))
            isAmbiguous = true
        }
    }
    
    private func findSimilarWords(_ input: String) -> [String] {
        return mnemonic.wordlist.filter { word in
            word.contains(input.lowercased()) || 
            input.lowercased().contains(word.prefix(3))
        }.prefix(3).map(String.init)
    }
    
    func selectSuggestion(_ word: String) {
        currentWord = word
        expandedWord = word
        suggestions = []
        isAmbiguous = false
    }
}

struct WordExpansionView: View {
    @StateObject private var manager = try! WordExpansionManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Type word prefix...", text: $manager.currentWord)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if let expanded = manager.expandedWord {
                    Text("→ \(expanded)")
                        .foregroundColor(.green)
                        .font(.system(font: .body, design: .monospaced))
                }
            }
            
            if manager.isAmbiguous && !manager.suggestions.isEmpty {
                Text("Multiple matches:")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80))
                ], spacing: 8) {
                    ForEach(manager.suggestions, id: \.self) { suggestion in
                        Button(suggestion) {
                            manager.selectSuggestion(suggestion)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        .font(.caption)
                    }
                }
            }
            
            if !manager.isAmbiguous && manager.expandedWord == nil && !manager.currentWord.isEmpty {
                if !manager.suggestions.isEmpty {
                    Text("No exact match. Similar words:")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    HStack {
                        ForEach(manager.suggestions, id: \.self) { suggestion in
                            Button(suggestion) {
                                manager.selectSuggestion(suggestion)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                            .font(.caption)
                        }
                    }
                } else {
                    Text("No matches found")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
    }
}
```


## Performance Optimization

```swift
class OptimizedWordExpander {
    private let wordTrie: WordTrie
    
    init(language: Language = .english) throws {
        let mnemonic = try Mnemonic(language: language)
        self.wordTrie = WordTrie(words: mnemonic.wordlist)
    }
    
    func expandWord(_ prefix: String) -> [String] {
        return wordTrie.findWords(withPrefix: prefix)
    }
    
    func expandWordUnique(_ prefix: String) -> String? {
        let matches = wordTrie.findWords(withPrefix: prefix)
        return matches.count == 1 ? matches[0] : nil
    }
}

class WordTrie {
    private class TrieNode {
        var children: [Character: TrieNode] = [:]
        var isEndOfWord = false
        var word: String?
    }
    
    private let root = TrieNode()
    
    init(words: [String]) {
        for word in words {
            insert(word)
        }
    }
    
    private func insert(_ word: String) {
        var current = root
        
        for char in word {
            if current.children[char] == nil {
                current.children[char] = TrieNode()
            }
            current = current.children[char]!
        }
        
        current.isEndOfWord = true
        current.word = word
    }
    
    func findWords(withPrefix prefix: String) -> [String] {
        guard let prefixNode = findNode(prefix) else {
            return []
        }
        
        var results: [String] = []
        collectWords(from: prefixNode, into: &results)
        return results.sorted()
    }
    
    private func findNode(_ prefix: String) -> TrieNode? {
        var current = root
        
        for char in prefix {
            guard let next = current.children[char] else {
                return nil
            }
            current = next
        }
        
        return current
    }
    
    private func collectWords(from node: TrieNode, into results: inout [String]) {
        if node.isEndOfWord, let word = node.word {
            results.append(word)
        }
        
        for child in node.children.values {
            collectWords(from: child, into: &results)
        }
    }
}

// Performance comparison
func compareExpansionPerformance() throws {
    let mnemonic = try Mnemonic(language: .english)
    let optimizedExpander = try OptimizedWordExpander(language: .english)
    
    let testPrefixes = ["a", "ab", "ac", "ad", "ae"]
    
    // Standard expansion
    let startStandard = CFAbsoluteTimeGetCurrent()
    for prefix in testPrefixes {
        _ = mnemonic.expandWord(prefix: prefix)
    }
    let standardTime = CFAbsoluteTimeGetCurrent() - startStandard
    
    // Optimized expansion
    let startOptimized = CFAbsoluteTimeGetCurrent()
    for prefix in testPrefixes {
        _ = optimizedExpander.expandWord(prefix)
    }
    let optimizedTime = CFAbsoluteTimeGetCurrent() - startOptimized
    
    print("Standard expansion: \(standardTime * 1000) ms")
    print("Optimized expansion: \(optimizedTime * 1000) ms")
    
    if optimizedTime > 0 {
        print("Speed improvement: \(Int((standardTime / optimizedTime)))x")
    }
}

try compareExpansionPerformance()
```

## Best Practices

### User Experience Guidelines

1. **Provide Visual Feedback**: Show expansion results immediately
2. **Handle Ambiguity Gracefully**: Offer multiple options when prefix is ambiguous
3. **Support Partial Typing**: Work with very short prefixes (2-3 characters)
4. **Clear Error States**: Show helpful messages for no matches

### Performance Guidelines

1. **Use Tries for Large Wordlists**: More efficient than linear search
2. **Cache Expansion Results**: Avoid repeated computations
3. **Debounce User Input**: Prevent excessive expansions during typing
4. **Limit Suggestion Count**: Don't overwhelm users with too many options

## See Also

- ``Mnemonic/expandWord(prefix:)``
- ``Mnemonic/expand(mnemonic:)``
- <doc:LanguageSupport>
- <doc:ValidatingMnemonics>
