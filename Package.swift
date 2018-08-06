// swift-tools-version:4.0
import PackageDescription


#if os(iOS) || os(macOS)
    let cdns_sd = "CDNS_Services"
#else
    let cdns_sd = "CDNS_SD"
#endif


let package = Package(
    name: "NewtonKit",
    products: [
        .executable(name: "newton",
                    targets: ["newton"]),
        .library(name: "NewtonKit",
                 targets: [
                    "NewtonKit", "NSOF", "MNP",
                    "NewtonDock", "NewtonSerialPort"
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
                 targets: ["NewtonServer"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-web.git", .branch(name: "master")),
        .package(url: "https://github.com/rhx/\(cdns_sd).git", .upToNextMinor(from: "1.0.0"))
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
                dependencies: ["NSOF", "Html"]),
        .target(name: "NewtonServer",
                dependencies: ["NewtonCommon"]),
        .target(name: "NewtonKit",
                dependencies: [
                    "NSOF", "NewtonCommon", "MNP", "NewtonDock",
                    "NewtonSerialPort", "NewtonTranslators", "NewtonServer"
                ]),
        .target(name: "newton",
                dependencies: ["NewtonKit"]),
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
