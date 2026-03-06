// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Rewrite",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey.git", from: "0.2.1")
    ],
    targets: [
        .executableTarget(
            name: "Rewrite",
            dependencies: ["HotKey"],
            path: "Sources/Rewrite",
            exclude: ["Resources/Info.plist"]
        )
    ]
)
