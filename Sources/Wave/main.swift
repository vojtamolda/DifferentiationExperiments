import _Differentiation
import Foundation
import Swim


// FIXME: Replace these with 32 and 8 if you don't want to get old waiting for results...
let resolution = 256
let duration = 128


// MARK: - Splash

func splash() throws {
    let waterLevelRow = [Float](repeating: 0.0, count: resolution)
    var initialWaterLevel = [[Float]](repeating: waterLevelRow, count: resolution)
    initialWaterLevel[resolution / 2][resolution / 2] = 100

    let initialSolution = Solution(waterLevel: initialWaterLevel)
    let evolution = [Solution](evolve: initialSolution, for: duration)
    
    var visualization = evolution.visualization
    try visualization.waterSchlieren.write(to: URL(fileURLWithPath: "Splash.gif"))
    visualization.interval = 8
    try visualization.waterLevel.show()
}

try splash()


// MARK: - Optimization

func optimization() throws {
    let waterLevelRow = [Float](repeating: 0.0, count: resolution)
    var initialWaterLevel = [[Float]](repeating: waterLevelRow, count: resolution)

    var target = try Image<RGB, Float>(contentsOf: URL(fileURLWithPath: "Target.png")).toGray()
    target = target.flipUD().resize(width: resolution, height: resolution)
    let mean = target.pixels().map(\.color[.gray]).reduce(0, +) / Float(target.pixelCount)
    target.dataConvert { $0 - mean }

    let alpha: Float = 5.0
    for opt in 1 ... 50 {
        let (loss, 𝛁initialWaterLevel) = valueWithGradient(at: initialWaterLevel) { (initialWaterLevel) -> Float in
            let initialSolution = Solution(waterLevel: initialWaterLevel)
            let evolution = [Solution](evolve: initialSolution, for: duration)
            let last = withoutDerivative(at: evolution.count - 1)
            let loss = evolution[last].meanSquaredError(to: target)
            return -alpha * loss
        }
        print("\(opt): \(loss)")

        initialWaterLevel.move(by: 𝛁initialWaterLevel)
    }

    let initialSolution = Solution(waterLevel: initialWaterLevel)
    let evolution = [Solution](evolve: initialSolution, for: duration)
    
    var visualization = evolution.visualization
    try visualization.waterSchlieren.write(to: URL(fileURLWithPath: "Optimization.gif"))
    visualization.interval = 8
    try visualization.waterLevel.show()
    try visualization.waterSurface.show()
}

try optimization()
