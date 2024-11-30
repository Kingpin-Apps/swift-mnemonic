import Foundation

public enum WordCount: Int, Codable, Equatable, CaseIterable {
    case twelve = 12
    case fifteen = 15
    case eighteen = 18
    case twentyOne = 21
    case twentyFour = 24
    
    public var strength: Int {
        return (self.rawValue / 3) * 32
    }
}


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
