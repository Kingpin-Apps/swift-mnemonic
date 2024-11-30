import Foundation

public enum MnemonicError: Error, Equatable {
    case failedChecksum(String?)
    case fileNotFound(String?)
    case fileLoadFail(String?)
    case invalidEntropy(String?)
    case invalidSeedLength(String?)
    case invalidStrengthValue(String?)
    case invalidWordlistLength(String?)
    case languageNotDetected(String?)
    case wordNotFound(String?)
}
