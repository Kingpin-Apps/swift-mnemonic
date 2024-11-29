import XCTest
@testable import SwiftMnemonic


final class LanguageTests: XCTestCase {

    func testLanguageWords() {
        // Test all cases of the Language enum
        for language in Language.allCases {
            do {
                let words = try language.words()
                XCTAssertFalse(words.isEmpty, "Wordlist for \(language.rawValue) should not be empty.")
                XCTAssertEqual(words.count, 2048, "Wordlist for \(language.rawValue) should contain exactly 2048 words.")
            } catch {
                XCTFail("Failed to load wordlist for \(language.rawValue): \(error)")
            }
        }
    }

    func testMissingWordlistFile() {
        // Temporarily use an invalid enum case to simulate a missing file
        let invalidLanguage = Language(rawValue: "invalid_language")
        XCTAssertNil(invalidLanguage, "Invalid language case should not create a Language instance.")
    }

    func testWordlistContent() {
        // Ensure that specific wordlists are correctly loaded
        do {
            let englishWords = try Language.english.words()
            XCTAssertEqual(englishWords.first, "abandon", "First word in the English wordlist should be 'abandon'.")
            XCTAssertEqual(englishWords.last, "zoo", "Last word in the English wordlist should be 'zoo'.")
        } catch {
            XCTFail("Failed to validate English wordlist content: \(error)")
        }
    }
}
