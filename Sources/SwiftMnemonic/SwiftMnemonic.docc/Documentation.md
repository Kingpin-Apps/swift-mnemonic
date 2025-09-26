# ``SwiftMnemonic``

A comprehensive Swift implementation of BIP-39 for generating deterministic cryptographic keys from mnemonic phrases.

## Overview

SwiftMnemonic provides a complete implementation of BIP-39 (Mnemonic code for generating deterministic keys) with support for 12 languages. It enables secure generation, validation, and conversion of mnemonic phrases for cryptocurrency wallets and other cryptographic applications.

### Key Features

- **Complete BIP-39 Compliance**: Full implementation following the official BIP-39 specification
- **Multi-language Support**: 12 languages including English, Japanese, Chinese, and more
- **Flexible Word Counts**: Support for 12, 15, 18, 21, and 24-word mnemonics
- **Entropy Conversion**: Bidirectional conversion between entropy and mnemonic phrases
- **Seed Derivation**: PBKDF2-based seed generation with optional passphrase support
- **Language Detection**: Automatic detection of mnemonic language
- **Word Expansion**: Smart completion of partial words
- **HD Wallet Support**: Extended private key (xprv) generation

### Basic Usage

```swift
import SwiftMnemonic

// Create a mnemonic with random 24-word phrase
let mnemonic = try Mnemonic(language: .english, wordCount: .twentyFour)
print("Generated mnemonic: \(mnemonic.phrase.joined(separator: " "))")

// Create from existing entropy
let entropy = Data(repeating: 0x42, count: 16) // 128-bit entropy for 12 words
let entropyMnemonic = try Mnemonic(language: .english, entropy: entropy)

// Restore from existing mnemonic phrase
let words = ["abandon", "abandon", "abandon", "abandon", "abandon", "abandon",
             "abandon", "abandon", "abandon", "abandon", "abandon", "about"]
let restoredMnemonic = try Mnemonic(from: words)

// Validate a mnemonic
let isValid = try mnemonic.check(mnemonic: mnemonic.phrase.joined(separator: " "))

// Derive seed for wallet
let seed = try Mnemonic.toSeed(mnemonic: mnemonic.phrase.joined(separator: " "))
```

## Topics

### Essential Types

- ``Mnemonic``
- ``Language``
- ``WordCount``
- ``MnemonicError``

### Core Functionality

- <doc:GeneratingMnemonics>
- <doc:ValidatingMnemonics>
- <doc:SeedDerivation>
- <doc:LanguageSupport>

### Advanced Features

- <doc:EntropyConversion>
- <doc:LanguageDetection>
- <doc:WordExpansion>

### Security and Best Practices

- <doc:SecurityConsiderations>
- <doc:ErrorHandling>
