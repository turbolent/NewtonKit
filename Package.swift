// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "newch",
    products: [
        .executable(name: "newch-cli", targets: ["newch-cli"]),
        .library(name: "newch", targets: ["newch"]),
    ],
    targets: [
        .target(name: "newch"),
        .target(name: "newch-cli", dependencies: ["newch"]),
        .testTarget(name: "newchTests", dependencies: ["newch"])
    ]
)
