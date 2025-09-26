import Testing
@testable import SwiftMnemonic

@Suite("MnemonicError Tests")
struct ErrorsTests {
    
    @Test("Test all MnemonicError cases are equatable")
    func testMnemonicErrorEquality() {
        let error1 = MnemonicError.failedChecksum("Test message")
        let error2 = MnemonicError.failedChecksum("Test message")
        let error3 = MnemonicError.failedChecksum("Different message")
        let error4 = MnemonicError.fileNotFound("Test message")
        
        #expect(error1 == error2, "Same error cases with same messages should be equal")
        #expect(error1 != error3, "Same error cases with different messages should not be equal")
        #expect(error1 != error4, "Different error cases should not be equal")
    }
    
    @Test("Test MnemonicError.failedChecksum")
    func testFailedChecksumError() {
        let message = "Checksum validation failed"
        let error = MnemonicError.failedChecksum(message)
        
        #expect(error == MnemonicError.failedChecksum(message))
        #expect(error != MnemonicError.failedChecksum("Different message"))
    }
    
    @Test("Test MnemonicError.fileNotFound")
    func testFileNotFoundError() {
        let message = "Wordlist file not found"
        let error = MnemonicError.fileNotFound(message)
        
        #expect(error == MnemonicError.fileNotFound(message))
        #expect(error != MnemonicError.fileNotFound("Different message"))
    }
    
    @Test("Test MnemonicError.fileLoadFail")
    func testFileLoadFailError() {
        let message = "Failed to load wordlist"
        let error = MnemonicError.fileLoadFail(message)
        
        #expect(error == MnemonicError.fileLoadFail(message))
        #expect(error != MnemonicError.fileLoadFail("Different message"))
    }
    
    @Test("Test MnemonicError.invalidEntropy")
    func testInvalidEntropyError() {
        let message = "Invalid entropy length"
        let error = MnemonicError.invalidEntropy(message)
        
        #expect(error == MnemonicError.invalidEntropy(message))
        #expect(error != MnemonicError.invalidEntropy("Different message"))
    }
    
    @Test("Test MnemonicError.invalidSeedLength")
    func testInvalidSeedLengthError() {
        let message = "Invalid seed length"
        let error = MnemonicError.invalidSeedLength(message)
        
        #expect(error == MnemonicError.invalidSeedLength(message))
        #expect(error != MnemonicError.invalidSeedLength("Different message"))
    }
    
    @Test("Test MnemonicError.invalidStrengthValue")
    func testInvalidStrengthValueError() {
        let message = "Invalid strength value"
        let error = MnemonicError.invalidStrengthValue(message)
        
        #expect(error == MnemonicError.invalidStrengthValue(message))
        #expect(error != MnemonicError.invalidStrengthValue("Different message"))
    }
    
    @Test("Test MnemonicError.invalidWordlistLength")
    func testInvalidWordlistLengthError() {
        let message = "Invalid wordlist length"
        let error = MnemonicError.invalidWordlistLength(message)
        
        #expect(error == MnemonicError.invalidWordlistLength(message))
        #expect(error != MnemonicError.invalidWordlistLength("Different message"))
    }
    
    @Test("Test MnemonicError.languageNotDetected")
    func testLanguageNotDetectedError() {
        let message = "Language not detected"
        let error = MnemonicError.languageNotDetected(message)
        
        #expect(error == MnemonicError.languageNotDetected(message))
        #expect(error != MnemonicError.languageNotDetected("Different message"))
    }
    
    @Test("Test MnemonicError.unsupportedLanguage")
    func testUnsupportedLanguageError() {
        let message = "Unsupported language"
        let error = MnemonicError.unsupportedLanguage(message)
        
        #expect(error == MnemonicError.unsupportedLanguage(message))
        #expect(error != MnemonicError.unsupportedLanguage("Different message"))
    }
    
    @Test("Test MnemonicError.wordNotFound")
    func testWordNotFoundError() {
        let message = "Word not found in wordlist"
        let error = MnemonicError.wordNotFound(message)
        
        #expect(error == MnemonicError.wordNotFound(message))
        #expect(error != MnemonicError.wordNotFound("Different message"))
    }
    
    @Test("Test error cases with nil messages")
    func testErrorsWithNilMessages() {
        let error1 = MnemonicError.failedChecksum(nil)
        let error2 = MnemonicError.fileNotFound(nil)
        let error3 = MnemonicError.fileLoadFail(nil)
        let error4 = MnemonicError.invalidEntropy(nil)
        let error5 = MnemonicError.invalidSeedLength(nil)
        let error6 = MnemonicError.invalidStrengthValue(nil)
        let error7 = MnemonicError.invalidWordlistLength(nil)
        let error8 = MnemonicError.languageNotDetected(nil)
        let error9 = MnemonicError.unsupportedLanguage(nil)
        let error10 = MnemonicError.wordNotFound(nil)
        
        // Verify they can be created and are equatable with themselves
        #expect(error1 == MnemonicError.failedChecksum(nil))
        #expect(error2 == MnemonicError.fileNotFound(nil))
        #expect(error3 == MnemonicError.fileLoadFail(nil))
        #expect(error4 == MnemonicError.invalidEntropy(nil))
        #expect(error5 == MnemonicError.invalidSeedLength(nil))
        #expect(error6 == MnemonicError.invalidStrengthValue(nil))
        #expect(error7 == MnemonicError.invalidWordlistLength(nil))
        #expect(error8 == MnemonicError.languageNotDetected(nil))
        #expect(error9 == MnemonicError.unsupportedLanguage(nil))
        #expect(error10 == MnemonicError.wordNotFound(nil))
    }
}