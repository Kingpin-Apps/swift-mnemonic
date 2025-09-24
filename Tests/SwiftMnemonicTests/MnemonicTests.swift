import Foundation
import Testing
@testable import SwiftMnemonic

@Suite("Mnemonic Tests")
struct MnemonicTests {
    func checkList(language: Language, vectors: [[String]]) throws {
        let mnemonic = try Mnemonic(language: language)
        for v in vectors {
            let entropy = Data(fromHex: v[0])
            let code = try mnemonic.toMnemonicString(entropy: entropy)
            let seed = try Mnemonic.toSeed(mnemonic: code, passphrase: "TREZOR")
            let xprv = try Mnemonic.toHDMasterKey(seed: seed)
            
            #expect(try mnemonic.check(mnemonic: v[1]), "Failed to check mnemonic - \(language.rawValue)")
            #expect(v[1] == code, "Failed to generate mnemonic - \(language.rawValue)")
            #expect(v[2] == seed.hexEncodedString(), "Failed to generate seed - \(language.rawValue)")
            #expect(v[3] == xprv, "Failed to generate xprv - \(language.rawValue)")
        }
    }
    
    @Test("Test vectors from JSON")
    func testVectors() throws {
        let url = try #require(
            Bundle.module.url(
                forResource: "vectors",
                withExtension: "json",
                subdirectory: "data"
            ),
            "Failed to find vectors.json"
        )
        let data = try Data(contentsOf: url)
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        let json = try #require(jsonObject as? [String: [[String]]], "vectors.json has invalid format")
        
        for (lang, vectors) in json {
            if let language = Language(rawValue: lang) {
                try checkList(language: language, vectors: vectors)
            }
        }
    }
    
    @Test
    func testFailedChecksum() throws {
        let code = "bless cloud wheel regular tiny venue bird web grief security dignity zoo"
        let mnemonic = try Mnemonic(language: .english)
        #expect(try mnemonic.check(mnemonic: code) == false)
    }
    
    @Test
    func testDetection() throws {
        let mnemonic = try Mnemonic(language: .english)
        #expect(try mnemonic.detectLanguage(code: "security") == .english)
        #expect(try mnemonic.detectLanguage(code: "fruit wave dwarf") == .english)
        #expect(try mnemonic.detectLanguage(code: "fru wago dw") == .english)
        #expect(try mnemonic.detectLanguage(code: "fru wago dur enje") == .french)
        
        #expect(throws: MnemonicError.self) { _ = try mnemonic.detectLanguage(code: "jaguar xxxxxxx") }
        #expect(throws: MnemonicError.self) { _ = try mnemonic.detectLanguage(code: "jaguar jaguar") }
        
        #expect(try mnemonic.detectLanguage(code: "jaguar security") == .english)
        #expect(try mnemonic.detectLanguage(code: "jaguar aboyer") == .french)
        #expect(try mnemonic.detectLanguage(code: "abandon about") == .english)
        #expect(try mnemonic.detectLanguage(code: "abandon aboutir") == .french)
    }
    
    @Test
    func testNormalizationEquivalence() {
        let decomposed = "e\u{0301}"
        let precomposed = "\u{e9}"
        
        #expect(decomposed.precomposedStringWithCanonicalMapping == precomposed, "Normalization failed.")
        #expect(precomposed.decomposedStringWithCanonicalMapping == decomposed, "Normalization failed.")
    }
    
    @Test
    func testUtf8Normalization() throws {
        // The same sentence in various UTF-8 forms
        let wordsNfkd = "Pr\u{030c}i\u{0301}s\u{030c}erne\u{030c} z\u{030c}lut\u{030c}ouc\u{030c}ky\u{0301} ku\u{030a}n\u{030c} u\u{0301}pe\u{030c}l d\u{030c}a\u{0301}belske\u{0301} o\u{0301}dy za\u{0301}ker\u{030c}ny\u{0301} uc\u{030c}en\u{030c} be\u{030c}z\u{030c}i\u{0301} pode\u{0301}l zo\u{0301}ny u\u{0301}lu\u{030a}"
        let wordsNfc = "P\u{0159}\u{00ed}\u{0161}ern\u{011b} \u{017e}lu\u{0165}ou\u{010d}k\u{fd} k\u{016f}\u{0148} \u{fa}p\u{011b}l \u{010f}\u{e1}belsk\u{e9} \u{f3}dy z\u{e1}ke\u{0159}n\u{fd} u\u{010d}e\u{0148} b\u{011b}\u{017e}\u{ed} pod\u{e9}l z\u{f3}ny \u{fa}l\u{16f}"
        let wordsNfkc = "P\u{0159}\u{00ed}\u{0161}ern\u{011b} \u{017e}lu\u{0165}ou\u{010d}k\u{fd} k\u{016f}\u{0148} \u{fa}p\u{011b}l \u{010f}\u{e1}belsk\u{e9} \u{f3}dy z\u{e1}ke\u{0159}n\u{fd} u\u{010d}e\u{0148} b\u{011b}\u{017e}\u{ed} pod\u{e9}l z\u{f3}ny \u{fa}l\u{16f}"
        let wordsNfd = "Pr\u{030c}i\u{0301}s\u{030c}erne\u{030c} z\u{030c}lut\u{030c}ouc\u{030c}ky\u{0301} ku\u{030a}n\u{030c} u\u{0301}pe\u{030c}l d\u{030c}a\u{0301}belske\u{0301} o\u{0301}dy za\u{0301}ker\u{030c}ny\u{0301} uc\u{030c}en\u{030c} be\u{030c}z\u{030c}i\u{0301} pode\u{0301}l zo\u{0301}ny u\u{0301}lu\u{030a}"
        
        let passphraseNfkd = "Neuve\u{030c}r\u{030c}itelne\u{030c} bezpec\u{030c}ne\u{0301} hesli\u{0301}c\u{030c}ko"
        let passphraseNfc = "Neuv\u{011b}\u{0159}iteln\u{011b} bezpe\u{010d}n\u{00e9} hesl\u{00ed}\u{010d}ko"
        let passphraseNfkc = "Neuv\u{011b}\u{0159}iteln\u{011b} bezpe\u{010d}n\u{00e9} hesl\u{00ed}\u{010d}ko"
        let passphraseNfd = "Neuve\u{030c}r\u{030c}itelne\u{030c} bezpec\u{030c}ne\u{0301} hesli\u{0301}c\u{030c}ko"
        
        let seedNfkd = try Mnemonic.toSeed(mnemonic: wordsNfkd, passphrase: passphraseNfkd)
        let seedNfc = try Mnemonic.toSeed(mnemonic: wordsNfc, passphrase: passphraseNfc)
        let seedNfkc = try Mnemonic.toSeed(mnemonic: wordsNfkc, passphrase: passphraseNfkc)
        let seedNfd = try Mnemonic.toSeed(mnemonic: wordsNfd, passphrase: passphraseNfd)
        
        // Assert all seeds are equal
        #expect(seedNfkd == seedNfc, "Seeds generated from NFKD and NFC forms do not match.")
        #expect(seedNfkd == seedNfkc, "Seeds generated from NFKD and NFKC forms do not match.")
        #expect(seedNfkd == seedNfd, "Seeds generated from NFKD and NFD forms do not match.")
        #expect(seedNfc == seedNfkc, "Seeds generated from NFC and NFKD forms do not match.")
    }
    
    @Test
    func testToEntropy() throws {
        let mnemonic = try Mnemonic(language: .english)
        for _ in 0..<1024 {
            let entropy = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
            let phrase = try mnemonic.toMnemonic(entropy: entropy)
            let recoveredEntropy = try mnemonic.toEntropy(phrase, wordlist: mnemonic.wordlist)
            #expect(entropy == Data(recoveredEntropy))
        }
    }
    
    @Test
    func testExpandWord() throws {
        let mnemonic = try Mnemonic(language: .english)
        #expect(mnemonic.expandWord(prefix: "") == "")
        #expect(mnemonic.expandWord(prefix: " ") == " ")
        #expect(mnemonic.expandWord(prefix: "access") == "access")
        #expect(mnemonic.expandWord(prefix: "acce") == "access")
        #expect(mnemonic.expandWord(prefix: "acb") == "acb")
        #expect(mnemonic.expandWord(prefix: "acc") == "acc")
        #expect(mnemonic.expandWord(prefix: "act") == "act")
        #expect(mnemonic.expandWord(prefix: "acti") == "action")
    }
    
    @Test
    func testExpand() throws {
        let mnemonic = try Mnemonic(language: .english)
        #expect(mnemonic.expand(mnemonic: "access") == "access")
        #expect(mnemonic.expand(mnemonic: "access acce acb acc act acti") == "access access acb acc act action")
    }
    
    @Test
    func testGenerateValidStrengths() throws {
        for wordCount in WordCount.allCases {
            let mnemonic = try Mnemonic(language: .english)
            let phrase = try mnemonic.generate(wordCount: wordCount)
            
            // Verify the phrase has the expected word count
            #expect(
                phrase.count == wordCount.rawValue,
                "Expected \(wordCount.rawValue) words for count \(wordCount), but got \(phrase.count)."
            )
        }
    }

    @Test
    func testGenerateEntropyRandomness() throws {
        let mnemonic = try Mnemonic(language: .english)
        let phrase1 = try mnemonic.generate()
        let phrase2 = try mnemonic.generate()
        
        // Ensure the two generated phrases are not identical
        #expect(phrase1 != phrase2, "Generated mnemonic phrases should be different for different random entropy.")
    }

    @Test
    func testGenerateWithDifferentLanguages() throws {
        let languages: [Language] = [.english, .japanese, .french, .spanish]
        
        for language in languages {
            let mnemonic = try Mnemonic(language: language)
            let phrase = try mnemonic.generate()
            
            // Verify the phrase has the correct word count
            #expect(phrase.count == 12, "Expected 12 words for strength 128, but got \(phrase.count).")
            
            // Verify the phrase contains words from the specified language
            for word in phrase {
                #expect(mnemonic.wordlist.contains(word), "Word \(word) not found in \(language.rawValue) wordlist.")
            }
        }
    }
}
