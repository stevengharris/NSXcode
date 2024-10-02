// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "MyProductNS",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "MyProductNS",
            targets: ["MyProductNS"]
        ),
        .library(
            name: "Module",
            type: .dynamic,
            targets: ["MyProductNS"]
        )
    ],
    dependencies: [
        .package(path: "../MyProductLib"),
        .package(path: "../../node-swift"),
    ],
    targets: [
        .target(
            name: "MyProductNS",
            dependencies: [
                .product(name: "MyProductLib", package: "MyProductLib"),
                .product(name: "NodeAPI", package: "node-swift"),
                .product(name: "NodeModuleSupport", package: "node-swift")
            ]
        ),
    ],
    swiftLanguageModes: [.v5, .v6],
    cxxLanguageStandard: .cxx17
)

