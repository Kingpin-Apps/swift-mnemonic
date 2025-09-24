# Language Detection

Automatically identify the language of mnemonic phrases for better user experience.

## Overview

Language detection enables automatic identification of mnemonic phrase languages, improving user experience by eliminating the need for manual language selection. SwiftMnemonic uses sophisticated algorithms to detect languages from complete or partial mnemonic phrases.

## Basic Language Detection

```swift
import SwiftMnemonic

let mnemonic = try Mnemonic(language: .english)

// Detect language from a complete phrase
let englishPhrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
let detectedLanguage = try mnemonic.detectLanguage(code: englishPhrase)
print("Detected language: \(detectedLanguage.rawValue)") // "english"

// Detect from partial phrases
let partialPhrase = "abandon about access"
let partialDetected = try mnemonic.detectLanguage(code: partialPhrase)
print("Detected from partial: \(partialDetected.rawValue)") // "english"
```

## Detection from Partial Words

One of the most powerful features is detecting languages from partial word inputs:

```swift
func demonstratePartialWordDetection() throws {
    let mnemonic = try Mnemonic(language: .english)
    
    // These all detect English
    try detectAndPrint(mnemonic, code: "aba")           // "abandon" prefix
    try detectAndPrint(mnemonic, code: "aba acc")       // Multiple prefixes
    try detectAndPrint(mnemonic, code: "abandon")       // Complete word
    try detectAndPrint(mnemonic, code: "abandon about") // Multiple complete words
}

func detectAndPrint(_ mnemonic: Mnemonic, code: String) throws {
    let detected = try mnemonic.detectLanguage(code: code)
    print("'\(code)' -> \(detected.rawValue)")
}

try demonstratePartialWordDetection()
```

## Multi-Language Detection

Distinguish between similar languages:

```swift
func demonstrateMultiLanguageDetection() throws {
    let detector = try Mnemonic(language: .english)
    
    // English vs French distinction
    let englishWord = try detector.detectLanguage(code: "abandon")
    let frenchWord = try detector.detectLanguage(code: "abandon aboutir")
    
    print("'abandon' -> \(englishWord.rawValue)")           // "english"
    print("'abandon aboutir' -> \(frenchWord.rawValue)")   // "french"
    
    // Japanese detection (uses different character set)
    let japanesePhrase = "あいこくしん あいさつ あいだ"
    let japanese = try detector.detectLanguage(code: japanesePhrase)
    print("Japanese phrase -> \(japanese.rawValue)")       // "japanese"
    
    // Chinese detection
    let chinesePhrase = "的 的 的"
    let chinese = try detector.detectLanguage(code: chinesePhrase)
    print("Chinese phrase -> \(chinese.rawValue)")         // "chinese_simplified"
}

try demonstrateMultiLanguageDetection()
```

## Advanced Detection Algorithms

Understanding how detection works internally:

```swift
class LanguageDetectionEngine {
    private let supportedLanguages: [Language]
    private var mnemonicCache: [Language: Mnemonic] = [:]
    
    init() {
        self.supportedLanguages = Language.allCases.filter { $0 != .unsupported }
        
        // Pre-load all mnemonics for performance
        for language in supportedLanguages {
            do {
                mnemonicCache[language] = try Mnemonic(language: language)
            } catch {
                print("Failed to load \(language.rawValue): \(error)")
            }
        }
    }
    
    func detectLanguage(from phrase: String, method: DetectionMethod = .smart) throws -> Language {
        switch method {
        case .smart:
            return try smartDetection(phrase)
        case .bruteForce:
            return try bruteForceDetection(phrase)
        case .characterSet:
            return try characterSetDetection(phrase)
        }
    }
    
    private func smartDetection(_ phrase: String) throws -> Language {
        let normalizedPhrase = Mnemonic.normalizeString(phrase)
        let words = Set(normalizedPhrase.split(separator: " ").map(String.init))
        
        // Phase 1: Character set analysis
        let candidatesByCharset = filterByCharacterSet(phrase)
        let workingCandidates = candidatesByCharset.isEmpty ? supportedLanguages : candidatesByCharset
        
        // Phase 2: Prefix matching
        var possibleLanguages = workingCandidates.compactMap { language in
            mnemonicCache[language]
        }
        
        for word in words {
            possibleLanguages = possibleLanguages.filter { mnemonic in
                mnemonic.wordlist.contains { $0.hasPrefix(word) }
            }
            
            if possibleLanguages.isEmpty {
                throw MnemonicError.languageNotDetected("No language matches all words")
            }
        }
        
        if possibleLanguages.count == 1 {
            return possibleLanguages[0].language
        }
        
        // Phase 3: Exact matching for disambiguation
        var exactMatches = Set<Mnemonic>()
        for word in words {
            let matches = possibleLanguages.filter { $0.wordlist.contains(word) }
            if matches.count == 1 {
                exactMatches.formUnion(matches)
            }
        }
        
        if exactMatches.count == 1 {
            return exactMatches.first!.language
        }
        
        throw MnemonicError.languageNotDetected("Could not disambiguate between languages")
    }
    
    private func bruteForceDetection(_ phrase: String) throws -> Language {
        for language in supportedLanguages {
            if let mnemonic = mnemonicCache[language] {
                do {
                    if try mnemonic.check(mnemonic: phrase) {
                        return language
                    }
                } catch {
                    continue
                }
            }
        }
        throw MnemonicError.languageNotDetected("No language validates the phrase")
    }
    
    private func characterSetDetection(_ phrase: String) throws -> Language {
        let candidates = filterByCharacterSet(phrase)
        
        if candidates.count == 1 {
            return candidates[0]
        } else if candidates.isEmpty {
            throw MnemonicError.languageNotDetected("No language matches character set")
        } else {
            // Multiple candidates, need further analysis
            return try smartDetection(phrase)
        }
    }
    
    private func filterByCharacterSet(_ phrase: String) -> [Language] {
        let containsCJK = phrase.range(of: "\\p{Script=Han}|\\p{Script=Hiragana}|\\p{Script=Katakana}|\\p{Script=Hangul}", options: .regularExpression) != nil
        let containsCyrillic = phrase.range(of: "\\p{Script=Cyrillic}", options: .regularExpression) != nil
        
        if containsCJK {
            if phrase.contains("あ") || phrase.contains("か") || phrase.contains("さ") {
                return [.japanese]
            } else if phrase.contains("가") || phrase.contains("나") || phrase.contains("다") {
                return [.korean]
            } else {
                return [.chinese_simplified, .chinese_traditional]
            }
        } else if containsCyrillic {
            return [.russian]
        } else {
            // Latin-based languages
            return [.english, .french, .spanish, .italian, .portuguese, .czech, .turkish]
        }
    }
}

enum DetectionMethod {
    case smart
    case bruteForce
    case characterSet
}

// Usage
let engine = LanguageDetectionEngine()

let testPhrases = [
    "abandon about access",
    "あいこくしん あいさつ",
    "的 的 的",
    "abaisser abeille",
    "абажур абзац"
]

for phrase in testPhrases {
    do {
        let detected = try engine.detectLanguage(from: phrase, method: .smart)
        print("'\(phrase)' -> \(detected.rawValue)")
    } catch {
        print("'\(phrase)' -> Detection failed: \(error)")
    }
}
```

## Real-Time Detection for UI

Implementing real-time language detection in user interfaces:

```swift
import SwiftUI
import Combine

class RealTimeLanguageDetector: ObservableObject {
    @Published var detectedLanguage: Language?
    @Published var confidence: Double = 0.0
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let detector = LanguageDetectionEngine()
    
    func detectLanguage(from input: String) {
        // Debounce input to avoid excessive processing
        let publisher = Just(input)
            .delay(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
        
        publisher
            .sink { [weak self] phrase in
                self?.performDetection(phrase)
            }
            .store(in: &cancellables)
    }
    
    private func performDetection(_ phrase: String) {
        let trimmedPhrase = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedPhrase.isEmpty else {
            detectedLanguage = nil
            confidence = 0.0
            errorMessage = nil
            return
        }
        
        do {
            let detected = try detector.detectLanguage(from: trimmedPhrase)
            let calculatedConfidence = calculateConfidence(phrase: trimmedPhrase, language: detected)
            
            DispatchQueue.main.async {
                self.detectedLanguage = detected
                self.confidence = calculatedConfidence
                self.errorMessage = nil
            }
            
        } catch {
            DispatchQueue.main.async {
                self.detectedLanguage = nil
                self.confidence = 0.0
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func calculateConfidence(phrase: String, language: Language) -> Double {
        // Simplified confidence calculation
        let words = phrase.split(separator: " ")
        
        if words.count >= 3 {
            return 0.95
        } else if words.count == 2 {
            return 0.80
        } else {
            return 0.60
        }
    }
}

struct LanguageDetectionView: View {
    @State private var input = ""
    @StateObject private var detector = RealTimeLanguageDetector()
    
    var body: some View {
        VStack {
            TextField("Enter mnemonic words...", text: $input)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: input) { newValue in
                    detector.detectLanguage(from: newValue)
                }
            
            if let language = detector.detectedLanguage {
                HStack {
                    Text("Detected: \(language.rawValue)")
                        .foregroundColor(.green)
                    
                    Text("(\(Int(detector.confidence * 100))% confidence)")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            
            if let error = detector.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
    }
}
```

## Detection Performance Optimization

Optimizing detection for large-scale applications:

```swift
class OptimizedLanguageDetector {
    private let commonWords: [Language: Set<String>]
    private let languageScores: [Language: Double]
    
    init() throws {
        var tempCommonWords: [Language: Set<String>] = [:]
        var tempLanguageScores: [Language: Double] = [:]
        
        // Pre-compute common word sets for faster lookup
        for language in Language.allCases where language != .unsupported {
            let mnemonic = try Mnemonic(language: language)
            let wordlist = mnemonic.wordlist
            
            // Take first 100 words as "common" words for quick detection
            tempCommonWords[language] = Set(wordlist.prefix(100))
            
            // Language frequency score (simplified)
            tempLanguageScores[language] = getLanguageFrequency(language)
        }
        
        self.commonWords = tempCommonWords
        self.languageScores = tempLanguageScores
    }
    
    func quickDetect(_ phrase: String) -> [(language: Language, score: Double)] {
        let words = phrase.split(separator: " ").map(String.init)
        var scores: [Language: Double] = [:]
        
        for (language, commonWordSet) in commonWords {
            var matchScore = 0.0
            let baseScore = languageScores[language] ?? 1.0
            
            for word in words {
                // Check exact match
                if commonWordSet.contains(word) {
                    matchScore += 10.0
                } else {
                    // Check prefix match
                    let prefixMatches = commonWordSet.filter { $0.hasPrefix(word) }
                    matchScore += Double(prefixMatches.count) * 2.0
                }
            }
            
            scores[language] = matchScore * baseScore
        }
        
        return scores
            .sorted { $0.value > $1.value }
            .map { (language: $0.key, score: $0.value) }
    }
    
    private func getLanguageFrequency(_ language: Language) -> Double {
        // Simplified language frequency scoring
        // In practice, this could be based on usage statistics
        switch language {
        case .english: return 2.0
        case .chinese_simplified, .chinese_traditional: return 1.8
        case .spanish, .french: return 1.5
        case .japanese, .korean: return 1.3
        default: return 1.0
        }
    }
}

// Performance comparison
func compareDetectionPerformance() throws {
    let standardDetector = try Mnemonic(language: .english)
    let optimizedDetector = try OptimizedLanguageDetector()
    
    let testPhrases = [
        "abandon about access",
        "legal winner thank",
        "あいこくしん あいさつ",
        "abaisser abeille"
    ]
    
    // Standard detection timing
    let startStandard = CFAbsoluteTimeGetCurrent()
    for phrase in testPhrases {
        _ = try? standardDetector.detectLanguage(code: phrase)
    }
    let standardTime = CFAbsoluteTimeGetCurrent() - startStandard
    
    // Optimized detection timing
    let startOptimized = CFAbsoluteTimeGetCurrent()
    for phrase in testPhrases {
        _ = optimizedDetector.quickDetect(phrase)
    }
    let optimizedTime = CFAbsoluteTimeGetCurrent() - startOptimized
    
    print("Standard detection: \(standardTime * 1000) ms")
    print("Optimized detection: \(optimizedTime * 1000) ms")
    print("Speed improvement: \(Int((standardTime / optimizedTime) * 100))%")
}

try compareDetectionPerformance()
```

## Handling Edge Cases

Dealing with ambiguous or problematic inputs:

```swift
struct RobustLanguageDetector {
    private let fallbackOrder: [Language] = [
        .english, .spanish, .french, .italian, .portuguese,
        .chinese_simplified, .japanese, .korean,
        .russian, .czech, .turkish, .chinese_traditional
    ]
    
    func detectWithFallback(_ phrase: String) -> DetectionResult {
        // Clean and normalize input
        let cleanPhrase = cleanInput(phrase)
        
        guard !cleanPhrase.isEmpty else {
            return .failure(.emptyInput)
        }
        
        // Try smart detection first
        do {
            let detector = try Mnemonic(language: .english)
            let detected = try detector.detectLanguage(code: cleanPhrase)
            return .success(detected, confidence: .high)
        } catch {
            // Fall back to heuristic detection
            return heuristicDetection(cleanPhrase)
        }
    }
    
    private func cleanInput(_ input: String) -> String {
        return input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
    }
    
    private func heuristicDetection(_ phrase: String) -> DetectionResult {
        // Character-based heuristics
        if phrase.range(of: "\\p{Script=Hiragana}|\\p{Script=Katakana}", options: .regularExpression) != nil {
            return .success(.japanese, confidence: .medium)
        }
        
        if phrase.range(of: "\\p{Script=Hangul}", options: .regularExpression) != nil {
            return .success(.korean, confidence: .medium)
        }
        
        if phrase.range(of: "\\p{Script=Han}", options: .regularExpression) != nil {
            return .success(.chinese_simplified, confidence: .low)
        }
        
        if phrase.range(of: "\\p{Script=Cyrillic}", options: .regularExpression) != nil {
            return .success(.russian, confidence: .medium)
        }
        
        // Word-based heuristics for Latin scripts
        let words = phrase.split(separator: " ")
        
        if words.contains(where: { $0.starts(with: "aba") || $0.starts(with: "acc") }) {
            return .success(.english, confidence: .low)
        }
        
        return .failure(.cannotDetect)
    }
}

enum DetectionResult {
    case success(Language, confidence: ConfidenceLevel)
    case failure(DetectionError)
}

enum ConfidenceLevel {
    case high   // 90-100%
    case medium // 70-89%
    case low    // 50-69%
    
    var percentage: Int {
        switch self {
        case .high: return 95
        case .medium: return 80
        case .low: return 60
        }
    }
}

enum DetectionError {
    case emptyInput
    case cannotDetect
    case ambiguousInput
}

// Usage
let robustDetector = RobustLanguageDetector()

let edgeCases = [
    "",  // Empty
    "xyz abc def",  // Invalid words
    "的 的 的 的",  // Ambiguous Chinese
    "aba acc act"   // English prefixes
]

for testCase in edgeCases {
    let result = robustDetector.detectWithFallback(testCase)
    
    switch result {
    case .success(let language, let confidence):
        print("'\(testCase)' -> \(language.rawValue) (\(confidence.percentage)% confidence)")
    case .failure(let error):
        print("'\(testCase)' -> Failed: \(error)")
    }
}
```

## Best Practices

### Performance Guidelines

1. **Cache Language Instances**: Avoid recreating `Mnemonic` objects
2. **Debounce Input**: For real-time detection, debounce user input
3. **Progressive Detection**: Start with character set analysis
4. **Early Returns**: Exit detection as soon as confident

### Accuracy Guidelines

1. **Minimum Word Count**: Require at least 2-3 words for reliable detection
2. **Confidence Scoring**: Provide confidence levels to users
3. **Fallback Strategies**: Have multiple detection strategies
4. **User Override**: Allow manual language selection

## See Also

- ``Mnemonic/detectLanguage(code:)``
- <doc:LanguageSupport>
- <doc:ValidatingMnemonics>
- ``Language``