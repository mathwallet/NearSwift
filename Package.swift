// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NearSwift",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "NearSwift",
            targets: ["NearSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.4.2"),
        .package(name: "Secp256k1Swift", url: "https://github.com/mathwallet/Secp256k1Swift.git", from: "1.2.6"),
        .package(name: "Base58Swift", url: "https://github.com/mathwallet/Base58Swift.git", from: "0.0.1"),
        .package(name: "TweetNacl", url: "https://github.com/lishuailibertine/tweetnacl-swiftwrap", from: "1.0.3"),
        .package(url: "https://github.com/Flight-School/AnyCodable.git", .exact("0.6.0")),
        .package(url: "https://github.com/mxcl/PromiseKit.git", from: "6.16.2")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "NearSwift",
            dependencies: [
                "Base58Swift",
                "CryptoSwift",
                "Secp256k1Swift",
                "TweetNacl",
                "AnyCodable",
                "PromiseKit"
            ]),
        .testTarget(
            name: "NearSwiftTests",
            dependencies: ["NearSwift"]),
    ]
)
