// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "RESTWebService",
    platforms: [
        .iOS("16.0"),
        .macOS("13.0")
    ],
    products: [
        .library(
            name: "RESTWebService",
            targets: ["RESTWebService"]),
    ],
    dependencies: [
        .package(url: "https://github.com/WeTransfer/Mocker.git", from: "2.7.0"),
        .package(url: "https://github.com/antarianLogic/date-utils.git", from: "0.2.0"),
        .package(url: "https://github.com/antarianLogic/al-telemetry.git", from: "1.0.3")
    ],
    targets: [
        .target(
            name: "RESTWebService",
            dependencies: [
                .product(name: "DateUtils", package: "date-utils"),
                .product(name: "ALTelemetryProtocol", package: "al-telemetry")]
        ),
        .testTarget(
            name: "RESTWebServiceTests",
            dependencies: ["RESTWebService", "Mocker"]),
    ]
)
