import Foundation
import Base58Swift

public extension Data {
    init(fromHex: String) {
        self.init()
        var hex = fromHex
        while hex.count > 0 {
            let c = String(hex.prefix(2))
            hex = String(hex.dropFirst(2))
            self.append(UInt8(c, radix: 16)!)
        }
    }

    func base58EncodedString() -> String {
        return Base58.base58Encode(Array(self))
    }
    
    func hexEncodedString() -> String {
        return map { String(format: "%02x", $0) }.joined()
    }
}
