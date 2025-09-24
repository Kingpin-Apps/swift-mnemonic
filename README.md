![GitHub Workflow Status](https://github.com/Kingpin-Apps/swift-mnemonic/actions/workflows/swift.yml/badge.svg)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FKingpin-Apps%2Fswift-mnemonic%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/Kingpin-Apps/swift-mnemonic)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FKingpin-Apps%2Fswift-mnemonic%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/Kingpin-Apps/swift-mnemonic)

# SwiftMnemonic - Reference implementation of BIP-0039: Mnemonic code for generating deterministic keys

SwiftMnemonic is a comprehensive Swift implementation of BIP-39 (Mnemonic code for generating deterministic keys). It provides secure mnemonic phrase generation, validation, and seed derivation with support for 12 languages as specified in the BIP-39 standard.

## Features

- ✅ **Complete BIP-39 Implementation**: Full compliance with the BIP-39 specification
- ✅ **12 Language Support**: English, Chinese (Simplified & Traditional), Czech, French, Italian, Japanese, Korean, Portuguese, Russian, Spanish, Turkish
- ✅ **Multiple Word Counts**: Support for 12, 15, 18, 21, and 24-word mnemonics
- ✅ **Entropy Conversion**: Bidirectional conversion between entropy and mnemonic phrases
- ✅ **Seed Derivation**: PBKDF2-based seed generation with optional passphrase
- ✅ **Language Detection**: Automatic detection of mnemonic language
- ✅ **Word Expansion**: Partial word matching and expansion
- ✅ **HD Wallet Support**: Extended private key (xprv) generation
- ✅ **Comprehensive Testing**: Extensive test coverage with BIP-39 test vectors

## Installation

### Swift Package Manager

#### Xcode Integration
1. In Xcode, go to `File` → `Add Package Dependencies...`
2. Enter the repository URL: `https://github.com/Kingpin-Apps/swift-mnemonic.git`
3. Select the version or branch you want to use
4. Click `Add Package`

#### Package.swift

Add SwiftMnemonic as a dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/Kingpin-Apps/swift-mnemonic.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["SwiftMnemonic"]
    )
]
```

## Usage

### Basic Usage

```swift
import SwiftMnemonic

// Create a mnemonic generator for English
let mnemonic = try Mnemonic(language: .english)

// Generate a 24-word mnemonic phrase
let phrase = try mnemonic.generate(wordCount: .twentyFour)
print("Generated mnemonic: \(phrase.joined(separator: " "))")
```

### Generating Mnemonics

```swift
import SwiftMnemonic

let mnemonic = try Mnemonic(language: .english)

// Generate different word count mnemonics
let words12 = try mnemonic.generate(wordCount: .twelve)      // 128-bit entropy
let words15 = try mnemonic.generate(wordCount: .fifteen)     // 160-bit entropy  
let words18 = try mnemonic.generate(wordCount: .eighteen)    // 192-bit entropy
let words21 = try mnemonic.generate(wordCount: .twentyOne)   // 224-bit entropy
let words24 = try mnemonic.generate(wordCount: .twentyFour)  // 256-bit entropy

// Default is 12 words if not specified
let defaultPhrase = try mnemonic.generate()
print("12-word mnemonic: \(defaultPhrase.joined(separator: " "))")
```

### Working with Different Languages

```swift
// Generate mnemonic in different languages
let englishMnemonic = try Mnemonic(language: .english)
let japaneseMnemonic = try Mnemonic(language: .japanese)
let frenchMnemonic = try Mnemonic(language: .french)

// Japanese uses special delimiter
let japanesePhrase = try japaneseMnemonic.generate()
let japaneseString = japanesePhrase.joined(separator: "\u{3000}") // Full-width space

// Other languages use regular space
let frenchPhrase = try frenchMnemonic.generate()
let frenchString = frenchPhrase.joined(separator: " ")

print("Japanese: \(japaneseString)")
print("French: \(frenchString)")
```

### Validating Mnemonics

```swift
let mnemonic = try Mnemonic(language: .english)

let testPhrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"

// Check if mnemonic is valid
let isValid = try mnemonic.check(mnemonic: testPhrase)
print("Is valid: \(isValid)") // true

// Invalid mnemonic will return false
let invalidPhrase = "invalid mnemonic phrase here"
let isInvalid = try mnemonic.check(mnemonic: invalidPhrase)
print("Is invalid: \(isInvalid)") // false
```

### Converting Between Entropy and Mnemonic

```swift
let mnemonic = try Mnemonic(language: .english)

// Create entropy from hex string
let entropyHex = "0123456789abcdef0123456789abcdef"
let entropyData = Data(fromHex: entropyHex)

// Convert entropy to mnemonic
let phrase = try mnemonic.toMnemonic(entropy: entropyData)
print("Mnemonic: \(phrase.joined(separator: " "))")

// Convert mnemonic back to entropy
let recoveredEntropy = try mnemonic.toEntropy(phrase, wordlist: mnemonic.wordlist)
let recoveredHex = Data(recoveredEntropy).hexEncodedString()
print("Recovered entropy: \(recoveredHex)")

// They should match
print("Match: \(entropyHex == recoveredHex)") // true
```

### Seed Derivation

```swift
let mnemonicPhrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"

// Generate seed without passphrase
let seed = try Mnemonic.toSeed(mnemonic: mnemonicPhrase)
print("Seed: \(seed.hexEncodedString())")

// Generate seed with passphrase
let seedWithPassphrase = try Mnemonic.toSeed(mnemonic: mnemonicPhrase, passphrase: "mypassphrase")
print("Seed with passphrase: \(seedWithPassphrase.hexEncodedString())")

// Generate HD wallet master key (xprv)
let masterKey = try Mnemonic.toHDMasterKey(seed: seed)
print("Master Key: \(masterKey)")

// Generate testnet master key
let testnetMasterKey = try Mnemonic.toHDMasterKey(seed: seed, testnet: true)
print("Testnet Master Key: \(testnetMasterKey)")
```

### Language Detection

```swift
let mnemonic = try Mnemonic(language: .english)

// Detect language from partial words
let detectedLang1 = try mnemonic.detectLanguage(code: "abandon about")
print("Detected: \(detectedLang1)") // .english

// Works with partial words too
let detectedLang2 = try mnemonic.detectLanguage(code: "aba abo")
print("Detected: \(detectedLang2)") // .english

// Can distinguish between similar languages
let detectedFrench = try mnemonic.detectLanguage(code: "abandon aboutir")
print("Detected: \(detectedFrench)") // .french
```

### Word Expansion

```swift
let mnemonic = try Mnemonic(language: .english)

// Expand partial words
let expandedWord = mnemonic.expandWord(prefix: "aba")
print("Expanded: \(expandedWord)") // "abandon"

// Expand full mnemonic with partial words
let partialMnemonic = "aba abo acc"
let expandedMnemonic = mnemonic.expand(mnemonic: partialMnemonic)
print("Expanded mnemonic: \(expandedMnemonic)") // "abandon about access"

// If word is ambiguous or not found, returns original
let ambiguous = mnemonic.expandWord(prefix: "ac")
print("Ambiguous: \(ambiguous)") // "ac" (multiple matches)
```

### Custom Wordlists

```swift
// Use a custom wordlist (must be exactly 2048 words)
let customWordlist: [String] = loadYourCustomWordlist() // Your implementation
let customMnemonic = try Mnemonic(language: .english, wordlist: customWordlist)

// Use it like any other mnemonic
let phrase = try customMnemonic.generate()
```

### Error Handling

```swift
do {
    let mnemonic = try Mnemonic(language: .english)
    let phrase = try mnemonic.generate(wordCount: .twentyFour)
    let seed = try Mnemonic.toSeed(mnemonic: phrase.joined(separator: " "))
    print("Success!")
} catch MnemonicError.invalidWordlistLength(let message) {
    print("Invalid wordlist: \(message)")
} catch MnemonicError.languageNotDetected(let message) {
    print("Language detection failed: \(message)")
} catch MnemonicError.failedChecksum(let message) {
    print("Checksum validation failed: \(message)")
} catch MnemonicError.wordNotFound(let message) {
    print("Word not found: \(message)")
} catch {
    print("Other error: \(error)")
}
```

### Complete Example: Wallet Setup

```swift
import SwiftMnemonic

func createWallet() throws {
    // 1. Create mnemonic generator
    let mnemonic = try Mnemonic(language: .english)
    
    // 2. Generate a secure 24-word mnemonic
    let phrase = try mnemonic.generate(wordCount: .twentyFour)
    let mnemonicString = phrase.joined(separator: " ")
    print("🔐 Your mnemonic phrase (keep it safe!):")
    print(mnemonicString)
    
    // 3. Validate the generated mnemonic
    let isValid = try mnemonic.check(mnemonic: mnemonicString)
    guard isValid else {
        throw MnemonicError.failedChecksum("Generated mnemonic is invalid")
    }
    
    // 4. Derive seed with optional passphrase
    let passphrase = "" // Use empty string or prompt user for passphrase
    let seed = try Mnemonic.toSeed(mnemonic: mnemonicString, passphrase: passphrase)
    print("🌱 Seed: \(seed.hexEncodedString())")
    
    // 5. Generate master private key for HD wallet
    let masterKey = try Mnemonic.toHDMasterKey(seed: seed)
    print("🔑 Master Key: \(masterKey)")
    
    // 6. Store securely (pseudocode)
    // secureStorage.store(mnemonic: mnemonicString)
    // secureStorage.store(masterKey: masterKey)
}

// Usage
do {
    try createWallet()
} catch {
    print("❌ Error creating wallet: \(error)")
}
}```

## API Reference

### Mnemonic Class

#### Initializer
```swift
public init(language: Language = .english, wordlist: [String]? = nil) throws
```
Creates a new Mnemonic instance for the specified language.

**Parameters:**
- `language`: The language to use (default: `.english`)
- `wordlist`: Optional custom wordlist (must be exactly 2048 words)

**Throws:** `MnemonicError` if wordlist is invalid

#### Instance Methods

```swift
public func generate(wordCount: WordCount = .twelve) throws -> [String]
```
Generates a new mnemonic phrase with the specified word count.

```swift
public func check(mnemonic: String) throws -> Bool
```
Validates a mnemonic phrase and returns true if valid.

```swift
public func toMnemonic(entropy: Data) throws -> [String]
```
Converts entropy data to a mnemonic phrase.

```swift
public func toEntropy(_ phrase: [String], wordlist: [String]) throws -> [UInt8]
```
Converts a mnemonic phrase back to entropy bytes.

```swift
public func detectLanguage(code: String) throws -> Language
```
Detects the language of a mnemonic phrase (supports partial words).

```swift
public func expandWord(prefix: String) -> String
```
Expands a partial word to its full form if unambiguous.

```swift
public func expand(mnemonic: String) -> String
```
Expands all partial words in a mnemonic phrase.

#### Static Methods

```swift
public static func toSeed(mnemonic: String, passphrase: String = "") throws -> Data
```
Derives a 64-byte seed from a mnemonic using PBKDF2-HMAC-SHA512.

```swift
public static func toHDMasterKey(seed: Data, testnet: Bool = false) throws -> String
```
Generates an HD wallet master private key (xprv format) from a seed.

```swift
public static func normalizeString(_ txt: String) -> String
```
Normalizes a string using Unicode compatibility decomposition.

### Enums

#### Language
```swift
public enum Language: String, CaseIterable {
    case chinese_simplified, chinese_traditional, czech, english
    case french, italian, japanese, korean, portuguese
    case russian, spanish, turkish, unsupported
}
```

#### WordCount
```swift
public enum WordCount: Int, CaseIterable {
    case twelve = 12        // 128-bit entropy
    case fifteen = 15       // 160-bit entropy
    case eighteen = 18      // 192-bit entropy
    case twentyOne = 21     // 224-bit entropy
    case twentyFour = 24    // 256-bit entropy
}
```

#### MnemonicError
```swift
public enum MnemonicError: Error {
    case failedChecksum(String?)
    case fileNotFound(String?)
    case fileLoadFail(String?)
    case invalidEntropy(String?)
    case invalidSeedLength(String?)
    case invalidStrengthValue(String?)
    case invalidWordlistLength(String?)
    case languageNotDetected(String?)
    case unsupportedLanguage(String?)
    case wordNotFound(String?)
}
```

## Security Considerations

⚠️ **Important Security Notes:**

1. **Mnemonic Storage**: Never store mnemonic phrases in plain text. Use secure storage mechanisms provided by your platform (Keychain on iOS/macOS, encrypted databases, etc.).

2. **Passphrase Protection**: Consider using a passphrase for additional security. Passphrases should be stored separately from mnemonics.

3. **Random Number Generation**: This library uses the system's secure random number generator. Ensure your deployment environment has proper entropy sources.

4. **Memory Management**: Sensitive data like seeds and private keys should be cleared from memory when no longer needed.

5. **Network Security**: Never transmit mnemonic phrases or seeds over unsecured connections.

6. **Backup Security**: When backing up mnemonics, use secure, offline methods. Consider physical storage in secure locations.

```swift
// Example: Secure cleanup
var seed = try Mnemonic.toSeed(mnemonic: mnemonicPhrase)
// ... use seed ...
// Clear sensitive data
seed.resetBytes(in: seed.startIndex..<seed.endIndex)
```

## Platform Support

- ✅ **iOS**: 14.0+
- ✅ **macOS**: 11.0+
- ✅ **watchOS**: 7.0+
- ✅ **tvOS**: 14.0+
- ✅ **Swift**: 6.0+

## Available Languages

| Language | Code | Delimiter | Status |
|----------|------|-----------|--------|
| Chinese (Simplified) | `chinese_simplified` | Space | ✅ |
| Chinese (Traditional) | `chinese_traditional` | Space | ✅ |
| Czech | `czech` | Space | ✅ |
| English | `english` | Space | ✅ |
| French | `french` | Space | ✅ |
| Italian | `italian` | Space | ✅ |
| Japanese | `japanese` | Full-width space (`\u{3000}`) | ✅ |
| Korean | `korean` | Space | ✅ |
| Portuguese | `portuguese` | Space | ✅ |
| Russian | `russian` | Space | ✅ |
| Spanish | `spanish` | Space | ✅ |
| Turkish | `turkish` | Space | ✅ |

## Dependencies

- **[UncommonCrypto](https://github.com/tesseract-one/UncommonCrypto.swift)**: Provides cryptographic functions (SHA2, HMAC, PBKDF2)
- **[SwiftBase58](https://github.com/KINGH242/swift-base58)**: Base58 encoding for extended keys

## Testing

The library includes comprehensive tests covering:

- All BIP-39 official test vectors
- All supported languages  
- Edge cases and error conditions
- UTF-8 normalization
- Entropy/mnemonic round-trip conversion
- Language detection accuracy

```bash
# Run tests
swift test

# Run with verbose output
swift test -v
```

## Contributing

Contributions are welcome! Please ensure that:

1. All tests pass
2. New functionality includes appropriate tests
3. Code follows the existing style conventions
4. Cryptographic changes are thoroughly tested against BIP-39 vectors

## License

See [LICENSE](LICENSE)

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

## Support

For questions, issues, or contributions:
- Open an issue on [GitHub](https://github.com/Kingpin-Apps/swift-mnemonic/issues)
- Check existing documentation and examples
- Review the BIP-39 specification for technical details

---

**Disclaimer**: This library is provided as-is. Users are responsible for implementing proper security practices when handling cryptographic keys and mnemonic phrases in production applications.
