import Foundation

/// Enum representing the number of words in a mnemonic phrase.
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

/// Enum representing supported languages for mnemonic phrases.
public enum Language: String, Codable, Equatable, CaseIterable {
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

    /// Load the wordlist for the specified language.
    /// - Throws: `MnemonicError` if the language is unsupported or if the wordlist file cannot be found or loaded.
    /// - Returns: An array of words in the specified language.
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
