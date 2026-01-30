// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "interchange",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "Interchange",
            targets: ["Interchange"]),
    ],
    dependencies: [
        .package(url: "https://github.com/WeTransfer/Mocker", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "Interchange"
        ),
        .testTarget(
            name: "InterchangeTests",
            dependencies: ["Interchange", "Mocker"]),
    ]
)
