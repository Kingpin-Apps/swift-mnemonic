# Entropy Conversion

Convert between raw entropy data and mnemonic phrases for advanced cryptographic applications.

## Overview

Entropy conversion is the bidirectional process of transforming random bytes (entropy) into mnemonic phrases and vice versa. This functionality is essential for advanced applications that need to work with specific entropy sources or integrate with existing cryptographic systems.

## Understanding Entropy

Entropy represents the randomness used to generate mnemonic phrases. The entropy length determines both the security level and the resulting word count:

| Entropy Bits | Entropy Bytes | Word Count | Security Level |
|--------------|---------------|------------|----------------|
| 128 bits     | 16 bytes      | 12 words   | High          |
| 160 bits     | 20 bytes      | 15 words   | Very High     |
| 192 bits     | 24 bytes      | 18 words   | Extremely High |
| 224 bits     | 28 bytes      | 21 words   | Maximum       |
| 256 bits     | 32 bytes      | 24 words   | Maximum       |

## Converting Entropy to Mnemonic

```swift
import SwiftMnemonic

// Create entropy from hex string
let entropyHex = "0123456789abcdef0123456789abcdef"
let entropyData = Data(fromHex: entropyHex)

let mnemonic = try Mnemonic(language: .english)

// Convert entropy to mnemonic phrase
let phrase = try mnemonic.toMnemonic(entropy: entropyData)
print("Mnemonic: \(phrase.joined(separator: " "))")

// Convert to string format
let mnemonicString = try mnemonic.toMnemonicString(entropy: entropyData)
print("Mnemonic String: \(mnemonicString)")
```

## Converting Mnemonic to Entropy

```swift
let mnemonic = try Mnemonic(language: .english)
let phrase = ["abandon", "abandon", "abandon", "abandon", "abandon", "abandon", 
              "abandon", "abandon", "abandon", "abandon", "abandon", "about"]

// Convert mnemonic back to entropy
let recoveredEntropy = try mnemonic.toEntropy(phrase, wordlist: mnemonic.wordlist)
let entropyData = Data(recoveredEntropy)

print("Recovered entropy: \(entropyData.hexEncodedString())")

// Verify round-trip conversion
let originalEntropy = Data(fromHex: "00000000000000000000000000000000")
let roundTripPhrase = try mnemonic.toMnemonic(entropy: originalEntropy)
let roundTripEntropy = try mnemonic.toEntropy(roundTripPhrase, wordlist: mnemonic.wordlist)

print("Round-trip successful: \(originalEntropy == Data(roundTripEntropy))")
```

## Working with Custom Entropy

### Using Specific Entropy Sources

```swift
import CryptoKit

func generateEntropyFromSecureSource() -> Data {
    // Use CryptoKit for secure random generation
    var entropy = Data(count: 32) // 256 bits
    entropy = Data(CryptoKit.SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) })
    return entropy
}

func generateEntropyFromCustomSource(seed: String) throws -> Data {
    // Derive entropy from a custom seed using HKDF
    let inputKey = SymmetricKey(data: seed.data(using: .utf8)!)
    
    let derivedKey = try CryptoKit.HKDF<CryptoKit.SHA256>.deriveKey(
        inputKeyMaterial: inputKey,
        salt: Data("entropy_derivation".utf8),
        info: Data("mnemonic_entropy".utf8),
        outputByteCount: 32
    )
    
    return derivedKey.withUnsafeBytes { Data($0) }
}

// Usage
let customEntropy = try generateEntropyFromCustomSource(seed: "my_deterministic_seed")
let mnemonic = try Mnemonic(language: .english)
let phrase = try mnemonic.toMnemonic(entropy: customEntropy)

print("Custom entropy mnemonic: \(phrase.joined(separator: " "))")
```

### Entropy Analysis

```swift
struct EntropyAnalyzer {
    static func analyzeEntropy(_ entropy: Data) -> EntropyAnalysis {
        let bitCount = entropy.count * 8
        let wordCount = determineWordCount(entropyBits: bitCount)
        let checksumBits = bitCount / 32
        
        // Simple randomness test (not cryptographically rigorous)
        let bytes = Array(entropy)
        let uniqueBytes = Set(bytes).count
        let randomnessScore = Double(uniqueBytes) / 256.0
        
        return EntropyAnalysis(
            byteCount: entropy.count,
            bitCount: bitCount,
            wordCount: wordCount,
            checksumBits: checksumBits,
            randomnessScore: randomnessScore,
            isValidLength: [16, 20, 24, 28, 32].contains(entropy.count)
        )
    }
    
    private static func determineWordCount(entropyBits: Int) -> Int {
        switch entropyBits {
        case 128: return 12
        case 160: return 15
        case 192: return 18
        case 224: return 21
        case 256: return 24
        default: return 0
        }
    }
}

struct EntropyAnalysis {
    let byteCount: Int
    let bitCount: Int
    let wordCount: Int
    let checksumBits: Int
    let randomnessScore: Double
    let isValidLength: Bool
    
    var description: String {
        """
        Entropy Analysis:
        - Bytes: \(byteCount)
        - Bits: \(bitCount)
        - Words: \(wordCount)
        - Checksum bits: \(checksumBits)
        - Randomness score: \(String(format: "%.2f", randomnessScore))
        - Valid length: \(isValidLength)
        """
    }
}

// Usage
let entropy = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
let analysis = EntropyAnalyzer.analyzeEntropy(entropy)
print(analysis.description)
```

## Checksum Validation

Understanding how checksums work in BIP-39:

```swift
func demonstrateChecksumMechanism() throws {
    let mnemonic = try Mnemonic(language: .english)
    
    // Example with 128-bit entropy (16 bytes -> 12 words)
    let entropy = Data(fromHex: "00000000000000000000000000000000")
    
    // Calculate checksum using the library's method
    let (checksum, checksumBits) = try Mnemonic.calculateChecksumBits(entropy)
    
    print("Entropy: \(entropy.hexEncodedString())")
    print("Checksum: \(String(checksum, radix: 2).padded(to: 8))")
    print("Checksum bits used: \(checksumBits)")
    
    // Generate mnemonic and verify
    let phrase = try mnemonic.toMnemonic(entropy: entropy)
    let isValid = try mnemonic.check(mnemonic: phrase.joined(separator: " "))
    
    print("Generated phrase: \(phrase.joined(separator: " "))")
    print("Checksum valid: \(isValid)")
    
    // Demonstrate checksum failure
    var modifiedPhrase = phrase
    modifiedPhrase[11] = "about" // Change last word
    let modifiedValid = try mnemonic.check(mnemonic: modifiedPhrase.joined(separator: " "))
    print("Modified phrase valid: \(modifiedValid)") // Should be false
}

extension String {
    func padded(to length: Int, with character: Character = "0") -> String {
        return String(repeating: String(character), count: max(0, length - count)) + self
    }
}

try demonstrateChecksumMechanism()
```

## Advanced Entropy Operations

### Combining Entropy Sources

```swift
func combineEntropySources(sources: [Data]) throws -> Data {
    guard !sources.isEmpty else {
        throw EntropyError.noSources
    }
    
    guard sources.allSatisfy({ $0.count == 32 }) else {
        throw EntropyError.inconsistentLengths
    }
    
    // XOR all entropy sources together
    var combined = sources[0]
    
    for i in 1..<sources.count {
        let source = sources[i]
        for j in 0..<combined.count {
            combined[j] ^= source[j]
        }
    }
    
    // Hash the result to ensure uniform distribution
    let hashedEntropy = CryptoKit.SHA256.hash(data: combined)
    return Data(hashedEntropy)
}

enum EntropyError: Error {
    case noSources
    case inconsistentLengths
    case invalidLength
}

// Usage - combining multiple entropy sources
let source1 = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
let source2 = Data(CryptoKit.SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) })
let source3 = try generateEntropyFromCustomSource(seed: "additional_source")

let combinedEntropy = try combineEntropySources(sources: [source1, source2, source3])
let mnemonic = try Mnemonic(language: .english)
let secureMnemonic = try mnemonic.toMnemonic(entropy: combinedEntropy)

print("Secure combined mnemonic: \(secureMnemonic.joined(separator: " "))")
```

### Entropy Stretching

```swift
func stretchEntropy(_ entropy: Data, to targetLength: Int) throws -> Data {
    guard [16, 20, 24, 28, 32].contains(targetLength) else {
        throw EntropyError.invalidLength
    }
    
    if entropy.count == targetLength {
        return entropy
    }
    
    // Use HKDF to stretch or compress entropy
    let inputKey = SymmetricKey(data: entropy)
    
    let stretchedKey = try CryptoKit.HKDF<CryptoKit.SHA256>.deriveKey(
        inputKeyMaterial: inputKey,
        salt: Data("entropy_stretch".utf8),
        info: Data("target_\(targetLength)".utf8),
        outputByteCount: targetLength
    )
    
    return stretchedKey.withUnsafeBytes { Data($0) }
}

// Example: Stretch 16-byte entropy to 32 bytes
let shortEntropy = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
let longEntropy = try stretchEntropy(shortEntropy, to: 32)

let shortMnemonic = try Mnemonic(language: .english).toMnemonic(entropy: shortEntropy)
let longMnemonic = try Mnemonic(language: .english).toMnemonic(entropy: longEntropy)

print("12-word mnemonic: \(shortMnemonic.joined(separator: " "))")
print("24-word mnemonic: \(longMnemonic.joined(separator: " "))")
```

## Entropy Import/Export

### From Various Formats

```swift
extension Data {
    // Initialize from binary string
    init(binaryString: String) {
        let cleanBinary = binaryString.replacingOccurrences(of: " ", with: "")
        var data = Data()
        
        for i in stride(from: 0, to: cleanBinary.count, by: 8) {
            let endIndex = min(i + 8, cleanBinary.count)
            let byteString = String(cleanBinary[cleanBinary.index(cleanBinary.startIndex, offsetBy: i)..<cleanBinary.index(cleanBinary.startIndex, offsetBy: endIndex)])
            
            if let byte = UInt8(byteString, radix: 2) {
                data.append(byte)
            }
        }
        
        self = data
    }
    
    // Convert to binary string representation
    func binaryString() -> String {
        return map { String($0, radix: 2).padded(to: 8) }.joined(separator: " ")
    }
    
    // Initialize from base64
    init(base64: String) {
        self = Data(base64Encoded: base64) ?? Data()
    }
}

// Examples of entropy from different formats
let hexEntropy = Data(fromHex: "deadbeefcafebabe0123456789abcdef")
let binaryEntropy = Data(binaryString: "11011110 10101101 10111110 11101111")
let base64Entropy = Data(base64: "3q2+78r+uvgBI0eJq7zv")

let mnemonic = try Mnemonic(language: .english)

if hexEntropy.count == 16 {
    let hexMnemonic = try mnemonic.toMnemonic(entropy: hexEntropy)
    print("From hex: \(hexMnemonic.joined(separator: " "))")
}

print("Binary representation: \(hexEntropy.binaryString())")
print("Base64 representation: \(hexEntropy.base64EncodedString())")
```

## Validation and Testing

### Round-trip Validation

```swift
func validateRoundTripConversion(entropy: Data, language: Language = .english) throws -> Bool {
    let mnemonic = try Mnemonic(language: language)
    
    // Convert entropy to mnemonic
    let phrase = try mnemonic.toMnemonic(entropy: entropy)
    
    // Convert back to entropy
    let recoveredEntropy = try mnemonic.toEntropy(phrase, wordlist: mnemonic.wordlist)
    
    // Compare
    return entropy == Data(recoveredEntropy)
}

// Test with various entropy lengths
let testLengths = [16, 20, 24, 28, 32]

for length in testLengths {
    let testEntropy = Data((0..<length).map { _ in UInt8.random(in: 0...255) })
    
    do {
        let isValid = try validateRoundTripConversion(entropy: testEntropy)
        print("Length \(length) bytes: \(isValid ? "✅ PASS" : "❌ FAIL")")
    } catch {
        print("Length \(length) bytes: ❌ ERROR - \(error)")
    }
}
```

## See Also

- ``Mnemonic/toMnemonic(entropy:)``
- ``Mnemonic/toEntropy(_:wordlist:)``
- ``Mnemonic/calculateChecksumBits(_:)``
- <doc:GeneratingMnemonics>
- <doc:ValidatingMnemonics>
