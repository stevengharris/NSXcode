// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "MyProductLib",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "MyProductLib",
            targets: ["MyProductLib"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MyProductLib",
            dependencies: []
        ),
    ],
    swiftLanguageModes: [.v5, .v6],
    cxxLanguageStandard: .cxx17
)
