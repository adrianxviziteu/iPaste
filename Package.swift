// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "iPaste",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "iPaste",
            path: "Sources/iPaste",
            swiftSettings: [.swiftLanguageMode(.v5)],
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("Vision"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("Network")
            ]
        )
    ]
)
