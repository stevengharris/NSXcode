// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "MyProductCKNS",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "MyProductCKNS",
            targets: ["MyProductCKNS"]
        ),
        .library(
            name: "Module",
            type: .dynamic,
            targets: ["MyProductCKNS"]
        )
    ],
    dependencies: [
        .package(path: "../MyProductCKLib"),
        .package(path: "../../node-swift"),
    ],
    targets: [
        .target(
            name: "MyProductCKNS",
            dependencies: [
                .product(name: "MyProductCKLib", package: "MyProductCKLib"),
                .product(name: "NodeAPI", package: "node-swift"),
                .product(name: "NodeModuleSupport", package: "node-swift")
            ]
        ),
    ],
    swiftLanguageModes: [.v5, .v6],
    cxxLanguageStandard: .cxx17
)

