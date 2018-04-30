// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "NewtonKit",
    products: [
        .executable(name: "newton", targets: ["newton"]),
        .library(name: "NewtonKit", targets: ["NewtonKit"]),
    ],
    targets: [
        .target(name: "Extensions"),
        .target(name: "NSOF", dependencies: ["Extensions"]),
        .target(name: "NewtonKit", dependencies: ["NSOF", "Extensions"]),
        .target(name: "newton", dependencies: ["NewtonKit"]),
        .testTarget(name: "NewtonKitTests", dependencies: ["NewtonKit"])
    ]
)
