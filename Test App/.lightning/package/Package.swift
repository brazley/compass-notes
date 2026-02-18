// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LightningApp",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "/Users/quikolas/github/Compass/Lightning")
    ],
    targets: [
        .executableTarget(
            name: "LightningApp",
            dependencies: [
                .product(name: "Lightning", package: "Lightning")
            ]
        )
    ]
)