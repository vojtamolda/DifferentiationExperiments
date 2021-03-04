import _Differentiation
import Foundation


// MARK: Helpers

typealias Vector2 = Vec2
let iterationCount = 100

let maxLr = Float(1e-1)
let minLr = Float(1e-2)

func learningRate(_ i: Int = 0) -> Float {
    return (maxLr - minLr) * (cos(Float.pi * Float(i) / Float(iterationCount)) + 1) / 2 + minLr
}

extension Array where Element == Float {
    @differentiable(reverse)
    func sum() -> Float {
        differentiableReduce(0, +)
    }
}

// MARK: Cell 1

@differentiable(reverse)
func simulate(_ initialState: World) -> World {
    var state = initialState
    while !state.still {
        state = state.stepped()
    }
    return state
}

// MARK: Cell 2

var v0 = Vector2(20, 0.01)
drawSimulation(file: "Example.svg", ball1InitialVelocity: v0)

// MARK: Cell 3

@differentiable(reverse)
func loss(_ v0: Vector2) -> Float {
    // Initialize a world with the given initial velocity.
    let initialState = World(ball1InitialVelocity: v0)
    
    // Simulate the world forwards to the final state.
    let finalState = simulate(initialState)
    
    // Sum the closest approaches to the targets.
    return finalState.targetDistances.sum()
}

let l0 = loss(v0)
print(l0)

// MARK: Cell 4

let grad = gradient(at: v0, of: loss)
drawGradients(file: "Gradient.svg", ball1InitialVelocity: v0, grad: grad)
v0 -= learningRate() * grad

// MARK: Cell 5

drawSimulation(file: "Initial.svg", ball1InitialVelocity: v0)

// MARK: Cell 6

for i in 0..<iterationCount {
    let (loss0, grad) = valueWithGradient(at: v0, of: loss)
    print("\(i): loss \(loss0)")
    v0 -= learningRate(i) * grad
}

// MARK: Cell 7

drawSimulation(file: "Optimized.svg", ball1InitialVelocity: v0)
