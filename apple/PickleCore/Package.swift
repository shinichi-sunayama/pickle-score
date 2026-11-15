// swift-tools-version:5.9
// Score-calling rules shared by the iPhone and Apple Watch apps (port of web/core.js and web/history.js).
// Tests read the same tests/cases.json as the web tests.
import PackageDescription

let package = Package(
    name: "PickleCore",
    platforms: [.iOS(.v17), .watchOS(.v10), .macOS(.v14)],
    products: [
        .library(name: "PickleCore", targets: ["PickleCore"]),
    ],
    targets: [
        .target(name: "PickleCore"),
        .testTarget(name: "PickleCoreTests", dependencies: ["PickleCore"]),
    ]
)
