import Foundation
import SwiftBase58

/// Utility extensions for Data type to handle hex and Base58 encoding/decoding.
public extension Data {
    
    /// Initialize Data from a hexadecimal string.
    init(fromHex: String) {
        self.init()
        var hex = fromHex
        while hex.count > 0 {
            let c = String(hex.prefix(2))
            hex = String(hex.dropFirst(2))
            self.append(UInt8(c, radix: 16)!)
        }
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
