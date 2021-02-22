// swift-tools-version:5.3
import PackageDescription


let package = Package(
    name: "Differentiation Experiments",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(
            name: "Bounce",
            targets: ["Bounce"]
        ),
        .executable(
            name: "Opening",
            targets: ["Opening"]
        ),
        .executable(
            name: "Basics",
            targets: ["Basics"]
        )
    ],
    dependencies: [
        .package(
            name: "Plotly",
            url: "https://github.com/vojtamolda/Plotly.swift",
            from: "0.5.0"
        ),
    ],
    targets: [
        .target(
            name: "Bounce",
            dependencies: [
                .product(name: "Plotly", package: "Plotly"),
            ],
            exclude: [
                "Evolution.png", "Evolution.html",
                "Triangle Area.png", "Triangle Area.html"
            ]
        ),
        .target(
            name: "Opening",
            dependencies: [
                .product(name: "Plotly", package: "Plotly"),
            ],
            exclude: [
                "Derivative.png", "Derivative.html",
                "Curve Fitting.png", "Curve Fitting.html"
            ]
        ),
        .target(
            name: "Basics"
        ),
    ]
)
