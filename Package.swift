// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AIUsageLimits",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "AIUsageLimits",
            path: "Sources/AIUsageLimits",
            resources: [.process("Resources")],
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
        .testTarget(
            name: "AIUsageLimitsTests",
            dependencies: ["AIUsageLimits"],
            path: "Tests/AIUsageLimitsTests",
            resources: [.copy("Fixtures")]
        ),
    ]
)
