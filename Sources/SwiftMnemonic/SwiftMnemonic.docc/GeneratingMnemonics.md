# Generating Mnemonics

Create secure mnemonic phrases with different word counts and languages.

## Overview

SwiftMnemonic allows you to generate cryptographically secure mnemonic phrases following the BIP-39 standard. You can choose from different word counts depending on your security requirements and generate mnemonics in any of the 12 supported languages.

## Choosing Word Count

The word count determines the entropy strength of your mnemonic:

| Word Count | Entropy Bits | Security Level |
|------------|--------------|----------------|
| 12 words   | 128 bits     | High          |
| 15 words   | 160 bits     | Very High     |
| 18 words   | 192 bits     | Extremely High |
| 21 words   | 224 bits     | Maximum       |
| 24 words   | 256 bits     | Maximum       |

## Basic Generation

```swift
import SwiftMnemonic

// Create a mnemonic generator for English
let mnemonic = try Mnemonic(language: .english)

// Generate a 12-word mnemonic (default)
let phrase = try mnemonic.generate()
print("12-word mnemonic: \(phrase.joined(separator: " "))")

// Generate a 24-word mnemonic for maximum security
let securePhrase = try mnemonic.generate(wordCount: .twentyFour)
print("24-word mnemonic: \(securePhrase.joined(separator: " "))")
```

## Multi-Language Generation

```swift
// Generate mnemonic in different languages
let englishMnemonic = try Mnemonic(language: .english)
let japaneseMnemonic = try Mnemonic(language: .japanese)
let frenchMnemonic = try Mnemonic(language: .french)

let englishPhrase = try englishMnemonic.generate(wordCount: .twelve)
let japanesePhrase = try japaneseMnemonic.generate(wordCount: .twelve)
let frenchPhrase = try frenchMnemonic.generate(wordCount: .twelve)

// Note: Japanese uses full-width space as delimiter
let japaneseString = japanesePhrase.joined(separator: "\u{3000}")
let englishString = englishPhrase.joined(separator: " ")
let frenchString = frenchPhrase.joined(separator: " ")

print("English: \(englishString)")
print("Japanese: \(japaneseString)")
print("French: \(frenchString)")
```

## All Word Count Options

```swift
let mnemonic = try Mnemonic(language: .english)

// Generate all supported word counts
let words12 = try mnemonic.generate(wordCount: .twelve)      // 128-bit entropy
let words15 = try mnemonic.generate(wordCount: .fifteen)     // 160-bit entropy
let words18 = try mnemonic.generate(wordCount: .eighteen)    // 192-bit entropy
let words21 = try mnemonic.generate(wordCount: .twentyOne)   // 224-bit entropy
let words24 = try mnemonic.generate(wordCount: .twentyFour)  // 256-bit entropy

print("Generated mnemonics:")
print("12 words: \(words12.count) words")
print("15 words: \(words15.count) words") 
print("18 words: \(words18.count) words")
print("21 words: \(words21.count) words")
print("24 words: \(words24.count) words")
```

## Error Handling

```swift
do {
    let mnemonic = try Mnemonic(language: .english)
    let phrase = try mnemonic.generate(wordCount: .twentyFour)
    
    // Use the generated phrase
    print("Successfully generated: \(phrase.joined(separator: " "))")
    
} catch MnemonicError.invalidWordlistLength(let message) {
    print("Wordlist error: \(message)")
} catch MnemonicError.unsupportedLanguage(let message) {
    print("Language error: \(message)")
} catch {
    print("Unexpected error: \(error)")
}
```

## Best Practices

### Security Recommendations

1. **Use 24 words for maximum security**: For critical applications, use 24-word mnemonics
2. **Secure random generation**: SwiftMnemonic uses cryptographically secure random number generation
3. **Immediate validation**: Always validate generated mnemonics before use

### Language Selection

1. **Consider user locale**: Choose a language familiar to your users
2. **Japanese special handling**: Remember that Japanese uses full-width spaces
3. **Consistent language**: Use the same language throughout your application

### Example: Secure Wallet Generation

```swift
func generateSecureWallet() throws -> (mnemonic: [String], seed: Data) {
    // Use maximum security 24-word mnemonic
    let mnemonic = try Mnemonic(language: .english)
    let phrase = try mnemonic.generate(wordCount: .twentyFour)
    
    // Validate the generated mnemonic
    let mnemonicString = phrase.joined(separator: " ")
    guard try mnemonic.check(mnemonic: mnemonicString) else {
        throw MnemonicError.failedChecksum("Generated mnemonic failed validation")
    }
    
    // Derive seed for wallet
    let seed = try Mnemonic.toSeed(mnemonic: mnemonicString)
    
    return (phrase, seed)
}

// Usage
do {
    let wallet = try generateSecureWallet()
    print("🔐 Secure wallet generated with \(wallet.mnemonic.count) words")
    // Store securely...
} catch {
    print("❌ Failed to generate wallet: \(error)")
}
```

## See Also

- ``Mnemonic/generate(wordCount:)``
- ``WordCount``
- ``Language``
- <doc:ValidatingMnemonics>
- <doc:SeedDerivation>