import Foundation

/// Errors that can be thrown by the Mnemonic module.
/// - Note: All error cases have an associated string message for additional context.
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
