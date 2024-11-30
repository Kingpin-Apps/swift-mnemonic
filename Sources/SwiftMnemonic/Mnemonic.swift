import Foundation
import UncommonCrypto

public struct Mnemonic: Equatable, Hashable {
    /*
        Generates a mnemonic phrase in the specified language.
     
        - Parameters:
            language: The language to generate the mnemonic in. Defaults to English.
            wordlist: A custom wordlist to use for the mnemonic. Defaults to the language's wordlist.
     
        - Throws: An error if the wordlist is not the correct length.
     */
    
    /// The number of words in the wordlist.
    let radix = 2048
    
    /// The language to generate the mnemonic in.
    let language: Language
    
    /// The wordlist to use for the mnemonic.
    let wordlist: [String]
    
    /// The delimiter to use when joining words.
    let delimiter: String

    public init(language: Language = .english, wordlist: [String]? = nil) throws {
        self.language = language

        if let wordlist = wordlist {
            self.wordlist = wordlist
        } else {
            self.wordlist = try language.words()
        }

        if self.wordlist.count != radix {
            throw MnemonicError.invalidWordlistLength("Invalid wordlist length: \(self.wordlist.count)")
        }

        self.delimiter = language == .japanese ? "\u{3000}" : " "
    }

    public func listLanguages() -> [String] {
        return Language.allCases.map { $0.rawValue }
    }

    public static func normalizeString(_ txt: String) -> String {
        return txt.decomposedStringWithCompatibilityMapping
    }

    public func detectLanguage(code: String) throws -> Language {
        let normalizedCode = Mnemonic.normalizeString(code)
        var possibleLanguages = try listLanguages().map {
            try Mnemonic(language: Language(rawValue: $0)!)
        }
        let words = Set(normalizedCode.split(separator: " ").map { String($0) })

        for word in words {
            possibleLanguages = possibleLanguages.filter { $0.wordlist.contains { $0.hasPrefix(word) } }
            if possibleLanguages.isEmpty {
                throw MnemonicError.languageNotDetected("Language not detected for code: \(code)")
            }
        }

        if possibleLanguages.count == 1 {
            return possibleLanguages.first!.language
        }

        var completeLanguages = Set<Mnemonic>()
        for word in words {
            let exactMatches = possibleLanguages.filter { $0.wordlist.contains(word) }
            if exactMatches.count == 1 {
                completeLanguages.formUnion(exactMatches)
            }
        }

        if completeLanguages.count == 1 {
            return completeLanguages.first!.language
        }

        throw MnemonicError.languageNotDetected("Language not detected for code: \(code)")
    }

    public func generate(wordCount: WordCount = .twelve) throws -> [String] {
        let entropy = Data((0..<wordCount.strength / 8).map { _ in UInt8.random(in: 0...255) })
        return try toMnemonic(entropy: entropy)
    }

    public func toEntropy(_ phrase: [String], wordlist: [String]) throws -> [UInt8] {
        // Ensure the phrase has a valid length
        guard [12, 15, 18, 21, 24].contains(phrase.count) else {
            throw MnemonicError.invalidWordlistLength("Invalid wordlist length: \(phrase.count)")
        }

        // Convert words to a concatenated bit representation
        var concatBits = [Bool]()
        for word in phrase {
            guard let index = wordlist.firstIndex(of: word) else {
                throw MnemonicError.wordNotFound("Word not found in wordlist: \(word)")
            }

            // Convert index to an 11-bit binary representation
            let bits = (0..<11).map { (index >> (10 - $0)) & 1 == 1 }
            concatBits.append(contentsOf: bits)
        }

        // Calculate checksum bits length
        let checksumLength = concatBits.count / 33
        let entropyLength = concatBits.count - checksumLength

        // Convert the concatenated bits back to entropy bytes
        var entropy = [UInt8](repeating: 0, count: entropyLength / 8)
        for i in 0..<entropy.count {
            for j in 0..<8 {
                if concatBits[i * 8 + j] {
                    entropy[i] |= 1 << (7 - j)
                }
            }
        }

        // Compute the checksum from the entropy
        let hash = SHA2.hash(type: .sha256, bytes: entropy)
        let hashBytes = Array(hash) // Convert SHA256.Digest to an Array of bytes
        let hashBits = (0..<8).map { (hashBytes[0] >> (7 - $0)) & 1 == 1 }

        // Validate the checksum
        for i in 0..<checksumLength {
            if concatBits[entropyLength + i] != hashBits[i] {
                throw MnemonicError.failedChecksum("Checksum validation failed")
            }
        }

        return entropy
    }
    
    // Calculate checksum
    public static func calculateChecksumBits(_ entropy: Data) throws -> (checksum: UInt8, bits: Int) {
        guard entropy.count > 0, entropy.count <= 32, entropy.count % 4 == 0 else {
            throw MnemonicError.invalidEntropy("Invalid entropy length: \(entropy.count)")
        }
        
        let size = entropy.count / 4 // Calculate checksum size.
        let hash = SHA2.hash(type: .sha256, bytes: Array(entropy))
        return (hash[0] >> (8 - size), size)
    }

    public func toMnemonic(entropy: Data) throws -> [String] {
        // Validate entropy length
        guard [16, 20, 24, 28, 32].contains(entropy.count) else {
            throw MnemonicError.invalidWordlistLength("Invalid entropy length: \(entropy.count)")
        }

        // Calculate checksum
        let (checksum, csBits) = try Mnemonic.calculateChecksumBits(entropy)
        var bitArray = [Bool]()

        // Convert entropy bytes into bits
        for byte in entropy {
            for i in (0..<8).reversed() {
                bitArray.append((byte & (1 << i)) != 0)
            }
        }

        // Append checksum bits
        for i in (0..<csBits).reversed() {
            bitArray.append((checksum & (1 << i)) != 0)
        }

        // Split bits into 11-bit groups and map to words
        var phrase = [String]()
        for i in stride(from: 0, to: bitArray.count, by: 11) {
            let bitSlice = bitArray[i..<min(i + 11, bitArray.count)]
            var index = 0
            for (j, bit) in bitSlice.enumerated() {
                if bit {
                    index += 1 << (10 - j)
                }
            }
            phrase.append(wordlist[index])
        }

        return phrase
    }
    
    public func toMnemonicString(entropy: Data) throws -> String {
        let phrase = try toMnemonic(entropy: entropy)
        return phrase.joined(separator: delimiter)
    }

    public func check(mnemonic: String) throws -> Bool {
        let mnemonicList = Mnemonic.normalizeString(mnemonic).split(separator: " ").map { String($0) }
        guard [12, 15, 18, 21, 24].contains(mnemonicList.count) else {
            return false
        }
        
        do {
            let _ = try toEntropy(mnemonicList, wordlist: wordlist)
            return true
        } catch {
            return false
        }
    }

    public func expandWord(prefix: String) -> String {
        if wordlist.contains(prefix) {
            return prefix
        } else {
            let matches = wordlist.filter { $0.hasPrefix(prefix) }
            return matches.count == 1 ? matches[0] : prefix
        }
    }

    public func expand(mnemonic: String) -> String {
        return mnemonic.split(separator: " ").map { expandWord(prefix: String($0)) }.joined(separator: " ")
    }

    public static func toSeed(mnemonic: String, passphrase: String = "") throws -> Data {
        let normalizedMnemonic = normalizeString(mnemonic)
        let normalizedPassphrase = normalizeString(passphrase)
        let salt = "mnemonic" + normalizedPassphrase

        // Derive the key using PBKDF2
        let derivedKey = try PBKDF2.derive(
            type: .sha512,
            password: Array(normalizedMnemonic.utf8),
            salt: Array(salt.utf8)
        )

        return Data(derivedKey)
    }

    public static func toHDMasterKey(seed: Data, testnet: Bool = false) throws -> String {
        guard seed.count == 64 else {
            throw MnemonicError.invalidSeedLength("Invalid seed length: \(seed.count)")
        }
        
        let key = Array("Bitcoin seed".data(using: .utf8)!)
        let seedHMAC = HMAC.authenticate(type: .sha512, key: key, data: seed)

        var xprv = testnet ? Data([0x04, 0x35, 0x83, 0x94]) : Data([0x04, 0x88, 0xad, 0xe4])
        xprv.append(Data(repeating: 0, count: 9))
        xprv.append(Data(seedHMAC[32...]))
        xprv.append(Data([0x00]))
        xprv.append(Data(seedHMAC[..<32]))
        
        let hash = SHA2.hash(type: .sha256, bytes: Array(xprv))
        let doubleHash = SHA2.hash(type: .sha256, bytes: hash)
        
        xprv.append(contentsOf: doubleHash.prefix(4))

        return xprv.base58EncodedString()
    }
}
