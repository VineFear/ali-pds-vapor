// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ali-pds-vapor",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AliPdsVapor",
            targets: ["AliPdsVapor"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/VineFear/ali-pds-kit.git", from: "0.0.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "AliPdsVapor",
            dependencies: [
                .product(name: "AliPDSCore", package: "ali-pds-kit"),
                .product(name: "Vapor", package: "vapor"),
            ]),
        // Demo
        .executableTarget(name: "Run", dependencies: [.target(name: "AliPdsVapor")]),
        .testTarget(
            name: "ali-pds-vaporTests",
            dependencies: ["AliPdsVapor"]),
    ]
)
