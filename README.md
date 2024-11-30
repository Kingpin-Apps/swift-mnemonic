![GitHub Workflow Status](https://github.com/Kingpin-Apps/swift-mnemonic/actions/workflows/swift.yml/badge.svg)

# SwiftMnemonic - Reference implementation of BIP-0039: Mnemonic code for generating deterministic keys

SwiftMnemonic is an implementation of BIP39 in Swift. It supports 12 languages specified in the BIP39 standard.

## Usage
To add SwiftMnemonic as dependency to your Xcode project, select `File` > `Swift Packages` > `Add Package Dependency`, enter its repository URL: `https://github.com/Kingpin-Apps/swift-mnemonic.git` and import `SwiftMnemonic`.

Then, to use it in your source code, add:

```swift
import SwiftMnemonic
            
let mnemonic = try Mnemonic(language: .english)
let phrase = try mnemonic.generate(wordCount: .twentyFour)
```

## Available Languages
- [x] Chinese (Simplified)
- [x] Chinese (Traditional)
- [x] Czech
- [x] English
- [x] French
- [x] Italian
- [x] Japanese
- [x] Korean
- [x] Portuguese
- [x] Russian
- [x] Spanish
- [x] Turkish