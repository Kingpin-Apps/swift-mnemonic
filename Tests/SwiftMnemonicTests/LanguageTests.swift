import Testing
import Foundation
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
    
    @Test("Test localized names for all languages")
    func testLocalizedNames() {
        // Test that the localizedName extension works for all languages
        for language in Language.allCases {
            let localizedName = language.localizedName
            #expect(!localizedName.isEmpty, "Localized name should not be empty for \(language.rawValue)")
            
            // Verify specific expected values
            switch language {
            case .english:
                #expect(localizedName.contains("English"))
            case .japanese:
                #expect(localizedName.contains("Japanese") || localizedName.contains("日本語"))
            case .chinese_simplified:
                #expect(localizedName.contains("Chinese") || localizedName.contains("简体中文"))
            case .chinese_traditional:
                #expect(localizedName.contains("Chinese") || localizedName.contains("繁體中文"))
            case .french:
                #expect(localizedName.contains("French") || localizedName.contains("Français"))
            case .spanish:
                #expect(localizedName.contains("Spanish") || localizedName.contains("Español"))
            case .italian:
                #expect(localizedName.contains("Italian") || localizedName.contains("Italiano"))
            case .portuguese:
                #expect(localizedName.contains("Portuguese") || localizedName.contains("Português"))
            case .korean:
                #expect(localizedName.contains("Korean") || localizedName.contains("한국어"))
            case .czech:
                #expect(localizedName.contains("Czech") || localizedName.contains("Čeština"))
            case .russian:
                #expect(localizedName.contains("Russian") || localizedName.contains("Русский"))
            case .turkish:
                #expect(localizedName.contains("Turkish") || localizedName.contains("Türkçe"))
            case .unsupported:
                #expect(localizedName.contains("Unsupported"))
            }
        }
    }
}

@Suite("WordCount tests")
struct WordCountTests {
    
    @Test("Test WordCount strength calculation")
    func testWordCountStrength() {
        #expect(WordCount.twelve.strength == 128, "12 words should have 128 bits of strength")
        #expect(WordCount.fifteen.strength == 160, "15 words should have 160 bits of strength")
        #expect(WordCount.eighteen.strength == 192, "18 words should have 192 bits of strength")
        #expect(WordCount.twentyOne.strength == 224, "21 words should have 224 bits of strength")
        #expect(WordCount.twentyFour.strength == 256, "24 words should have 256 bits of strength")
    }
    
    @Test("Test WordCount raw values")
    func testWordCountRawValues() {
        #expect(WordCount.twelve.rawValue == 12)
        #expect(WordCount.fifteen.rawValue == 15)
        #expect(WordCount.eighteen.rawValue == 18)
        #expect(WordCount.twentyOne.rawValue == 21)
        #expect(WordCount.twentyFour.rawValue == 24)
    }
    
    @Test("Test WordCount initialization from raw value")
    func testWordCountFromRawValue() {
        #expect(WordCount(rawValue: 12) == .twelve)
        #expect(WordCount(rawValue: 15) == .fifteen)
        #expect(WordCount(rawValue: 18) == .eighteen)
        #expect(WordCount(rawValue: 21) == .twentyOne)
        #expect(WordCount(rawValue: 24) == .twentyFour)
        #expect(WordCount(rawValue: 10) == nil, "Invalid raw value should return nil")
        #expect(WordCount(rawValue: 30) == nil, "Invalid raw value should return nil")
    }
    
    @Test("Test WordCount all cases")
    func testWordCountAllCases() {
        let allCases = WordCount.allCases
        #expect(allCases.count == 5, "Should have exactly 5 word count cases")
        #expect(allCases.contains(.twelve))
        #expect(allCases.contains(.fifteen))
        #expect(allCases.contains(.eighteen))
        #expect(allCases.contains(.twentyOne))
        #expect(allCases.contains(.twentyFour))
    }
    
    @Test("Test WordCount Codable")
    func testWordCountCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for wordCount in WordCount.allCases {
            let encoded = try encoder.encode(wordCount)
            let decoded = try decoder.decode(WordCount.self, from: encoded)
            #expect(decoded == wordCount, "WordCount should be codable: \(wordCount)")
        }
    }
    
    @Test("Test WordCount Equatable")
    func testWordCountEquatable() {
        #expect(WordCount.twelve == WordCount.twelve)
        #expect(WordCount.fifteen == WordCount.fifteen)
        #expect(WordCount.twelve != WordCount.fifteen)
        #expect(WordCount.twentyFour != WordCount.twelve)
    }
}
