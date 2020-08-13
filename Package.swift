// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ClassyFlux",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v11),
        .watchOS(.v4),
        .tvOS(.v11)
    ],
    products: [
        .library(name: "ClassyFlux", targets: ["ClassyFlux"])
    ],
    dependencies: [
        .package(url: "https://github.com/kzlekk/ResolverContainer.git", , from: "1.3.0"),
    ],
    targets: [
        .target(name: "ClassyFlux", dependencies: ["ResolverContainer"], path: "Flux")
    ],
    swiftLanguageVersions: [ .v5 ]
)
