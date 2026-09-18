// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "T3HUD",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "T3HUD", targets: ["T3HUD"])],
    targets: [
        .target(name: "T3HUDCore"),
        .executableTarget(name: "T3HUD", dependencies: ["T3HUDCore"])
    ]
)
