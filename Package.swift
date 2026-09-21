// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AgentBar",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "AgentBar",
            path: "Sources/AgentBar",
            resources: [.process("Resources")],
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
        .testTarget(
            name: "AgentBarTests",
            dependencies: ["AgentBar"],
            path: "Tests/AgentBarTests",
            resources: [.copy("Fixtures")]
        ),
    ]
)
