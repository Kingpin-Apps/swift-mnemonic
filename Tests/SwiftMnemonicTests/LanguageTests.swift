import Testing
@testable import SwiftMnemonic

@Suite("Language tests")
struct LanguageTests {

    @Test("All language wordlists load and are 2048 words")
    func testLanguageWords() {
        // Test all cases of the Language enum
        for language in Language.allCases {
            do {
                if language == .unsupported {
                    // Expecting this to throw; fail if it does not
                    #expect(throws: MnemonicError.self) {
                        _ = try language.words()
                    }
                    continue
                }
                let words = try language.words()
                #expect(!words.isEmpty, "Wordlist for \(language.rawValue) should not be empty.")
                #expect(words.count == 2048, "Wordlist for \(language.rawValue) should contain exactly 2048 words.")
            } catch {
                Issue.record("Failed to load wordlist for \(language.rawValue): \(error)")
                return
            }
        }
    }

    @Test("Invalid enum case should be nil")
    func testMissingWordlistFile() {
        // Temporarily use an invalid enum case to simulate a missing file
        let invalidLanguage = Language(rawValue: "invalid_language")
        #expect(invalidLanguage == nil, "Invalid language case should not create a Language instance.")
    }

    @Test("English wordlist content sanity check")
    func testWordlistContent() throws {
        // Ensure that specific wordlists are correctly loaded
        let englishWords = try Language.english.words()
        #expect(englishWords.first == "abandon", "First word in the English wordlist should be 'abandon'.")
        #expect(englishWords.last == "zoo", "Last word in the English wordlist should be 'zoo'.")
    }
}
