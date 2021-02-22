// swift-tools-version:5.3
import PackageDescription


let package = Package(
    name: "Differentiation Experiments",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(
            name: "Opening",
            targets: ["Opening"]
        ),
        .executable(
            name: "Basics",
            targets: ["Basics"]
        )
    ],
    targets: [
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
