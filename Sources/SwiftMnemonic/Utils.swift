import Foundation
import SwiftBase58

/// Utility extensions for Data type to handle hex and Base58 encoding/decoding.
public extension Data {
    
    /// Initialize Data from a hexadecimal string.
    /// - Throws: `MnemonicError.invalidHex` if the string has odd length or a character outside `[0-9a-fA-F]`.
    init(fromHex hex: String) throws {
        let utf8 = Array(hex.utf8)
        guard utf8.count % 2 == 0 else {
            throw MnemonicError.invalidHex("Hex string has odd length: \(utf8.count)")
        }
        func nibble(_ c: UInt8) -> UInt8? {
            switch c {
            case 0x30...0x39: return c - 0x30
            case 0x41...0x46: return c - 0x37
            case 0x61...0x66: return c - 0x57
            default: return nil
            }
        }
        var bytes = [UInt8]()
        bytes.reserveCapacity(utf8.count / 2)
        for i in stride(from: 0, to: utf8.count, by: 2) {
            guard let hi = nibble(utf8[i]), let lo = nibble(utf8[i + 1]) else {
                throw MnemonicError.invalidHex("Invalid hex character at offset \(i)")
            }
            bytes.append(hi << 4 | lo)
        }
        self.init(bytes)
    }

    /// Encode the given bytes to a Base58 encoded string.
    func base58EncodedString() -> String {
        return Base58.base58Encode(Array(self))
    }
    
    /// Encode the given bytes to a hexadecimal string.
    func hexEncodedString() -> String {
        return map { String(format: "%02x", $0) }.joined()
    }
}
