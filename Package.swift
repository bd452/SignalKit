// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SignalKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v13),
        .macCatalyst(.v15),
    ],
    products: [
        .library(
            name: "SignalKit",
            targets: ["SignalKit"]
        ),
    ],
    targets: [
        .target(
            name: "SignalKit"
        ),
        .testTarget(
            name: "SignalKitTests",
            dependencies: ["SignalKit"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
