# Seed Derivation

Convert mnemonic phrases into cryptographic seeds and master keys for wallet applications.

## Overview

Seed derivation is the process of converting a mnemonic phrase into a cryptographic seed that can be used to generate private keys for cryptocurrency wallets. SwiftMnemonic implements PBKDF2-HMAC-SHA512 as specified in BIP-39, with optional passphrase support for additional security.

## Basic Seed Generation

```swift
import SwiftMnemonic

let mnemonicPhrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"

// Generate seed without passphrase
let seed = try Mnemonic.toSeed(mnemonic: mnemonicPhrase)
print("Seed: \(seed.hexEncodedString())")

// The seed is always 64 bytes (512 bits)
print("Seed length: \(seed.count) bytes")
```

## Passphrase Protection

Adding a passphrase provides an additional layer of security. The passphrase acts as a "25th word" and is often called a "seed extension":

```swift
let mnemonicPhrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"

// Generate seed with passphrase
let seedWithPassphrase = try Mnemonic.toSeed(mnemonic: mnemonicPhrase, passphrase: "my_secure_passphrase")
print("Seed with passphrase: \(seedWithPassphrase.hexEncodedString())")

// Different passphrases produce completely different seeds
let differentPassphrase = try Mnemonic.toSeed(mnemonic: mnemonicPhrase, passphrase: "different_passphrase")
print("Different passphrase: \(differentPassphrase.hexEncodedString())")

// Empty passphrase is equivalent to no passphrase
let emptyPassphrase = try Mnemonic.toSeed(mnemonic: mnemonicPhrase, passphrase: "")
let noPassphrase = try Mnemonic.toSeed(mnemonic: mnemonicPhrase)
print("Seeds match: \(emptyPassphrase == noPassphrase)") // true
```

## HD Wallet Master Keys

For hierarchical deterministic (HD) wallets, you can generate master private keys in the extended key format:

```swift
let mnemonicPhrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
let seed = try Mnemonic.toSeed(mnemonic: mnemonicPhrase)

// Generate mainnet master private key (xprv)
let mainnetMasterKey = try Mnemonic.toHDMasterKey(seed: seed)
print("Mainnet Master Key: \(mainnetMasterKey)")

// Generate testnet master private key (tprv)
let testnetMasterKey = try Mnemonic.toHDMasterKey(seed: seed, testnet: true)
print("Testnet Master Key: \(testnetMasterKey)")

// The master key is in Base58Check format
print("Key starts with: \(String(mainnetMasterKey.prefix(4)))") // "xprv"
print("Testnet key starts with: \(String(testnetMasterKey.prefix(4)))") // "tprv"
```

## Complete Wallet Setup

Here's a complete example for setting up a wallet with proper error handling:

```swift
struct WalletSeed {
    let mnemonic: [String]
    let seed: Data
    let masterKey: String
    let language: Language
    let wordCount: Int
}

func createWalletSeed(
    wordCount: WordCount = .twentyFour,
    language: Language = .english,
    passphrase: String = "",
    testnet: Bool = false
) throws -> WalletSeed {
    
    // 1. Generate mnemonic
    let mnemonic = try Mnemonic(language: language)
    let phrase = try mnemonic.generate(wordCount: wordCount)
    
    // 2. Validate the generated mnemonic
    let mnemonicString = phrase.joined(separator: language == .japanese ? "\u{3000}" : " ")
    guard try mnemonic.check(mnemonic: mnemonicString) else {
        throw MnemonicError.failedChecksum("Generated mnemonic failed validation")
    }
    
    // 3. Derive seed
    let seed = try Mnemonic.toSeed(mnemonic: mnemonicString, passphrase: passphrase)
    
    // 4. Generate master key
    let masterKey = try Mnemonic.toHDMasterKey(seed: seed, testnet: testnet)
    
    return WalletSeed(
        mnemonic: phrase,
        seed: seed,
        masterKey: masterKey,
        language: language,
        wordCount: phrase.count
    )
}

// Usage
do {
    let wallet = try createWalletSeed(
        wordCount: .twentyFour,
        language: .english,
        passphrase: "my_additional_security",
        testnet: false
    )
    
    print("🔐 Wallet created successfully!")
    print("Language: \(wallet.language.rawValue)")
    print("Word count: \(wallet.wordCount)")
    print("Mnemonic: \(wallet.mnemonic.joined(separator: " "))")
    print("Seed: \(wallet.seed.hexEncodedString())")
    print("Master Key: \(wallet.masterKey)")
    
} catch {
    print("❌ Failed to create wallet: \(error)")
}
```

## Security Considerations

### Passphrase Benefits

1. **Additional Security Layer**: Even if someone obtains your mnemonic, they need the passphrase
2. **Plausible Deniability**: Different passphrases create different wallets from the same mnemonic
3. **Protection Against Physical Discovery**: Passphrase can be memorized separately

### Passphrase Risks

1. **Loss Risk**: Losing the passphrase means losing access to the wallet
2. **Complexity**: Adds another secret to manage
3. **No Recovery**: There's no way to recover a forgotten passphrase

```swift
// Example: Demonstrating passphrase importance
let mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"

let defaultSeed = try Mnemonic.toSeed(mnemonic: mnemonic)
let passphraseSeed = try Mnemonic.toSeed(mnemonic: mnemonic, passphrase: "secret")

// These are completely different seeds!
print("Seeds are different: \(defaultSeed != passphraseSeed)") // true

// Each produces different master keys
let defaultMaster = try Mnemonic.toHDMasterKey(seed: defaultSeed)
let passphraseMaster = try Mnemonic.toHDMasterKey(seed: passphraseSeed)
print("Master keys are different: \(defaultMaster != passphraseMaster)") // true
```

## Advanced Usage

### Seed Validation

```swift
func validateSeedDerivation(mnemonic: String, expectedSeed: String) -> Bool {
    do {
        let derivedSeed = try Mnemonic.toSeed(mnemonic: mnemonic)
        let expectedData = Data(fromHex: expectedSeed)
        
        return derivedSeed == expectedData
    } catch {
        print("Seed derivation failed: \(error)")
        return false
    }
}

// Test with known vectors
let testMnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
let expectedSeed = "c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e53495531f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04"

let isValid = validateSeedDerivation(mnemonic: testMnemonic, expectedSeed: expectedSeed)
print("Seed derivation correct: \(isValid)") // true
```

### Batch Processing

```swift
func deriveMultipleSeeds(mnemonics: [String], passphrase: String = "") -> [Data] {
    return mnemonics.compactMap { mnemonic in
        do {
            return try Mnemonic.toSeed(mnemonic: mnemonic, passphrase: passphrase)
        } catch {
            print("Failed to derive seed for mnemonic: \(error)")
            return nil
        }
    }
}

let mnemonicPhrases = [
    "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
    "legal winner thank year wave sausage worth useful legal winner thank yellow"
]

let seeds = deriveMultipleSeeds(mnemonics: mnemonicPhrases)
print("Derived \(seeds.count) seeds")
```

### Custom Derivation Parameters

For advanced use cases, you might want to understand the PBKDF2 parameters used:

```swift
// SwiftMnemonic uses these PBKDF2 parameters internally:
// - Hash: HMAC-SHA512
// - Iterations: 2048
// - Salt: "mnemonic" + passphrase
// - Output length: 64 bytes (512 bits)

func explainSeedDerivation(mnemonic: String, passphrase: String = "") {
    let normalizedMnemonic = Mnemonic.normalizeString(mnemonic)
    let normalizedPassphrase = Mnemonic.normalizeString(passphrase)
    let salt = "mnemonic" + normalizedPassphrase
    
    print("PBKDF2 Parameters:")
    print("- Hash: HMAC-SHA512")
    print("- Iterations: 2048")
    print("- Password: \(normalizedMnemonic)")
    print("- Salt: \(salt)")
    print("- Output: 64 bytes")
    
    // Actual derivation
    let seed = try! Mnemonic.toSeed(mnemonic: mnemonic, passphrase: passphrase)
    print("- Result: \(seed.hexEncodedString())")
}

explainSeedDerivation(
    mnemonic: "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
    passphrase: "TREZOR"
)
```

## Performance Considerations

PBKDF2 with 2048 iterations is computationally intensive by design:

```swift
import Foundation

func measureSeedDerivationTime(mnemonic: String, iterations: Int = 100) {
    let startTime = CFAbsoluteTimeGetCurrent()
    
    for _ in 0..<iterations {
        _ = try! Mnemonic.toSeed(mnemonic: mnemonic)
    }
    
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    let averageTime = timeElapsed / Double(iterations)
    
    print("Average seed derivation time: \(String(format: "%.3f", averageTime * 1000)) ms")
}

let testMnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
measureSeedDerivationTime(mnemonic: testMnemonic)
```

For UI applications, consider running seed derivation on a background queue:

```swift
func deriveSeedAsync(mnemonic: String, passphrase: String = "") async throws -> Data {
    return try await withCheckedThrowingContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let seed = try Mnemonic.toSeed(mnemonic: mnemonic, passphrase: passphrase)
                continuation.resume(returning: seed)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

// Usage in SwiftUI or async context
Task {
    do {
        let seed = try await deriveSeedAsync(mnemonic: userMnemonic)
        await MainActor.run {
            // Update UI with derived seed
            self.walletSeed = seed
        }
    } catch {
        print("Async seed derivation failed: \(error)")
    }
}
```

## See Also

- ``Mnemonic/toSeed(mnemonic:passphrase:)``
- ``Mnemonic/toHDMasterKey(seed:testnet:)``
- <doc:SecurityConsiderations>
- <doc:GeneratingMnemonics>