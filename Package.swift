// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "NewtonKit",
    products: [
        .executable(name: "newton", targets: ["newton"]),
        .library(name: "NewtonKit", targets: ["NewtonKit"]),
        .library(name: "NSOF", targets: ["NSOF"]),
        .library(name: "MNP", targets: ["MNP"]),
        .library(name: "NewtonDock", targets: ["NewtonDock"]),
    ],
    ],
    targets: [
        .target(name: "Extensions"),
        .target(name: "MNP", dependencies: ["Extensions"]),
        .target(name: "NSOF", dependencies: ["Extensions"]),
        .target(name: "NewtonDock", dependencies: ["Extensions", "NSOF"]),
        .target(name: "NewtonKit", dependencies: ["NSOF", "Extensions", "MNP", "NewtonDock"]),
        .target(name: "newton", dependencies: ["NewtonKit"]),
        .testTarget(name: "NewtonKitTests", dependencies: ["NewtonKit"])
    ]
)
