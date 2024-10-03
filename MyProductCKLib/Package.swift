// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "MyProductCKLib",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "MyProductCKLib",
            targets: ["MyProductCKLib"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MyProductCKLib",
            dependencies: []
        ),
    ],
    swiftLanguageModes: [.v5, .v6],
    cxxLanguageStandard: .cxx17
)
