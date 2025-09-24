# Validating Mnemonics

Verify the integrity and correctness of mnemonic phrases using checksum validation.

## Overview

Mnemonic validation is crucial for ensuring that user-entered phrases are valid according to the BIP-39 standard. SwiftMnemonic performs comprehensive validation including word verification, checksum validation, and proper formatting checks.

## Basic Validation

```swift
import SwiftMnemonic

let mnemonic = try Mnemonic(language: .english)

// Validate a correct mnemonic
let validPhrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
let isValid = try mnemonic.check(mnemonic: validPhrase)
print("Is valid: \(isValid)") // true

// Validate an incorrect mnemonic
let invalidPhrase = "invalid mnemonic phrase here that should fail validation"
let isInvalid = try mnemonic.check(mnemonic: invalidPhrase)
print("Is invalid: \(isInvalid)") // false
```

## Validation Process

The validation process checks several aspects:

1. **Word Count**: Must be 12, 15, 18, 21, or 24 words
2. **Word Verification**: All words must exist in the selected language's wordlist
3. **Checksum Validation**: The last few bits serve as a checksum for error detection
4. **Format Validation**: Proper spacing and normalization

```swift
func validateMnemonicDetailed(_ phrase: String, language: Language = .english) {
    do {
        let mnemonic = try Mnemonic(language: language)
        let isValid = try mnemonic.check(mnemonic: phrase)
        
        if isValid {
            print("✅ Mnemonic is valid!")
            
            // Additional checks can be performed
            let words = phrase.split(separator: " ").map(String.init)
            print("Word count: \(words.count)")
            print("Language: \(language.rawValue)")
            
        } else {
            print("❌ Mnemonic is invalid")
            analyzeValidationFailure(phrase, mnemonic: mnemonic)
        }
        
    } catch {
        print("🚫 Validation error: \(error)")
    }
}

func analyzeValidationFailure(_ phrase: String, mnemonic: Mnemonic) {
    let words = phrase.split(separator: " ").map(String.init)
    
    // Check word count
    let validCounts = [12, 15, 18, 21, 24]
    if !validCounts.contains(words.count) {
        print("Invalid word count: \(words.count). Must be 12, 15, 18, 21, or 24")
        return
    }
    
    // Check individual words
    for (index, word) in words.enumerated() {
        if !mnemonic.wordlist.contains(word) {
            print("Invalid word at position \(index + 1): '\(word)'")
        }
    }
    
    print("Checksum validation failed - possible data corruption or typo")
}
```

## Multi-Language Validation

```swift
// Validate mnemonics in different languages
let englishMnemonic = try Mnemonic(language: .english)
let japaneseMnemonic = try Mnemonic(language: .japanese)
let frenchMnemonic = try Mnemonic(language: .french)

let englishPhrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
let japanesePhrase = "あいこくしん あいこくしん あいこくしん あいこくしん あいこくしん あいこくしん あいこくしん あいこくしん あいこくしん あいこくしん あいこくしん あかちゃん"

// Validate with appropriate language
let englishValid = try englishMnemonic.check(mnemonic: englishPhrase)
let japaneseValid = try japaneseMnemonic.check(mnemonic: japanesePhrase)

print("English valid: \(englishValid)")
print("Japanese valid: \(japaneseValid)")

// Cross-language validation will fail
let crossValid = try englishMnemonic.check(mnemonic: japanesePhrase)
print("Cross-language valid: \(crossValid)") // false
```

## Handling User Input

When validating user-entered mnemonics, consider common issues:

```swift
func validateUserInput(_ userPhrase: String) -> Bool {
    do {
        // Normalize the input
        let normalizedPhrase = Mnemonic.normalizeString(userPhrase.trimmingCharacters(in: .whitespacesAndNewlines))
        
        // Try to detect language first
        let mnemonic = try Mnemonic(language: .english)
        let detectedLanguage = try mnemonic.detectLanguage(code: normalizedPhrase)
        
        // Create appropriate mnemonic for detected language
        let languageMnemonic = try Mnemonic(language: detectedLanguage)
        
        // Validate with correct language
        return try languageMnemonic.check(mnemonic: normalizedPhrase)
        
    } catch MnemonicError.languageNotDetected {
        print("Could not detect language - trying common languages...")
        return tryCommonLanguages(userPhrase)
        
    } catch {
        print("Validation error: \(error)")
        return false
    }
}

func tryCommonLanguages(_ phrase: String) -> Bool {
    let commonLanguages: [Language] = [.english, .japanese, .chinese_simplified, .french, .spanish]
    
    for language in commonLanguages {
        do {
            let mnemonic = try Mnemonic(language: language)
            if try mnemonic.check(mnemonic: phrase) {
                print("Valid in \(language.rawValue)")
                return true
            }
        } catch {
            continue
        }
    }
    
    return false
}
```

## Real-Time Validation

For user interfaces, you might want to provide real-time feedback:

```swift
class MnemonicValidator: ObservableObject {
    @Published var isValid = false
    @Published var wordCount = 0
    @Published var errorMessage = ""
    @Published var detectedLanguage: Language?
    
    private var mnemonic: Mnemonic?
    
    func validatePhrase(_ phrase: String) {
        let normalizedPhrase = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = normalizedPhrase.split(separator: " ")
        wordCount = words.count
        
        guard !normalizedPhrase.isEmpty else {
            resetValidation()
            return
        }
        
        do {
            // Try to detect language
            let tempMnemonic = try Mnemonic(language: .english)
            detectedLanguage = try tempMnemonic.detectLanguage(code: normalizedPhrase)
            
            // Validate with detected language
            mnemonic = try Mnemonic(language: detectedLanguage!)
            isValid = try mnemonic!.check(mnemonic: normalizedPhrase)
            
            if isValid {
                errorMessage = "✅ Valid mnemonic"
            } else {
                analyzeError(normalizedPhrase)
            }
            
        } catch MnemonicError.languageNotDetected {
            errorMessage = "❌ Could not detect language"
            isValid = false
            detectedLanguage = nil
            
        } catch {
            errorMessage = "❌ Validation error: \(error.localizedDescription)"
            isValid = false
            detectedLanguage = nil
        }
    }
    
    private func resetValidation() {
        isValid = false
        errorMessage = ""
        detectedLanguage = nil
    }
    
    private func analyzeError(_ phrase: String) {
        let words = phrase.split(separator: " ")
        
        let validCounts = [12, 15, 18, 21, 24]
        if !validCounts.contains(words.count) {
            errorMessage = "❌ Invalid word count (\(words.count)). Must be 12, 15, 18, 21, or 24"
            return
        }
        
        if let mnemonic = mnemonic {
            for (index, word) in words.enumerated() {
                if !mnemonic.wordlist.contains(String(word)) {
                    errorMessage = "❌ Invalid word at position \(index + 1): '\(word)'"
                    return
                }
            }
        }
        
        errorMessage = "❌ Checksum validation failed"
    }
}
```

## Best Practices

### Security Considerations

1. **Always validate before use**: Never use unvalidated mnemonics for key generation
2. **Normalize input**: Use `Mnemonic.normalizeString()` for consistent handling
3. **Language detection**: Use automatic language detection for better user experience
4. **Error feedback**: Provide clear error messages to help users correct issues

### Performance Tips

1. **Cache validators**: Reuse `Mnemonic` instances when validating multiple phrases
2. **Background validation**: Perform validation on background threads for UI responsiveness
3. **Partial validation**: For real-time UI, validate incrementally

### Example: Complete Validation Function

```swift
func completeValidation(phrase: String) -> (isValid: Bool, language: Language?, errors: [String]) {
    var errors: [String] = []
    
    // Basic checks
    let normalizedPhrase = Mnemonic.normalizeString(phrase.trimmingCharacters(in: .whitespacesAndNewlines))
    
    guard !normalizedPhrase.isEmpty else {
        errors.append("Mnemonic phrase cannot be empty")
        return (false, nil, errors)
    }
    
    let words = normalizedPhrase.split(separator: " ")
    let validCounts = [12, 15, 18, 21, 24]
    
    if !validCounts.contains(words.count) {
        errors.append("Invalid word count: \(words.count). Must be 12, 15, 18, 21, or 24")
    }
    
    do {
        // Detect language
        let tempMnemonic = try Mnemonic(language: .english)
        let detectedLanguage = try tempMnemonic.detectLanguage(code: normalizedPhrase)
        
        // Validate with detected language
        let mnemonic = try Mnemonic(language: detectedLanguage)
        let isValid = try mnemonic.check(mnemonic: normalizedPhrase)
        
        if !isValid {
            errors.append("Checksum validation failed")
        }
        
        return (isValid, detectedLanguage, errors)
        
    } catch MnemonicError.languageNotDetected {
        errors.append("Could not detect language")
        return (false, nil, errors)
        
    } catch {
        errors.append("Validation error: \(error)")
        return (false, nil, errors)
    }
}

// Usage
let (isValid, language, errors) = completeValidation(phrase: userInput)

if isValid {
    print("✅ Valid \(language?.rawValue ?? "unknown") mnemonic")
} else {
    print("❌ Validation failed:")
    errors.forEach { print("  - \($0)") }
}
```

## See Also

- ``Mnemonic/check(mnemonic:)``
- ``MnemonicError``
- <doc:LanguageDetection>
- <doc:ErrorHandling>