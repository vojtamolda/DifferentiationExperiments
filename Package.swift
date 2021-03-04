// swift-tools-version:5.3
import PackageDescription


let package = Package(
    name: "Differentiation Experiments",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(
            name: "Billiard",
            targets: ["Billiard"]
        ),
        .executable(
            name: "Wave",
            targets: ["Wave"]
        ),
        .executable(
            name: "RK4",
            targets: ["RK4"]
        ),
        .executable(
            name: "Trapz",
            targets: ["Trapz"]
        ),
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
        .package(
            name: "Swim",
            url: "https://github.com/t-ae/Swim",
            from: "3.9.0"
        )
    ],
    targets: [
        .target(
            name: "Animals",
            dependencies: [
                .product(name: "Plotly", package: "Plotly")
            ],
            exclude: [
                "Animal.png",
            ]
        ),
        .target(
            name: "Billiard",
            exclude: [
                "Example.svg"
            ]
        ),
        .target(
            name: "Wave",
            dependencies: [
                .product(name: "Plotly", package: "Plotly"),
                .product(name: "Swim", package: "Swim"),
            ],
            exclude: [
                "Target.png",
                "Splash.gif",
                "Optimization.gif"
            ]
        ),
        .target(
            name: "RK4",
            dependencies: [
                .product(name: "Plotly", package: "Plotly"),
            ],
            exclude: [
                "Figure 1.png", "Figure 1.html",
                "Figure 2.png", "Figure 2.html"
            ]
        ),
        .target(
            name: "Trapz",
            dependencies: [
                .product(name: "Plotly", package: "Plotly"),
            ],
            exclude: [
                "Example 1.png", "Example 1.html",
                "Example 2.png", "Example 2.html"
            ]
        ),
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
        )
    ]
)
