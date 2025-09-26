![GitHub Workflow Status](https://github.com/Kingpin-Apps/swift-mnemonic/actions/workflows/swift.yml/badge.svg)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FKingpin-Apps%2Fswift-mnemonic%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/Kingpin-Apps/swift-mnemonic)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FKingpin-Apps%2Fswift-mnemonic%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/Kingpin-Apps/swift-mnemonic)
![Coverage](https://img.shields.io/badge/coverage-99.35%25-brightgreen)

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

// Create a mnemonic with a randomly generated 24-word phrase
let mnemonic = try Mnemonic(language: .english, wordCount: .twentyFour)
print("Generated mnemonic: \(mnemonic.phrase.joined(separator: " "))")

// Or create from existing entropy
let entropy = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f])
let mnemonicFromEntropy = try Mnemonic(language: .english, entropy: entropy)

// Or restore from an existing mnemonic phrase
let words = ["abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "about"]
let restoredMnemonic = try Mnemonic(from: words)
print("Restored language: \(restoredMnemonic.language)")
```

### Generating Mnemonics

```swift
import SwiftMnemonic

// Generate different word count mnemonics
let words12 = try Mnemonic(language: .english, wordCount: .twelve)      // 128-bit entropy
let words15 = try Mnemonic(language: .english, wordCount: .fifteen)     // 160-bit entropy  
let words18 = try Mnemonic(language: .english, wordCount: .eighteen)    // 192-bit entropy
let words21 = try Mnemonic(language: .english, wordCount: .twentyOne)   // 224-bit entropy
let words24 = try Mnemonic(language: .english, wordCount: .twentyFour)  // 256-bit entropy

// Access the generated phrase
print("12-word mnemonic: \(words12.phrase.joined(separator: " "))")
print("24-word mnemonic: \(words24.phrase.joined(separator: " "))")

// You can also generate on-demand (legacy method)
let generator = try Mnemonic(language: .english)
let generatedPhrase = try generator.generate(wordCount: .twelve)
print("Generated: \(generatedPhrase.joined(separator: " "))")
```

### Working with Different Languages

```swift
// Generate mnemonic in different languages
let englishMnemonic = try Mnemonic(language: .english, wordCount: .twelve)
let japaneseMnemonic = try Mnemonic(language: .japanese, wordCount: .twelve)
let frenchMnemonic = try Mnemonic(language: .french, wordCount: .twelve)

// Access phrases with appropriate delimiters automatically handled
print("Japanese: \(japaneseMnemonic.phrase.joined(separator: japaneseMnemonic.delimiter))")
print("French: \(frenchMnemonic.phrase.joined(separator: frenchMnemonic.delimiter))")

// Or use the convenience method to get properly formatted strings
let japaneseString = try japaneseMnemonic.toMnemonicString(entropy: japaneseMnemonic.entropy)
let frenchString = try frenchMnemonic.toMnemonicString(entropy: frenchMnemonic.entropy)

print("Japanese formatted: \(japaneseString)")
print("French formatted: \(frenchString)")
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
// Create entropy from hex string (16 bytes = 128-bit entropy for 12 words)
let entropyHex = "0123456789abcdef0123456789abcdef"
let entropyData = Data(entropyHex.hexStringToData())

// Create mnemonic from specific entropy
let mnemonic = try Mnemonic(language: .english, entropy: entropyData)
print("Mnemonic from entropy: \(mnemonic.phrase.joined(separator: " "))")

// Access the original entropy
print("Original entropy hex: \(mnemonic.entropy.hexEncodedString())")

// Convert mnemonic phrase back to entropy (static method)
let phrase = ["abandon", "abandon", "abandon", "abandon", "abandon", "abandon", 
              "abandon", "abandon", "abandon", "abandon", "abandon", "about"]
let recoveredEntropy = try Mnemonic.toEntropy(phrase, wordlist: try Language.english.words())
print("Recovered entropy: \(recoveredEntropy.hexEncodedString())")

// Generate mnemonic from entropy (static method)
let generatedPhrase = try Mnemonic.toMnemonic(entropy: entropyData, wordlist: try Language.english.words())
print("Generated phrase: \(generatedPhrase.joined(separator: " "))")
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
// Detect language from a mnemonic phrase (static method)
let detectedLang1 = try Mnemonic.detectLanguage(phrase: "abandon about")
print("Detected: \(detectedLang1)") // .english

// Works with partial words too
let detectedLang2 = try Mnemonic.detectLanguage(phrase: "aba abo")
print("Detected: \(detectedLang2)") // .english

// Can distinguish between similar languages
let detectedFrench = try Mnemonic.detectLanguage(phrase: "abandon aboutir")
print("Detected: \(detectedFrench)") // .french

// Use detected language to create mnemonic from existing phrase
let existingPhrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
let detectedLanguage = try Mnemonic.detectLanguage(phrase: existingPhrase)
let mnemonicFromPhrase = try Mnemonic(from: existingPhrase.split(separator: " ").map(String.init))
print("Detected and restored: \(mnemonicFromPhrase.language)")
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
    // 1. Generate a secure 24-word mnemonic
    let mnemonic = try Mnemonic(language: .english, wordCount: .twentyFour)
    let mnemonicString = mnemonic.phrase.joined(separator: " ")
    print("🔐 Your mnemonic phrase (keep it safe!):")
    print(mnemonicString)
    
    // 2. Validate the generated mnemonic (should always be valid for generated mnemonics)
    let isValid = try mnemonic.check(mnemonic: mnemonicString)
    guard isValid else {
        throw MnemonicError.failedChecksum("Generated mnemonic is invalid")
    }
    
    // 3. Derive seed with optional passphrase
    let passphrase = "" // Use empty string or prompt user for passphrase
    let seed = try Mnemonic.toSeed(mnemonic: mnemonicString, passphrase: passphrase)
    print("🌱 Seed: \(seed.hexEncodedString())")
    
    // 4. Generate master private key for HD wallet
    let masterKey = try Mnemonic.toHDMasterKey(seed: seed)
    print("🔑 Master Key: \(masterKey)")
    
    // 5. Alternative: restore from existing mnemonic
    func restoreWallet(from words: [String]) throws {
        let restoredMnemonic = try Mnemonic(from: words)
        print("Restored mnemonic language: \(restoredMnemonic.language)")
        
        let restoredSeed = try Mnemonic.toSeed(mnemonic: words.joined(separator: " "), passphrase: passphrase)
        let restoredMasterKey = try Mnemonic.toHDMasterKey(seed: restoredSeed)
        print("🔑 Restored Master Key: \(restoredMasterKey)")
    }
    
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

The library includes comprehensive tests with **99.35% code coverage**, covering:

- All BIP-39 official test vectors
- All supported languages and word count combinations
- Edge cases and error conditions
- UTF-8 normalization across different encodings
- Entropy/mnemonic bidirectional conversion
- Language detection accuracy
- Error handling for all failure modes
- Custom wordlist validation
- Comprehensive enum testing (WordCount, Language, MnemonicError)

### Running Tests

```bash
# Run tests
swift test

# Run with verbose output
swift test -v

# Run with coverage
swift test --enable-code-coverage
```

### Coverage Reports

The project includes Makefile targets for generating coverage reports:

```bash
# Generate coverage report and check threshold (90%)
make coverage-check

# Generate detailed coverage report
make coverage-report

# Generate HTML coverage report (requires lcov: brew install lcov)
make coverage-html
```

**Note**: Test files are automatically excluded from coverage calculations to ensure metrics reflect only source code coverage.

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
