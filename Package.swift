// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "rest-web-service",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "RESTWebService",
            targets: ["RESTWebService"]),
    ],
    dependencies: [
        .package(url: "https://github.com/WeTransfer/Mocker.git", from: "3.0.0"),
        .package(url: "https://github.com/antarianLogic/date-utils.git", from: "0.3.0")
    ],
    targets: [
        .target(
            name: "RESTWebService",
            dependencies: [.product(name: "DateUtils", package: "date-utils")]
//            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
        ),
        .testTarget(
            name: "RESTWebServiceTests",
            dependencies: ["RESTWebService", "Mocker"]),
    ]
)
