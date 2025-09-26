import Foundation
import UncommonCrypto

/// A BIP-39 compliant mnemonic phrase generator and validator.
///
/// `Mnemonic` provides comprehensive functionality for generating, validating, and working with
/// mnemonic phrases according to the BIP-39 specification. It supports 12 languages and
/// multiple entropy sizes (128, 160, 192, 224, and 256 bits).
///
/// ## Overview
///
/// The `Mnemonic` struct can be used in several ways:
/// 1. Generate new mnemonic phrases with cryptographically secure random entropy
/// 2. Create mnemonics from existing entropy data
/// 3. Restore and validate existing mnemonic phrases
/// 4. Convert between entropy and mnemonic representations
///
/// ## Example Usage
///
/// ```swift
/// // Generate a new 24-word English mnemonic
/// let mnemonic = try Mnemonic(language: .english, wordCount: .twentyFour)
/// print("Generated: \(mnemonic.phrase.joined(separator: " "))")
///
/// // Restore from existing mnemonic phrase
/// let words = ["abandon", "abandon", "abandon", "abandon", "abandon", "abandon",
///              "abandon", "abandon", "abandon", "abandon", "abandon", "about"]
/// let restored = try Mnemonic(from: words)
/// print("Language detected: \(restored.language)")
/// ```
///
/// ## Thread Safety
///
/// `Mnemonic` conforms to `Sendable` and is safe to use across concurrent contexts.
/// All operations are immutable and thread-safe.
///
/// - Note: This implementation follows BIP-39 specification strictly, ensuring
///   compatibility with other BIP-39 compliant wallet implementations.
public struct Mnemonic: Equatable, Hashable, Sendable {
    /// The number of words in the wordlist (always 2048 for BIP-39 compliance).
    let radix = 2048
    
    /// The language used for the mnemonic phrase.
    ///
    /// This determines which wordlist is used and affects the delimiter for joining words.
    /// Japanese uses a full-width space (\u{3000}), while other languages use a regular space.
    let language: Language
    
    /// The wordlist used for encoding and decoding mnemonic phrases.
    ///
    /// Contains exactly 2048 words as specified by BIP-39. Each word corresponds to
    /// an 11-bit index used in mnemonic encoding.
    let wordlist: [String]
    
    /// The delimiter used when joining mnemonic words into a string.
    ///
    /// - Returns: `"\u{3000}"` (full-width space) for Japanese, `" "` (space) for all other languages.
    let delimiter: String
    
    /// The entropy data used to generate the mnemonic phrase.
    ///
    /// This is the raw cryptographic entropy that the mnemonic represents.
    /// Must be 128, 160, 192, 224, or 256 bits (16, 20, 24, 28, or 32 bytes).
    let entropy: Data
    
    /// The mnemonic phrase as an array of words.
    ///
    /// This computed property generates the mnemonic words from the stored entropy.
    /// The number of words depends on the entropy size:
    /// - 128 bits → 12 words
    /// - 160 bits → 15 words  
    /// - 192 bits → 18 words
    /// - 224 bits → 21 words
    /// - 256 bits → 24 words
    ///
    /// ## Example
    /// ```swift
    /// let mnemonic = try Mnemonic(language: .english, wordCount: .twelve)
    /// print(mnemonic.phrase) // ["word1", "word2", ..., "word12"]
    /// ```
    var phrase: [String] {
        return try! Self.toMnemonic(entropy: entropy, wordlist: wordlist)
    }

    /// Creates a new `Mnemonic` instance with specified parameters.
    ///
    /// This is the primary initializer that supports multiple use cases:
    /// 1. Generate a new mnemonic with random entropy
    /// 2. Create a mnemonic from existing entropy data
    /// 3. Use custom wordlists for specialized applications
    ///
    /// ## Usage Examples
    ///
    /// ```swift
    /// // Generate new 12-word English mnemonic
    /// let mnemonic1 = try Mnemonic(wordCount: .twelve)
    ///
    /// // Create mnemonic from specific entropy
    /// let entropy = Data([0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
    ///                     0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff])
    /// let mnemonic2 = try Mnemonic(language: .english, entropy: entropy)
    ///
    /// // Use different language
    /// let mnemonic3 = try Mnemonic(language: .japanese, wordCount: .twentyFour)
    /// ```
    ///
    /// - Parameters:
    ///   - language: The language for word selection. Defaults to `.english`.
    ///   - wordlist: Custom wordlist (must contain exactly 2048 words). If `nil`, uses the built-in list for the specified language.
    ///   - wordCount: Number of words in the mnemonic (12, 15, 18, 21, or 24). Defaults to `.twentyFour`.
    ///   - entropy: Specific entropy data to use. If `nil`, cryptographically secure random entropy is generated.
    ///
    /// - Throws:
    ///   - `MnemonicError.invalidWordlistLength`: If the wordlist doesn't contain exactly 2048 words.
    ///   - `MnemonicError.invalidEntropy`: If the provided entropy has an invalid length.
    ///
    /// - Note: If both `wordCount` and `entropy` are specified, the `entropy` parameter takes precedence
    ///   and `wordCount` is ignored.
    public init(
        language: Language = .english,
        wordlist: [String]? = nil,
        wordCount: WordCount = .twentyFour,
        entropy: Data? = nil
    ) throws {
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
        
        if let entropy = entropy {
            guard [16, 20, 24, 28, 32].contains(entropy.count) else {
                throw MnemonicError.invalidEntropy("Invalid entropy length: \(entropy.count)")
            }
            self.entropy = entropy
        } else {
            self.entropy = Data(try SecureRandom.bytes(size: wordCount.strength / 8))
        }
    }
    
    /// Creates a `Mnemonic` instance by restoring from an existing mnemonic phrase.
    ///
    /// This convenience initializer automatically detects the language of the provided
    /// mnemonic phrase and recreates the `Mnemonic` instance with the original entropy.
    ///
    /// ## Example Usage
    ///
    /// ```swift
    /// let words = ["abandon", "abandon", "abandon", "abandon", "abandon", "abandon",
    ///              "abandon", "abandon", "abandon", "abandon", "abandon", "about"]
    /// let mnemonic = try Mnemonic(from: words)
    /// print("Detected language: \(mnemonic.language)") // .english
    /// print("Word count: \(mnemonic.phrase.count)")     // 12
    /// ```
    ///
    /// - Parameter mnemonic: An array of mnemonic words to restore from.
    ///
    /// - Throws:
    ///   - `MnemonicError.languageNotDetected`: If the language cannot be determined.
    ///   - `MnemonicError.wordNotFound`: If any word is not found in the detected language's wordlist.
    ///   - `MnemonicError.failedChecksum`: If the mnemonic fails BIP-39 checksum validation.
    ///   - `MnemonicError.invalidWordlistLength`: If the phrase length is invalid (not 12, 15, 18, 21, or 24 words).
    ///
    /// - Note: This method performs full BIP-39 validation including checksum verification.
    public init(from mnemonic: [String]) throws {
        let language = try Mnemonic.detectLanguage(phrase: mnemonic.joined(separator: " "))
        try self.init(entropy: Self.toEntropy(mnemonic, wordlist: language.words()))
    }

    /// Returns the list of supported language identifiers.
    /// - Returns: An array of language raw values (for example, "english", "japanese").
    public static func listLanguages() -> [String] {
        return Language.allCases
            .filter { $0 != .unsupported }
            .map { $0.rawValue }
    }

    /// Normalizes a string using Unicode compatibility decomposition (NFKD).
    /// This normalization is recommended by BIP-39 to ensure consistent hashing and comparison.
    /// - Parameter txt: The input string to normalize.
    /// - Returns: The normalized string.
    public static func normalizeString(_ txt: String) -> String {
        return txt.decomposedStringWithCompatibilityMapping
    }

    /// Attempts to detect the mnemonic language from a space-separated phrase.
    /// The detection first narrows candidates by prefix matches, then by exact matches.
    /// - Parameter phrase: The mnemonic phrase or partial phrase to analyze.
    /// - Returns: The detected `Language`.
    /// - Throws: `MnemonicError.languageNotDetected` if a unique language cannot be determined.
    public static func detectLanguage(phrase: String) throws -> Language {
        let normalizedCode = Mnemonic.normalizeString(phrase)
        var possibleLanguages = try listLanguages().map {
            try Mnemonic(language: Language(rawValue: $0)!)
        }
        let words = Set(normalizedCode.split(separator: " ").map { String($0) })

        for word in words {
            possibleLanguages = possibleLanguages.filter { $0.wordlist.contains { $0.hasPrefix(word) } }
            if possibleLanguages.isEmpty {
                throw MnemonicError.languageNotDetected("Language not detected for phrase: \(phrase)")
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

        throw MnemonicError.languageNotDetected("Language not detected for phrase: \(phrase)")
    }

    /// Generates a new mnemonic phrase using cryptographically secure random entropy.
    /// - Parameter wordCount: Desired number of words (12, 15, 18, 21, or 24). Defaults to `.twelve`.
    /// - Returns: The generated mnemonic as an array of words.
    /// - Throws: An error if generation fails.
    public func generate(wordCount: WordCount = .twelve) throws -> [String] {
        let entropy = try SecureRandom.bytes(size: wordCount.strength / 8)
        return try Self.toMnemonic(entropy: Data(entropy), wordlist: wordlist)
    }

    /// Converts a mnemonic phrase into its underlying entropy.
    /// - Parameters:
    ///   - phrase: The mnemonic words (12/15/18/21/24).
    ///   - wordlist: The word list used to encode the phrase.
    /// - Returns: The recovered entropy bytes.
    /// - Throws:
    ///   - `MnemonicError.invalidWordlistLength` if the phrase length is invalid.
    ///   - `MnemonicError.wordNotFound` if a word is not present in `wordlist`.
    ///   - `MnemonicError.failedChecksum` if the checksum does not match.
    public static func toEntropy(_ phrase: [String], wordlist: [String]) throws -> Data {
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

        return Data(entropy)
    }
    
    /// Calculates the BIP-39 checksum bits for the given entropy.
    ///
    /// This method computes the checksum according to BIP-39 specification by taking the SHA-256
    /// hash of the entropy and using the appropriate number of most significant bits as the checksum.
    /// The number of checksum bits is determined by the entropy length:
    /// - 128 bits (16 bytes) → 4 checksum bits
    /// - 160 bits (20 bytes) → 5 checksum bits
    /// - 192 bits (24 bytes) → 6 checksum bits
    /// - 224 bits (28 bytes) → 7 checksum bits
    /// - 256 bits (32 bytes) → 8 checksum bits
    ///
    /// ## Example Usage
    ///
    /// ```swift
    /// let entropy = Data([0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
    ///                     0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff])
    /// let (checksum, bitCount) = try Mnemonic.calculateChecksumBits(entropy)
    /// print("Checksum: 0x\(String(checksum, radix: 16)), bits: \(bitCount)")
    /// ```
    ///
    /// - Parameter entropy: The entropy data (must be 16, 20, 24, 28, or 32 bytes).
    /// - Returns: A tuple containing:
    ///   - `checksum`: The checksum byte with relevant high bits set
    ///   - `bits`: The number of checksum bits used
    /// - Throws: `MnemonicError.invalidEntropy` if entropy length is invalid or zero.
    public static func calculateChecksumBits(_ entropy: Data) throws -> (checksum: UInt8, bits: Int) {
        guard entropy.count > 0, entropy.count <= 32, entropy.count % 4 == 0 else {
            throw MnemonicError.invalidEntropy("Invalid entropy length: \(entropy.count)")
        }
        
        let size = entropy.count / 4 // Calculate checksum size.
        let hash = SHA2.hash(type: .sha256, bytes: Array(entropy))
        return (hash[0] >> (8 - size), size)
    }

    /// Encodes entropy as a mnemonic phrase using the `wordlist`.
    /// - Parameters:
    ///  - entropy: Entropy data.
    ///  - wordlist: The word list to use for encoding.
    /// - Returns: The mnemonic words.
    /// - Throws: `MnemonicError.invalidWordlistLength` if `entropy` has an unsupported size.
    public static func toMnemonic(entropy: Data, wordlist: [String]) throws -> [String] {
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
    
    /// Converts entropy data to a properly formatted mnemonic string.
    ///
    /// This method encodes the provided entropy as a mnemonic phrase and joins the words
    /// with the appropriate delimiter for the language (regular space for most languages,
    /// full-width space for Japanese).
    ///
    /// ## Example Usage
    ///
    /// ```swift
    /// let mnemonic = try Mnemonic(language: .english)
    /// let entropy = Data([0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
    ///                     0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff])
    /// let mnemonicString = try mnemonic.toMnemonicString(entropy: entropy)
    /// print(mnemonicString) // "abandon abandon ... about"
    /// ```
    ///
    /// - Parameter entropy: The entropy data to encode (16, 20, 24, 28, or 32 bytes).
    /// - Returns: The mnemonic phrase as a single string with appropriate word delimiters.
    /// - Throws: `MnemonicError.invalidWordlistLength` if entropy length is invalid.
    public func toMnemonicString(entropy: Data) throws -> String {
        let phrase = try Self.toMnemonic(entropy: entropy, wordlist: wordlist)
        return phrase.joined(separator: delimiter)
    }

    /// Validates a mnemonic phrase against the current `wordlist`.
    /// - Parameter mnemonic: The space-separated mnemonic string.
    /// - Returns: `true` if the phrase is well-formed and passes checksum validation; otherwise, `false`.
    public func check(mnemonic: String) throws -> Bool {
        let mnemonicList = Mnemonic.normalizeString(mnemonic).split(separator: " ").map { String($0) }
        guard [12, 15, 18, 21, 24].contains(mnemonicList.count) else {
            return false
        }
        
        do {
            let _ = try Self.toEntropy(mnemonicList, wordlist: wordlist)
            return true
        } catch {
            return false
        }
    }

    /// Expands a word prefix to a full word when the prefix uniquely identifies a word in the `wordlist`.
    /// - Parameter prefix: The word or prefix to expand.
    /// - Returns: The full word if uniquely determined; otherwise, the original `prefix`.
    public func expandWord(prefix: String) -> String {
        if wordlist.contains(prefix) {
            return prefix
        } else {
            let matches = wordlist.filter { $0.hasPrefix(prefix) }
            return matches.count == 1 ? matches[0] : prefix
        }
    }

    /// Expands each word prefix in a mnemonic string using `expandWord(prefix:)`.
    /// - Parameter mnemonic: The mnemonic containing full words or prefixes.
    /// - Returns: A mnemonic string with uniquely resolvable prefixes expanded.
    public func expand(mnemonic: String) -> String {
        return mnemonic.split(separator: " ").map { expandWord(prefix: String($0)) }.joined(separator: " ")
    }

    /// Derives a binary seed from a mnemonic and optional passphrase.
    /// Uses PBKDF2-HMAC-SHA512 with the salt "mnemonic" + passphrase, per BIP-39.
    /// - Parameters:
    ///   - mnemonic: The mnemonic phrase.
    ///   - passphrase: An optional passphrase to harden the seed. Defaults to an empty string.
    /// - Returns: The derived seed data.
    /// - Throws: An error if key derivation fails.
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

    /// Derives a Base58Check-encoded extended private key (xprv/tprv) from a 64-byte seed.
    /// - Parameters:
    ///   - seed: A 64-byte seed (output of `toSeed`).
    ///   - testnet: If `true`, uses the testnet version prefix; otherwise, mainnet.
    /// - Returns: The extended private key as a Base58Check string.
    /// - Throws: `MnemonicError.invalidSeedLength` if `seed` is not 64 bytes.
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

