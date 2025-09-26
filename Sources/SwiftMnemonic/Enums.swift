import Foundation

/// Represents the supported word counts for mnemonic phrases and their corresponding entropy strength.
///
/// Each word count corresponds to a specific entropy strength as defined by BIP-39:
/// - `.twelve`: 12 words → 128 bits of entropy (16 bytes)
/// - `.fifteen`: 15 words → 160 bits of entropy (20 bytes)
/// - `.eighteen`: 18 words → 192 bits of entropy (24 bytes)
/// - `.twentyOne`: 21 words → 224 bits of entropy (28 bytes)
/// - `.twentyFour`: 24 words → 256 bits of entropy (32 bytes)
///
/// ## Example
///
/// ```swift
/// // Generate a mnemonic with specific word count
/// let mnemonic = try Mnemonic(language: .english, wordCount: .twentyFour)
/// 
/// // Get entropy strength in bits
/// let bits = WordCount.twentyFour.strength // 256
/// ```
public enum WordCount: Int, Codable, Equatable, CaseIterable {
    case twelve = 12
    case fifteen = 15
    case eighteen = 18
    case twentyOne = 21
    case twentyFour = 24
    
    /// The strength in bits corresponding to the word count.
    /// For example, 12 words correspond to 128 bits of entropy.
    /// - Returns: The strength in bits.
    public var strength: Int {
        return (self.rawValue / 3) * 32
    }
}

/// Represents supported languages for BIP-39 mnemonic phrases.
///
/// This enum covers all 12 languages officially supported by BIP-39:
/// - `english`: The default language for most cryptocurrency applications
/// - `chinese_simplified`, `chinese_traditional`: Chinese variants
/// - `japanese`: Uses special full-width space (\u{3000}) as delimiter
/// - Other languages: `czech`, `french`, `italian`, `korean`, `portuguese`, `russian`, `spanish`, `turkish`
///
/// ## Example Usage
///
/// ```swift
/// // List all supported languages
/// let languages = Language.allCases.filter { $0 != .unsupported }
///
/// // Create mnemonic in specific language
/// let mnemonic = try Mnemonic(language: .japanese)
/// ```
public enum Language: String, Codable, Equatable, CaseIterable, Sendable {
    case chinese_simplified
    case chinese_traditional
    case czech
    case english
    case french
    case italian
    case japanese
    case korean
    case portuguese
    case russian
    case spanish
    case turkish
    case unsupported

    /// Loads the BIP-39 wordlist for this language.
    ///
    /// Each language has exactly 2048 words as defined by the BIP-39 specification.
    /// The words are loaded from embedded text files within the bundle.
    ///
    /// ## Example Usage
    ///
    /// ```swift
    /// let englishWords = try Language.english.words()
    /// print(englishWords.count) // 2048
    /// print(englishWords[0])    // "abandon"
    /// 
    /// let japaneseWords = try Language.japanese.words()
    /// // Japanese wordlist contains hiragana characters
    /// ```
    ///
    /// - Returns: An array of exactly 2048 words in the specified language.
    /// - Throws: 
    ///   - `MnemonicError.unsupportedLanguage`: If called on `.unsupported`.
    ///   - `MnemonicError.fileNotFound`: If the wordlist file is missing from the bundle.
    ///   - `MnemonicError.fileLoadFail`: If the wordlist file cannot be read.
    public func words() throws -> [String] {
        if self == .unsupported {
            throw MnemonicError.unsupportedLanguage("Unsupported language: \(self.rawValue)")
        }
        guard let filePath = Bundle.module.path(forResource: self.rawValue, ofType: "txt", inDirectory: "wordlist") else {
            throw MnemonicError.fileNotFound("Wordlist file not found: \(self.rawValue).txt")
        }
        guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            throw MnemonicError.fileLoadFail("Failed to load wordlist for \(self.rawValue)")
        }
        return content.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }
}

extension Language {
    var localizedName: String {
        switch self {
            case .english:
                return NSLocalizedString("English", comment: "Language name")
            case .japanese:
                return NSLocalizedString("Japanese (日本語)", comment: "Language name")
            case .chinese_simplified:
                return NSLocalizedString("Chinese Simplified (简体中文)", comment: "Language name")
            case .chinese_traditional:
                return NSLocalizedString("Chinese Traditional (繁體中文)", comment: "Language name")
            case .french:
                return NSLocalizedString("French (Français)", comment: "Language name")
            case .spanish:
                return NSLocalizedString("Spanish (Español)", comment: "Language name")
            case .italian:
                return NSLocalizedString("Italian (Italiano)", comment: "Language name")
            case .portuguese:
                return NSLocalizedString("Portuguese (Português)", comment: "Language name")
            case .korean:
                return NSLocalizedString("Korean (한국어)", comment: "Language name")
            case .czech:
                return NSLocalizedString("Czech (Čeština)", comment: "Language name")
            case .russian:
                return NSLocalizedString("Russian (Русский)", comment: "Language name")
            case .turkish:
                return NSLocalizedString("Turkish (Türkçe)", comment: "Language name")
            case .unsupported:
                return NSLocalizedString("Unsupported", comment: "Language name")
        }
    }
}
