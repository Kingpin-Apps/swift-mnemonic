import Foundation
import Testing
@testable import SwiftMnemonic

@Suite("Security regression tests")
struct SecurityRegressionTests {
    static let rejectedPhrases: [[String]] = [
        Array(repeating: "abandon", count: 11) + ["abuot"],
        ["abandon", "abandon", "abandon", "abandn"] + Array(repeating: "abandon", count: 7) + ["about"],
        Array(repeating: "abandon", count: 12),
        Array(repeating: "abandon", count: 11) + ["abou"],
        Array(repeating: "abandon", count: 11) + ["zoo"],
    ]

    @Test("Restore errors never contain mnemonic words", arguments: rejectedPhrases)
    func restoreErrorsAreRedacted(words: [String]) {
        do {
            _ = try Mnemonic(from: words)
            Issue.record("Expected restore to fail")
        } catch {
            let description = String(describing: error)
            for word in Set(words) {
                #expect(!description.contains(word), "Error leaks '\(word)': \(description)")
            }
        }
    }

    @Test("detectLanguage errors never contain mnemonic words")
    func detectLanguageErrorIsRedacted() {
        let phrase = "abandon abandon abandon abandn abandon abandon abandon abandon abandon abandon abandon about"
        #expect(throws: MnemonicError.languageNotDetected("Language not detected for 12-word phrase")) {
            try Mnemonic.detectLanguage(phrase: phrase)
        }
    }

    @Test("toEntropy reports the position of an unknown word, not the word")
    func wordNotFoundIsRedacted() throws {
        let words = Array(repeating: "abandon", count: 11) + ["aband"]
        #expect(throws: MnemonicError.wordNotFound("Word not found in wordlist at position 12")) {
            try Mnemonic.toEntropy(words, wordlist: try Language.english.words())
        }
    }

    @Test("Data(fromHex:) decodes valid hex in either case")
    func hexDecodesValidInput() throws {
        #expect(try Data(fromHex: "") == Data())
        #expect(try Data(fromHex: "00ff7Fa0") == Data([0x00, 0xff, 0x7f, 0xa0]))
        #expect(try Data(fromHex: "DEADbeef").hexEncodedString() == "deadbeef")
    }

    @Test("Data(fromHex:) rejects malformed hex without trapping",
          arguments: ["zz", "abc", "+f+f", "+1-0", "-0", "0 ", " 00", "0g", "00\n", "000000000000000000000000000000f", "１２"])
    func hexRejectsMalformedInput(hex: String) {
        #expect(throws: MnemonicError.self) { try Data(fromHex: hex) }
    }
}
