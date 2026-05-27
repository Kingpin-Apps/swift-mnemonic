import Foundation
import Crypto

/// PBKDF2 key derivation using HMAC-SHA512 as the PRF, per RFC 2898 §5.2.
///
/// Implemented in-package because swift-crypto's `KDF.Insecure.PBKDF2` lives in
/// `_CryptoExtras`, which does not build for WebAssembly (it depends on
/// thread-local APIs unavailable on WASI).
enum PBKDF2 {
    static func deriveKeyHMACSHA512(
        password: [UInt8],
        salt: [UInt8],
        iterations: Int,
        keyLength: Int
    ) -> [UInt8] {
        precondition(iterations >= 1)
        precondition(keyLength >= 1)

        let hLen = SHA512.byteCount
        let blockCount = (keyLength + hLen - 1) / hLen
        let key = SymmetricKey(data: password)

        var derivedKey = [UInt8]()
        derivedKey.reserveCapacity(blockCount * hLen)

        for blockIndex in 1...blockCount {
            var seed = salt
            seed.append(UInt8((blockIndex >> 24) & 0xff))
            seed.append(UInt8((blockIndex >> 16) & 0xff))
            seed.append(UInt8((blockIndex >> 8) & 0xff))
            seed.append(UInt8(blockIndex & 0xff))

            var u = Array(HMAC<SHA512>.authenticationCode(for: seed, using: key))
            var block = u

            for _ in 1..<iterations {
                u = Array(HMAC<SHA512>.authenticationCode(for: u, using: key))
                for i in 0..<hLen {
                    block[i] ^= u[i]
                }
            }

            derivedKey.append(contentsOf: block)
        }

        return Array(derivedKey.prefix(keyLength))
    }
}
