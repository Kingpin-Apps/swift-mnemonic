# Language Support

Work with mnemonic phrases in 12 different languages supported by BIP-39.

## Overview

SwiftMnemonic supports all 12 languages specified in the BIP-39 standard. Each language has its own 2048-word wordlist, and some languages like Japanese have special formatting requirements. Understanding language support is crucial for creating inclusive applications and handling international users.

## Supported Languages

SwiftMnemonic supports the following languages:

| Language | Code | Delimiter | Character Set |
|----------|------|-----------|---------------|
| Chinese (Simplified) | `chinese_simplified` | Space | CJK |
| Chinese (Traditional) | `chinese_traditional` | Space | CJK |
| Czech | `czech` | Space | Latin Extended |
| English | `english` | Space | Latin Basic |
| French | `french` | Space | Latin Extended |
| Italian | `italian` | Space | Latin Extended |
| Japanese | `japanese` | Full-width space (`\u{3000}`) | CJK |
| Korean | `korean` | Space | Hangul |
| Portuguese | `portuguese` | Space | Latin Extended |
| Russian | `russian` | Space | Cyrillic |
| Spanish | `spanish` | Space | Latin Extended |
| Turkish | `turkish` | Space | Latin Extended |

## Basic Language Usage

```swift
import SwiftMnemonic

// Create mnemonics in different languages
let english = try Mnemonic(language: .english)
let japanese = try Mnemonic(language: .japanese)
let chinese = try Mnemonic(language: .chinese_simplified)
let french = try Mnemonic(language: .french)

// Generate phrases
let englishPhrase = try english.generate(wordCount: .twelve)
let japanesePhrase = try japanese.generate(wordCount: .twelve)
let chinesePhrase = try chinese.generate(wordCount: .twelve)
let frenchPhrase = try french.generate(wordCount: .twelve)

print("English: \(englishPhrase.joined(separator: " "))")
print("Japanese: \(japanesePhrase.joined(separator: "\u{3000}"))")  // Note: full-width space
print("Chinese: \(chinesePhrase.joined(separator: " "))")
print("French: \(frenchPhrase.joined(separator: " "))")
```

## Special Language Considerations

### Japanese Delimiter

Japanese is the only language that uses a full-width space (U+3000) as the word delimiter instead of a regular space:

```swift
let japaneseMnemonic = try Mnemonic(language: .japanese)
let phrase = try japaneseMnemonic.generate()

// Correct Japanese formatting
let japaneseString = phrase.joined(separator: "\u{3000}")
print("Japanese mnemonic: \(japaneseString)")

// The delimiter is handled automatically in most methods
let seed = try Mnemonic.toSeed(mnemonic: japaneseString)
```

### Unicode Normalization

All languages support proper Unicode normalization for consistent handling:

```swift
// Example with accented characters
let frenchMnemonic = try Mnemonic(language: .french)

// These different Unicode representations are equivalent
let composed = "café"  // é as single character U+00E9
let decomposed = "cafe\u{0301}"  // e + combining acute accent U+0301

let normalizedComposed = Mnemonic.normalizeString(composed)
let normalizedDecomposed = Mnemonic.normalizeString(decomposed)

print("Normalized strings match: \(normalizedComposed == normalizedDecomposed)")  // true
```

## Working with All Languages

### Listing Available Languages

```swift
let mnemonic = try Mnemonic(language: .english)
let availableLanguages = mnemonic.listLanguages()

print("Available languages:")
for language in availableLanguages {
    print("- \(language)")
}

// Or using the enum directly
print("\nAll language cases:")
for language in Language.allCases {
    if language != .unsupported {
        print("- \(language.rawValue)")
    }
}
```

### Multi-Language Wallet Support

```swift
struct MultiLanguageWallet {
    let supportedLanguages: [Language] = [
        .english, .japanese, .chinese_simplified, .chinese_traditional,
        .french, .spanish, .italian, .german, .portuguese, .korean,
        .czech, .russian, .turkish
    ]
    
    func createWallet(in language: Language, wordCount: WordCount = .twentyFour) throws -> (phrase: [String], formattedPhrase: String) {
        let mnemonic = try Mnemonic(language: language)
        let phrase = try mnemonic.generate(wordCount: wordCount)
        
        // Use appropriate delimiter for the language
        let delimiter = language == .japanese ? "\u{3000}" : " "
        let formattedPhrase = phrase.joined(separator: delimiter)
        
        return (phrase, formattedPhrase)
    }
    
    func validatePhrase(_ phrase: String, language: Language) throws -> Bool {
        let mnemonic = try Mnemonic(language: language)
        return try mnemonic.check(mnemonic: phrase)
    }
}

// Usage
let wallet = MultiLanguageWallet()

// Create wallets in different languages
let englishWallet = try wallet.createWallet(in: .english)
let japaneseWallet = try wallet.createWallet(in: .japanese)
let frenchWallet = try wallet.createWallet(in: .french)

print("English: \(englishWallet.formattedPhrase)")
print("Japanese: \(japaneseWallet.formattedPhrase)")
print("French: \(frenchWallet.formattedPhrase)")
```

## Language-Specific Examples

### English
```swift
let english = try Mnemonic(language: .english)
let phrase = try english.generate(wordCount: .twelve)
// Example: "abandon ability able about above absent absorb abstract absurd abuse access accident"
```

### Japanese (日本語)
```swift
let japanese = try Mnemonic(language: .japanese)
let phrase = try japanese.generate(wordCount: .twelve)
let japaneseString = phrase.joined(separator: "\u{3000}")
// Example: "あいこくしん　あいさつ　あいだ　あおぞら　あかちゃん　あきる　あけがた　あける　あこがれる　あさい　あさひ　あしあと"
```

### Chinese Simplified (简体中文)
```swift
let chinese = try Mnemonic(language: .chinese_simplified)
let phrase = try chinese.generate(wordCount: .twelve)
// Example: "的 的 的 的 的 的 的 的 的 的 的 在"
```

### French (Français)
```swift
let french = try Mnemonic(language: .french)
let phrase = try french.generate(wordCount: .twelve)
// Example: "abaisser abaisser abaisser abaisser abaisser abaisser abaisser abaisser abaisser abaisser abaisser abeille"
```

### Spanish (Español)
```swift
let spanish = try Mnemonic(language: .spanish)
let phrase = try spanish.generate(wordCount: .twelve)
// Example: "ábaco abdomen abeja abogado abono aborto abrazo abrir absurdo abuelo abundante acabar"
```

## Language Detection and Auto-Switching

```swift
class LanguageAwareMnemonic {
    func processPhrase(_ phrase: String) throws -> (isValid: Bool, language: Language, seed: Data?) {
        // First try to detect the language
        let tempMnemonic = try Mnemonic(language: .english)
        
        do {
            let detectedLanguage = try tempMnemonic.detectLanguage(code: phrase)
            let mnemonic = try Mnemonic(language: detectedLanguage)
            
            let isValid = try mnemonic.check(mnemonic: phrase)
            let seed = isValid ? try Mnemonic.toSeed(mnemonic: phrase) : nil
            
            return (isValid, detectedLanguage, seed)
            
        } catch MnemonicError.languageNotDetected {
            // Try each language manually
            return try bruteForceLanguageDetection(phrase)
        }
    }
    
    private func forceLanguageDetection(_ phrase: String) throws -> (Bool, Language, Data?) {
        let languages: [Language] = [
            .english, .japanese, .chinese_simplified, .chinese_traditional,
            .french, .spanish, .italian, .portuguese, .korean,
            .czech, .russian, .turkish
        ]
        
        for language in languages {
            do {
                let mnemonic = try Mnemonic(language: language)
                if try mnemonic.check(mnemonic: phrase) {
                    let seed = try Mnemonic.toSeed(mnemonic: phrase)
                    return (true, language, seed)
                }
            } catch {
                continue
            }
        }
        
        throw MnemonicError.languageNotDetected("No valid language found for phrase")
    }
}

// Usage
let processor = LanguageAwareMnemonic()

let testPhrases = [
    "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
    "あいこくしん あいこくしん あいこくしん あいこくしん あいこくしん あいこくしん あいこくしん あいこくしん あいこくしん あいこくしん あいこくしん あかちゃん",
    "abaisser abaisser abaisser abaisser abaisser abaisser abaisser abaisser abaisser abaisser abaisser abeille"
]

for phrase in testPhrases {
    do {
        let (isValid, language, seed) = try processor.processPhrase(phrase)
        print("Language: \(language.rawValue), Valid: \(isValid)")
        if let seed = seed {
            print("Seed: \(seed.hexEncodedString().prefix(32))...")
        }
    } catch {
        print("Failed to process phrase: \(error)")
    }
}
```

## Wordlist Information

Each language has exactly 2048 words:

```swift
func analyzeWordlists() throws {
    let languages: [Language] = [
        .english, .japanese, .chinese_simplified, .chinese_traditional,
        .french, .spanish, .italian, .portuguese, .korean,
        .czech, .russian, .turkish
    ]
    
    for language in languages {
        do {
            let mnemonic = try Mnemonic(language: language)
            let wordCount = mnemonic.wordlist.count
            let firstWord = mnemonic.wordlist.first ?? ""
            let lastWord = mnemonic.wordlist.last ?? ""
            
            print("\(language.rawValue):")
            print("  - Word count: \(wordCount)")
            print("  - First word: \(firstWord)")
            print("  - Last word: \(lastWord)")
            
            // Check for duplicates
            let uniqueWords = Set(mnemonic.wordlist)
            if uniqueWords.count != wordCount {
                print("  - ⚠️ Warning: Duplicate words found!")
            }
            
        } catch {
            print("\(language.rawValue): Error loading wordlist - \(error)")
        }
    }
}

try analyzeWordlists()
```

## Best Practices

### User Experience

1. **Automatic Detection**: Use language detection for better UX
2. **Fallback Options**: Provide manual language selection
3. **Visual Cues**: Show detected language to users
4. **Proper Fonts**: Ensure proper font support for all character sets

### Development

1. **Consistent Delimiters**: Always use the correct delimiter for each language
2. **Unicode Normalization**: Always normalize user input
3. **Error Handling**: Provide meaningful error messages in the user's language
4. **Testing**: Test with real phrases in each supported language


## See Also

- ``Language``
- ``Mnemonic/detectLanguage(code:)``
- <doc:LanguageDetection>
- <doc:GeneratingMnemonics>
