// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "NewtonKit",
    products: [
        .executable(name: "newton", targets: ["newton"]),
        .library(name: "NewtonKit", targets: ["NewtonKit", "NSOF", "MNP", "NewtonDock", "NewtonSerialPort"]),
        .library(name: "NSOF", targets: ["NSOF"]),
        .library(name: "MNP", targets: ["MNP"]),
        .library(name: "NewtonDock", targets: ["NewtonDock"]),
        .library(name: "NewtonSerialPort", targets: ["NewtonSerialPort"]),
        .library(name: "NewtonTranslators", targets: ["NewtonTranslators"]),
    ],
     dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-web.git", .revision("8cf59d3ede28ab6ed1b8ba7daad082267dd89a50")),
    ],
    targets: [
        .target(name: "Extensions"),
        .target(name: "NewtonSerialPort"),
        .target(name: "MNP", dependencies: ["Extensions"]),
        .target(name: "NSOF", dependencies: ["Extensions"]),
        .target(name: "NewtonDock", dependencies: ["Extensions", "NSOF"]),
        .target(name: "NewtonTranslators", dependencies: ["NSOF", "Html"]),
        .target(name: "NewtonKit", dependencies: ["NSOF", "Extensions", "MNP", "NewtonDock", "NewtonSerialPort", "NewtonTranslators"]),
        .target(name: "newton", dependencies: ["NewtonKit"]),
        .testTarget(name: "MNPTests", dependencies: ["MNP"]),
        .testTarget(name: "NSOFTests", dependencies: ["NSOF"]),
        .testTarget(name: "NewtonDockTests", dependencies: ["NewtonDock"]),
        .testTarget(name: "NewtonTranslatorsTests", dependencies: ["NewtonTranslators"]),
    ]
)
