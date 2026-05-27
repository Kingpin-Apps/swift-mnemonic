// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftMnemonic",
    platforms: [
      .iOS(.v14),
      .macOS(.v11),
      .watchOS(.v7),
      .tvOS(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftMnemonic",
            targets: ["SwiftMnemonic"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.15.1"),
        .package(url: "https://github.com/Kingpin-Apps/swift-base58.git", from: "0.1.3")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftMnemonic",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "SwiftBase58", package: "swift-base58")
            ],
            resources: [
                .embedInCode("wordlist/chinese_simplified.txt"),
                .embedInCode("wordlist/chinese_traditional.txt"),
                .embedInCode("wordlist/czech.txt"),
                .embedInCode("wordlist/english.txt"),
                .embedInCode("wordlist/french.txt"),
                .embedInCode("wordlist/italian.txt"),
                .embedInCode("wordlist/japanese.txt"),
                .embedInCode("wordlist/korean.txt"),
                .embedInCode("wordlist/portuguese.txt"),
                .embedInCode("wordlist/russian.txt"),
                .embedInCode("wordlist/spanish.txt"),
                .embedInCode("wordlist/turkish.txt"),
            ]
        ),
        .testTarget(
            name: "SwiftMnemonicTests",
            dependencies: ["SwiftMnemonic"],
            resources: [
               .copy("data")
           ]
        ),
    ]
)
