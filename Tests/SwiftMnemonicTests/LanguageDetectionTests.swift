import Foundation
import Testing
@testable import SwiftMnemonic

@Suite("Language detection tests")
struct LanguageDetectionTests {

    /// Every supported language, in `Language.allCases` order.
    static let languages = Language.allCases.filter { $0 != .unsupported }

    /// A random simplified-Chinese phrase whose every word is also in the
    /// traditional-Chinese wordlist (found after 241 random entropies).
    static let sharedChineseEntropy = Data(fromHex: "6ac7381b0b16b4118fb84dacd5d9322e")

    @Test("Shared simplified/traditional Chinese phrase is detected by checksum")
    func testSharedChinesePhrase() throws {
        let phrase = try Mnemonic(language: .chinese_simplified, entropy: Self.sharedChineseEntropy).phrase
        let traditional = Set(try Language.chinese_traditional.words())
        #expect(phrase.allSatisfy { traditional.contains($0) }, "Fixture must be all-shared")

        #expect(try Mnemonic.detectLanguage(phrase: phrase.joined(separator: " ")) == .chinese_simplified)

        let restored = try Mnemonic(from: phrase)
        #expect(restored.language == .chinese_simplified)
        #expect(restored.entropy == Self.sharedChineseEntropy)
        #expect(restored.phrase == phrase)

        // Traditional decodes the same phrase to the same entropy.
        #expect(try Mnemonic.toEntropy(phrase, wordlist: Language.chinese_traditional.words())
            == Self.sharedChineseEntropy)
    }

    @Test("All-zero entropy Chinese phrase is shared and restores")
    func testZeroEntropyChinesePhrase() throws {
        let entropy = Data(repeating: 0, count: 16)
        let phrase = try Mnemonic(language: .chinese_traditional, entropy: entropy).phrase
        let restored = try Mnemonic(from: phrase)
        #expect(restored.language == .chinese_simplified)
        #expect(restored.entropy == entropy)
    }

    @Test("English/French shared words resolve by checksum")
    func testSharedEnglishFrenchPhrase() throws {
        let words = "service canal fruit exact essence virus angle brave fragile miracle noble festival"
        #expect(try Mnemonic.detectLanguage(phrase: words) == .english)
        let restored = try Mnemonic(from: words.components(separatedBy: " "))
        #expect(restored.language == .english)
        #expect(restored.entropy == Data(fromHex: "c42421772724d5e90230da5c71ae56aa"))
    }

    @Test("Phrase valid in two wordlists with different entropy is ambiguous")
    func testTrulyAmbiguousPhrase() throws {
        // Every word is in both the English and French lists, at different
        // indices, and the checksum passes in both.
        let words = "nature distance angle abandon simple palace opinion fatigue noble volume simple wagon"
        let english = try Mnemonic.toEntropy(words.components(separatedBy: " "), wordlist: Language.english.words())
        let french = try Mnemonic.toEntropy(words.components(separatedBy: " "), wordlist: Language.french.words())
        #expect(english != french)

        #expect(throws: MnemonicError.self) { _ = try Mnemonic.detectLanguage(phrase: words) }
        #expect(throws: MnemonicError.self) { _ = try Mnemonic(from: words.components(separatedBy: " ")) }
    }

    @Test("A phrase unique to each language is detected and restored", arguments: languages)
    func testUniquePhrasePerLanguage(language: Language) throws {
        for entropy in [TestConstants.validEntropy16, TestConstants.validEntropy32] {
            let original = try Mnemonic(language: language, entropy: entropy)
            let phrase = original.phrase

            let others = try Self.languages.filter { $0 != language }.map { Set(try $0.words()) }
            #expect(others.allSatisfy { list in !phrase.allSatisfy { list.contains($0) } },
                    "Fixture for \(language.rawValue) must not fit any other wordlist")

            #expect(try Mnemonic.detectLanguage(phrase: original.toMnemonicString(entropy: entropy)) == language)

            let restored = try Mnemonic(from: phrase)
            #expect(restored.language == language)
            #expect(restored.entropy == entropy)
            #expect(restored.phrase == phrase)
            #expect(restored == original)
        }
    }

    @Test("Official vectors restore to their entropy")
    func testVectorsRestore() throws {
        let url = try #require(Bundle.module.url(forResource: "vectors", withExtension: "json", subdirectory: "data"))
        let json = try #require(
            try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: [[String]]])

        for (lang, vectors) in json {
            let language = try #require(Language(rawValue: lang))
            for vector in vectors {
                let restored = try Mnemonic(from: vector[1].components(separatedBy: " "))
                #expect(restored.entropy == Data(fromHex: vector[0]), "\(lang): \(vector[1])")
                // A traditional-Chinese vector may consist only of characters
                // shared with simplified Chinese; then simplified is reported.
                if restored.language != language {
                    #expect(language == .chinese_traditional && restored.language == .chinese_simplified)
                }
            }
        }
    }

    @Test("Invalid checksum is rejected")
    func testInvalidChecksum() throws {
        let words = "bless cloud wheel regular tiny venue bird web grief security dignity zoo"
        #expect(throws: MnemonicError.failedChecksum("Checksum validation failed")) {
            _ = try Mnemonic(from: words.components(separatedBy: " "))
        }

        // All words shared between the Chinese lists, checksum fails in both.
        let chinese = Array(repeating: "的", count: 12)
        #expect(throws: MnemonicError.self) {
            _ = try Mnemonic.detectLanguage(phrase: chinese.joined(separator: " "))
        }
        #expect(throws: MnemonicError.self) { _ = try Mnemonic(from: chinese) }
    }

    @Test("Phrase mixing languages is rejected")
    func testMixedLanguagePhrase() throws {
        var words = TestConstants.validMnemonic12
        words[3] = "abeille" // French only
        #expect(throws: MnemonicError.self) { _ = try Mnemonic(from: words) }

        var chinese = try Mnemonic(language: .chinese_simplified, entropy: TestConstants.validEntropy16).phrase
        chinese[0] = try Language.japanese.words()[5]
        #expect(throws: MnemonicError.self) { _ = try Mnemonic(from: chinese) }
    }

    @Test("Composed (NFC) input restores against the NFKD wordlists")
    func testComposedInputRestores() throws {
        for language in [Language.french, .spanish, .japanese, .korean] {
            let original = try Mnemonic(language: language, entropy: TestConstants.validEntropy32)
            let composed = original.phrase.map { $0.precomposedStringWithCanonicalMapping }
            #expect(composed.map { Array($0.unicodeScalars) } != original.phrase.map { Array($0.unicodeScalars) },
                    "Fixture for \(language.rawValue) should change scalars under NFC")

            let restored = try Mnemonic(from: composed)
            #expect(restored.language == language)
            #expect(restored.entropy == TestConstants.validEntropy32)
        }
    }

    @Test("Compatibility (full-width) input is NFKD-normalized before lookup")
    func testCompatibilityInputRestores() throws {
        // U+FF41... full-width Latin letters only match after NFKD.
        let fullWidth = TestConstants.validMnemonic12.map { word in
            String(String.UnicodeScalarView(word.unicodeScalars.map { Unicode.Scalar($0.value + 0xFEE0)! }))
        }
        let restored = try Mnemonic(from: fullWidth)
        #expect(restored.language == .english)
        #expect(restored.entropy == Data(repeating: 0, count: 16))
    }

    @Test("Japanese ideographic-space phrase is detected")
    func testJapaneseDelimiter() throws {
        let original = try Mnemonic(language: .japanese, entropy: TestConstants.validEntropy16)
        let joined = try original.toMnemonicString(entropy: TestConstants.validEntropy16)
        #expect(joined.contains("\u{3000}"))
        #expect(try Mnemonic.detectLanguage(phrase: joined) == .japanese)
        #expect(try Mnemonic(from: [joined]).entropy == TestConstants.validEntropy16)
    }
}
