# Security Considerations

Essential security practices when working with mnemonic phrases and cryptographic seeds.

## Overview

Working with mnemonic phrases requires careful attention to security practices. Since these phrases control access to cryptocurrency wallets and other sensitive cryptographic materials, implementing proper security measures is critical for protecting user funds and data.

## Critical Security Rules

### 1. Never Store Mnemonics in Plain Text

```swift
// ❌ NEVER DO THIS
let mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
UserDefaults.standard.set(mnemonic, forKey: "mnemonic") // INSECURE!

// ✅ DO THIS INSTEAD
import Security

func storeMnemonicSecurely(_ mnemonic: String) throws {
    let data = mnemonic.data(using: .utf8)!
    
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: "wallet_mnemonic",
        kSecAttrService as String: "MyApp",
        kSecValueData as String: data,
        kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    ]
    
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
        throw KeychainError.storageFailure
    }
}

func retrieveMnemonicSecurely() throws -> String {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: "wallet_mnemonic",
        kSecAttrService as String: "MyApp",
        kSecReturnData as String: true
    ]
    
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    
    guard status == errSecSuccess,
          let data = result as? Data,
          let mnemonic = String(data: data, encoding: .utf8) else {
        throw KeychainError.retrievalFailure
    }
    
    return mnemonic
}

enum KeychainError: Error {
    case storageFailure
    case retrievalFailure
}
```

### 2. Secure Memory Management

```swift
import Foundation

// Custom secure string type that clears memory when deallocated
class SecureString {
    private var data: Data
    
    init(_ string: String) {
        self.data = string.data(using: .utf8) ?? Data()
    }
    
    var string: String {
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    func clear() {
        // Overwrite memory with random data
        data.withUnsafeMutableBytes { bytes in
            guard let baseAddress = bytes.bindMemory(to: UInt8.self).baseAddress else { return }
            for i in 0..<bytes.count {
                baseAddress[i] = UInt8.random(in: 0...255)
            }
        }
        data = Data()
    }
    
    deinit {
        clear()
    }
}

// Usage example
func processSecureMnemonic() throws {
    let secureMnemonic = SecureString("abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about")
    
    // Use the mnemonic
    let seed = try Mnemonic.toSeed(mnemonic: secureMnemonic.string)
    
    // Mnemonic is automatically cleared when SecureString is deallocated
    
    // Process seed...
    
    // Clear sensitive data
    secureMnemonic.clear()
}
```

### 3. Network Security

```swift
// ❌ NEVER transmit mnemonics over the network
func badExample() {
    let mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
    
    // NEVER DO THIS - sending mnemonic over network
    var request = URLRequest(url: URL(string: "https://api.example.com/wallet")!)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpMethod = "POST"
    
    let body = ["mnemonic": mnemonic] // ❌ INSECURE!
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
}

// ✅ Instead, work with derived public data
func goodExample() throws {
    let mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
    let seed = try Mnemonic.toSeed(mnemonic: mnemonic)
    
    // Derive public key or address from seed (implementation depends on your crypto library)
    // let publicKey = derivePublicKey(from: seed)
    // let address = deriveAddress(from: publicKey)
    
    // Only transmit public data
    var request = URLRequest(url: URL(string: "https://api.example.com/wallet")!)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpMethod = "POST"
    
    let body = ["address": "your_public_address"] // ✅ SAFE
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
}
```

## Passphrase Security

### Benefits of Passphrases

```swift
func demonstratePassphraseImportance() throws {
    let mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
    
    // Without passphrase
    let seedDefault = try Mnemonic.toSeed(mnemonic: mnemonic)
    
    // With passphrase  
    let seedWithPassphrase = try Mnemonic.toSeed(mnemonic: mnemonic, passphrase: "my_secret_passphrase")
    
    // Completely different seeds!
    print("Seeds are different: \(seedDefault != seedWithPassphrase)") // true
    
    // This provides:
    // 1. Additional security layer
    // 2. Plausible deniability (different passphrases = different wallets)
    // 3. Protection against physical discovery of mnemonic
}
```

### Passphrase Best Practices

```swift
struct PassphraseValidator {
    static func validatePassphrase(_ passphrase: String) -> (isValid: Bool, issues: [String]) {
        var issues: [String] = []
        
        // Check length
        if passphrase.count < 8 {
            issues.append("Passphrase should be at least 8 characters")
        }
        
        // Check complexity
        let hasLowercase = passphrase.range(of: "[a-z]", options: .regularExpression) != nil
        let hasUppercase = passphrase.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasNumbers = passphrase.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSymbols = passphrase.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil
        
        var complexity = 0
        if hasLowercase { complexity += 1 }
        if hasUppercase { complexity += 1 }
        if hasNumbers { complexity += 1 }
        if hasSymbols { complexity += 1 }
        
        if complexity < 3 {
            issues.append("Passphrase should contain at least 3 of: lowercase, uppercase, numbers, symbols")
        }
        
        // Check against common passwords (simplified check)
        let commonPasswords = ["password", "123456", "qwerty", "admin"]
        if commonPasswords.contains(passphrase.lowercased()) {
            issues.append("Passphrase is too common")
        }
        
        return (issues.isEmpty, issues)
    }
}

// Usage
let (isValid, issues) = PassphraseValidator.validatePassphrase("MySecur3P@ssphrase!")
if !isValid {
    print("Passphrase issues:")
    issues.forEach { print("- \($0)") }
}
```

## Secure Random Number Generation

SwiftMnemonic uses secure random number generation, but here's how to verify:

```swift
import CryptoKit

func verifyRandomness() throws {
    // Generate multiple mnemonics and verify they're different
    let mnemonic = try Mnemonic(language: .english)
    
    var generatedPhrases: Set<String> = []
    
    for _ in 0..<100 {
        let phrase = try mnemonic.generate()
        let phraseString = phrase.joined(separator: " ")
        
        // Should never generate the same phrase twice
        if generatedPhrases.contains(phraseString) {
            throw SecurityError.weakRandomness
        }
        
        generatedPhrases.insert(phraseString)
    }
    
    print("✅ Random number generation appears secure")
}

enum SecurityError: Error {
    case weakRandomness
    case insecureStorage
}
```

## Environment Security

### Secure UI Practices

```swift
import SwiftUI

struct SecureMnemonicInput: View {
    @State private var mnemonic = ""
    @State private var isVisible = false
    
    var body: some View {
        VStack {
            HStack {
                if isVisible {
                    TextField("Enter mnemonic phrase", text: $mnemonic)
                        .textContentType(.none) // Disable AutoFill
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } else {
                    SecureField("Enter mnemonic phrase", text: $mnemonic)
                        .textContentType(.none)
                }
                
                Button(action: { isVisible.toggle() }) {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                }
            }
            
            Text("Your mnemonic phrase will not be stored on this device")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .onDisappear {
            // Clear sensitive data when view disappears
            clearSensitiveData()
        }
    }
    
    private func clearSensitiveData() {
        mnemonic = ""
    }
}

// Disable screenshots when sensitive data is visible
class SecurityManager {
    static func preventScreenshots() {
        #if os(iOS)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Hide sensitive content
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Show security overlay
        }
        #endif
    }
}
```

## Testing Security

### Secure Test Data

```swift
class SecureTestData {
    // Use well-known test vectors that don't represent real wallets
    static let testMnemonics = [
        "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
        "legal winner thank year wave sausage worth useful legal winner thank yellow"
    ]
    
    static func getTestMnemonic() -> String {
        return testMnemonics.randomElement()!
    }
    
    // Never use real mnemonics in tests
    static func validateTestMnemonic(_ mnemonic: String) -> Bool {
        return testMnemonics.contains(mnemonic)
    }
}

func testWalletFunctionality() throws {
    let testMnemonic = SecureTestData.getTestMnemonic()
    
    // Ensure we're using test data
    guard SecureTestData.validateTestMnemonic(testMnemonic) else {
        throw SecurityError.insecureStorage
    }
    
    // Proceed with testing
    let seed = try Mnemonic.toSeed(mnemonic: testMnemonic)
    // Test functionality...
}
```

## Emergency Procedures

### Secure Backup and Recovery

```swift
struct SecureBackupManager {
    // Create encrypted backup
    static func createEncryptedBackup(mnemonic: String, password: String) throws -> Data {
        let mnemonicData = mnemonic.data(using: .utf8)!
        let passwordData = password.data(using: .utf8)!
        
        // Use AES-GCM for authenticated encryption
        let key = try CryptoKit.HKDF<CryptoKit.SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: passwordData),
            salt: Data("backup_salt".utf8),
            info: Data("mnemonic_backup".utf8),
            outputByteCount: 32
        )
        
        let sealedBox = try AES.GCM.seal(mnemonicData, using: key)
        return sealedBox.combined!
    }
    
    // Decrypt backup
    static func decryptBackup(_ encryptedData: Data, password: String) throws -> String {
        let passwordData = password.data(using: .utf8)!
        
        let key = try CryptoKit.HKDF<CryptoKit.SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: passwordData),
            salt: Data("backup_salt".utf8),
            info: Data("mnemonic_backup".utf8),
            outputByteCount: 32
        )
        
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        guard let mnemonic = String(data: decryptedData, encoding: .utf8) else {
            throw BackupError.decryptionFailed
        }
        
        return mnemonic
    }
}

enum BackupError: Error {
    case encryptionFailed
    case decryptionFailed
}
```

## Security Best Practices Summary

1. **Storage**: Always use secure storage (Keychain on iOS/macOS)
2. **Network**: Never transmit mnemonics or seeds over the network
3. **Memory**: Clear sensitive data from memory when done
4. **UI**: Disable screenshots/recording when showing sensitive data
5. **Backup**: Use encrypted backups with strong passwords
6. **Testing**: Only use known test vectors, never real data
7. **Passphrases**: Use strong, unique passphrases for additional security
8. **Validation**: Always validate mnemonics before use
9. **Environment**: Different security levels for debug vs production
10. **Audit**: Regular security audits and code reviews

## Common Vulnerabilities to Avoid

```swift
// ❌ Common mistakes to avoid:

// 1. Storing in UserDefaults
UserDefaults.standard.set(mnemonic, forKey: "mnemonic")

// 2. Logging sensitive data
print("User mnemonic: \(mnemonic)")

// 3. Sending over HTTP
let url = URL(string: "http://api.example.com/mnemonic")

// 4. Using weak passphrases
let weakPassphrase = "123456"

// 5. Not clearing memory
var mnemonic = "sensitive data"
// mnemonic continues to exist in memory

// 6. Hardcoding in source
let backdoorMnemonic = "abandon abandon..." // In production code!

// 7. Screenshot vulnerabilities
// Not hiding sensitive UI during app backgrounding

// 8. Clipboard persistence
UIPasteboard.general.string = mnemonic // Persists across apps!
```

## See Also

- <doc:SeedDerivation>
- <doc:ErrorHandling>
- ``MnemonicError``
