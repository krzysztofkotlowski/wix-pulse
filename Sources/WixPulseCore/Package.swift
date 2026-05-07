// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WixPulseCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "WixPulseCore", targets: ["WixPulseCore"])
    ],
    targets: [
        .target(name: "WixPulseCore", path: "Sources/WixPulseCore"),
        .testTarget(name: "WixPulseCoreTests", dependencies: ["WixPulseCore"], path: "Tests/WixPulseCoreTests")
    ]
)
