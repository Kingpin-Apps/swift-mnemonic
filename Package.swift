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
        .package(url: "https://github.com/tesseract-one/UncommonCrypto.swift.git",
                 .upToNextMinor(from: "0.2.0")),
        .package(url: "https://github.com/heckj/Base58Swift.git", from: "2.1.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftMnemonic",
            dependencies: [
                .product(name: "UncommonCrypto", package: "UncommonCrypto.swift"),
                .product(name: "Base58Swift", package: "Base58Swift")
            ],
            resources: [
               .copy("wordlist")
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
