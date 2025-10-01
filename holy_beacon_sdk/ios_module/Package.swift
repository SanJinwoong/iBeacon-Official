// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HolyBeaconCore",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_14),
        .watchOS(.v5),
        .tvOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "HolyBeaconCore",
            targets: ["HolyBeaconCore"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        .target(
            name: "HolyBeaconCore",
            dependencies: [],
            path: "Sources/HolyBeaconCore"
        ),
        .testTarget(
            name: "HolyBeaconCoreTests",
            dependencies: ["HolyBeaconCore"],
            path: "Tests/HolyBeaconCoreTests"
        ),
    ]
)