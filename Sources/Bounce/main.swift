import _Differentiation


// MARK: - Initial Condition

/// Balls that form a triangle.
let balls = [
    World.Ball(position: .zero, velocity: .zero),
    World.Ball(position: .unitX, velocity: .zero),
    World.Ball(position: .unitY, velocity: .zero)
]
/// Springs that form vertices of a triangle.
var springs = [
    World.Spring(freeLength: 1.0, stiffness: 1.0, damping: 1.0, attached: (from: 0, to: 1)),
    World.Spring(freeLength: 2.0.squareRoot(), stiffness: 1.0, damping: 1.0, attached: (from: 1, to: 2)),
    World.Spring(freeLength: 1.0, stiffness: 1.0, damping: 1.0, attached: (from: 2, to: 0))
]


// MARK: - Objective

extension World {
    /// Area of the triangle formed by the first 3 balls.
    @differentiable(reverse)
    var area: Double {
        let base = balls[0].position - balls[1].position
        let side = balls[2].position - balls[0].position
        let height = base.perpendicular • side
        return 0.5 * height * base.magnitude
    }
}

/// Calculates mean-squared-error of a triangle area and the the target `area` evaluated after 5 s of simulation time.
@differentiable(reverse)
func areaAtEndOfSimulationMSE(_ initialWorld: World, target area: Double) -> Double {
    let terminalWorld = initialWorld.evolved(until: 5.0)
    return (terminalWorld.area - area) * (terminalWorld.area - area)
}


// MARK: - Optimization via Gradient Descent

let α = 0.1
let desiredArea = 0.1
var losses = [Double]()
for _ in 0 ..< 50 {
    let world = World(balls: balls, springs: springs, time: 0)
    
    let (loss, 𝛁world) = valueWithGradient(at: world) { world -> Double in
        return areaAtEndOfSimulationMSE(world, target: desiredArea)
    }

    for i in 0 ..< springs.count {
        springs[i].freeLength -= α * 𝛁world.springs[i].freeLength
    }
    
    losses.append(loss)
}


// MARK: - Result

var world = World(balls: balls, springs: springs, time: 0.0)
var evolution = [world]
while world.time < 5.0 {
    world = world.evolved()
    evolution.append(world)
}

try evolution.animationChart.show()
try evolution.animationChart.write(toFile: "Evolution.html")

try evolution.areaChart.show()
try evolution.areaChart.write(toFile: "Triangle Area.html")
