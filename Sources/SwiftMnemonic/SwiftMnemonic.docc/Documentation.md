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

// Create a mnemonic generator
let mnemonic = try Mnemonic(language: .english)

// Generate a 24-word mnemonic phrase
let phrase = try mnemonic.generate(wordCount: .twentyFour)
print("Generated mnemonic: \(phrase.joined(separator: " "))")

// Validate a mnemonic
let isValid = try mnemonic.check(mnemonic: phrase.joined(separator: " "))

// Derive seed for wallet
let seed = try Mnemonic.toSeed(mnemonic: phrase.joined(separator: " "))
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
- <doc:CustomWordlists>

### Security and Best Practices

- <doc:SecurityConsiderations>
- <doc:ErrorHandling>
- <doc:TestingAndValidation>
