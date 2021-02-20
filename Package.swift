// swift-tools-version:5.3
import PackageDescription


let package = Package(
    name: "Differentiation Experiments",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(
            name: "Basics",
            targets: ["Basics"]
        )
    ],
    targets: [
        .target(
            name: "Basics"
        ),
    ]
)
