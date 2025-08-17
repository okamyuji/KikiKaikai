// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KikiKaikai",
    platforms: [
        .macOS(.v12)
    ],
    targets: [
        .executableTarget(
            name: "KikiKaikai",
            dependencies: [],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "KikiKaikaiTests",
            dependencies: ["KikiKaikai"]
        )
    ]
)
