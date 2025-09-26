import Foundation
@testable import SwiftMnemonic

// MARK: - Test Helpers

/// Generates random data with the specified length for testing purposes.
func generateRandomData(length: Int) -> Data {
    return Data((0..<length).map { _ in UInt8.random(in: 0...255) })
}

/// Creates a temporary directory for file operations during tests.
func createTemporaryDirectory() -> URL {
    let tempDir = FileManager.default.temporaryDirectory
    let testDir = tempDir.appendingPathComponent(UUID().uuidString)
    try! FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
    return testDir
}

/// Removes a temporary directory after tests complete.
func removeTemporaryDirectory(_ url: URL) {
    try? FileManager.default.removeItem(at: url)
}

/// Creates a temporary wordlist file with the specified content.
func createTemporaryWordlistFile(content: String, in directory: URL, filename: String = "test.txt") -> URL {
    let fileURL = directory.appendingPathComponent(filename)
    try! content.write(to: fileURL, atomically: true, encoding: .utf8)
    return fileURL
}

/// Validates that two arrays contain the same elements regardless of order.
func assertArraysContainSameElements<T: Equatable>(_ array1: [T], _ array2: [T], file: StaticString = #file, line: UInt = #line) {
    let set1 = Set(array1.map { "\($0)" })
    let set2 = Set(array2.map { "\($0)" })
    assert(set1 == set2, "Arrays do not contain the same elements", file: file, line: line)
}

/// Test constants
struct TestConstants {
    static let validEntropy16 = Data([0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff])
    static let validEntropy32 = Data([
        0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff,
        0x01, 0x12, 0x23, 0x34, 0x45, 0x56, 0x67, 0x78, 0x89, 0x9a, 0xab, 0xbc, 0xcd, 0xde, 0xef, 0xf0
    ])
    static let invalidEntropy15 = Data([0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee])
    static let invalidEntropy33 = Data(Array(0x00...0x20))
    
    static let validMnemonic12 = ["abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "about"]
    static let invalidMnemonic11 = ["abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon"]
    static let invalidMnemonic13 = ["abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "about", "excess"]
    
    // Custom wordlist with exactly 2048 words (we'll generate it)
    static func createValidWordlist() -> [String] {
        return (0..<2048).map { "word\($0)" }
    }
    
    // Custom wordlist with wrong number of words
    static func createInvalidWordlist() -> [String] {
        return (0..<2047).map { "word\($0)" }
    }
}