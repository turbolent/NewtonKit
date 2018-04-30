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
        .library(name: "NewtonSerialPort", targets: ["NewtonSerialPort"]),
    ],
    ],
    targets: [
        .target(name: "Extensions"),
        .target(name: "NewtonSerialPort"),
        .target(name: "MNP", dependencies: ["Extensions"]),
        .target(name: "NSOF", dependencies: ["Extensions"]),
        .target(name: "NewtonDock", dependencies: ["Extensions", "NSOF"]),
        .target(name: "NewtonKit", dependencies: ["NSOF", "Extensions", "MNP", "NewtonDock", "NewtonSerialPort"]),
        .target(name: "newton", dependencies: ["NewtonKit"]),
        .testTarget(name: "MNPTests", dependencies: ["MNP"]),
        .testTarget(name: "NSOFTests", dependencies: ["NSOF"]),
        .testTarget(name: "NewtonDockTests", dependencies: ["NewtonDock"]),
    ]
)
