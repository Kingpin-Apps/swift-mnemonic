# Error Handling

Comprehensive guide to handling errors when working with mnemonic phrases and cryptographic operations.

## Overview

SwiftMnemonic provides detailed error handling through the ``MnemonicError`` enum. Understanding these errors and how to handle them properly is crucial for building robust applications that provide clear feedback to users.

## MnemonicError Types

SwiftMnemonic defines several specific error types:

```swift
public enum MnemonicError: Error, Equatable {
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

## Basic Error Handling

```swift
import SwiftMnemonic

func handleBasicErrors() {
    do {
        let mnemonic = try Mnemonic(language: .english)
        let phrase = try mnemonic.generate(wordCount: .twentyFour)
        let seed = try Mnemonic.toSeed(mnemonic: phrase.joined(separator: " "))
        
        print("✅ Success: Generated seed from mnemonic")
        
    } catch MnemonicError.invalidWordlistLength(let message) {
        print("❌ Wordlist error: \(message ?? "Unknown wordlist issue")")
        
    } catch MnemonicError.unsupportedLanguage(let message) {
        print("❌ Language error: \(message ?? "Unsupported language")")
        
    } catch MnemonicError.failedChecksum(let message) {
        print("❌ Checksum error: \(message ?? "Checksum validation failed")")
        
    } catch {
        print("❌ Unexpected error: \(error)")
    }
}

handleBasicErrors()
```

## Best Practices

### Error Handling Guidelines

1. **Always Catch Specific Errors**: Handle `MnemonicError` cases specifically
2. **Provide Context**: Include operation context in error messages
3. **Log Appropriately**: Use proper logging levels for different error types
4. **Recovery Strategies**: Implement recovery for recoverable errors
5. **User-Friendly Messages**: Translate technical errors into user-friendly language



## See Also

- ``MnemonicError``
- <doc:ValidatingMnemonics>
- <doc:SecurityConsiderations>
