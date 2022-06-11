// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "NewtonKit",
    products: [
        .executable(name: "newton",
                    targets: ["newton"]),
        .library(name: "NewtonKit",
                 targets: [
                    "NewtonKit",
                    "NSOF",
                    "NewtonCommon",
                    "MNP",
                    "NewtonDock",
                    "NewtonSerialPort",
                    "NewtonTranslators",
                    "NewtonServer"
                 ]),
        .library(name: "NSOF",
                 targets: ["NSOF"]),
        .library(name: "MNP",
                 targets: ["MNP"]),
        .library(name: "NewtonDock",
                 targets: ["NewtonDock"]),
        .library(name: "NewtonSerialPort",
                 targets: ["NewtonSerialPort"]),
        .library(name: "NewtonTranslators",
                 targets: ["NewtonTranslators"]),
        .library(name: "NewtonServer",
                 targets: ["NewtonServer"]),
        .library(name: "CDNS_SD", targets: ["CDNS_SD"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-html.git",
                 from: "0.4.0")
    ],
    targets: [
        .target(name: "NewtonCommon"),
        .target(name: "NewtonSerialPort",
                dependencies: ["NewtonCommon"]),
        .target(name: "MNP",
                dependencies: ["NewtonCommon"]),
        .target(name: "NSOF",
                dependencies: ["NewtonCommon"]),
        .target(name: "NewtonDock",
                dependencies: ["NewtonCommon", "NSOF"]),
        .target(name: "NewtonTranslators",
                dependencies: [
                    "NSOF",
                    .product(name: "Html",
                             package: "swift-html")
                ]),
        .target(name: "NewtonServer",
                dependencies: [
                    "NewtonCommon",
                    "CDNS_SD"
                ]),
        .target(name: "NewtonKit",
                dependencies: [
                    "NSOF",
                    "NewtonCommon",
                    "MNP",
                    "NewtonDock",
                    "NewtonSerialPort",
                    "NewtonTranslators",
                    "NewtonServer"
                ]),
        .executableTarget(name: "newton",
                          dependencies: ["NewtonKit"]),
        .systemLibrary(name: "CDNS_SD"),
        .testTarget(name: "MNPTests",
                    dependencies: ["MNP"]),
        .testTarget(name: "NSOFTests",
                    dependencies: ["NSOF"]),
        .testTarget(name: "NewtonDockTests",
                    dependencies: ["NewtonDock"]),
        .testTarget(name: "NewtonTranslatorsTests",
                    dependencies: ["NewtonTranslators"]),
    ]
)
