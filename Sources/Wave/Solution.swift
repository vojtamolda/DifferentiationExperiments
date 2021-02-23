import _Differentiation
import Foundation
import Swim


// MARK: Solution of shallow water equation

/// Differentiable solution of shallow water equation on a unit square.
///
/// Shallow water equation is a type of hyperbolic partial differential equation (PDE). This struct
/// represents its solution calculated with finite-difference discretization on a 2D plane and at a
/// particular point in time.
///
/// More details about the shallow water PDE can found for example on
/// [Wikipedia](https://en.wikipedia.org/wiki/Shallow_water_equations)
///
/// # Domain and Discretization
/// The PDE is solved on a `<0,1>x<0,1>` square discretized with spatial step of size `Δx`.
/// Laplace operator is approximated with five-point stencil finite-differencing.
///
/// Temporal advancing uses semi implicit Euler's schema. Time step `Δt` is calculated from
/// `Δx` to stay below the Courant–Friedrichs–Lewy numerical stability limit.
///
/// # Boundary Conditions
/// Values around the edges of the domain are subject to trivial Dirichlet boundary conditions
/// (i.e. equal to 0 with an arbitrary gradient).
///
/// # Laplace Operator Δ
/// Discretization of the operator is implemented as tight loops over the water height field.
/// This is a very naive but natural implementation that serves as a performance baseline
/// on the CPU.
///
struct Solution: Differentiable {
    /// Water level height
    var waterLevel: [[Float]] { u1 }
    /// Solution time
    var time: Float { t }

    /// Height of the water surface at time `t`
    private var u1: [[Float]]
    /// Height of the water surface at previous time-step `t - Δt`
    private var u0: [[Float]]
    /// Solution time
    @noDerivative private let t: Float
    /// Speed of sound
    @noDerivative private let c: Float = 340.0
    /// Dispersion coefficient
    @noDerivative private let α: Float = 0.001
    /// Number of spatial grid points
    @noDerivative private let resolution: Int
    /// Spatial discretization step
    @noDerivative private var Δx: Float { 1 / Float(resolution) }
    /// Time-step calculated to stay below the CFL stability limit
    @noDerivative private var Δt: Float { (sqrt(α * α + Δx * Δx / 3) - α) / c }

    /// Creates initial solution with water level `u0` at time `t`.
    @differentiable(reverse)
    init(waterLevel u0: [[Float]], time t: Float = 0.0) {
        self.resolution = u0.count
        self.u0 = u0
        self.u1 = u0
        self.t = t

        precondition(u0.count == resolution)
        precondition(u0.allSatisfy { $0.count == resolution })
    }

    /// Calculates solution stepped forward by one time-step `Δt`.
    ///
    /// - `u0` - Water surface height at previous time step
    /// - `u1` - Water surface height at current time step
    /// - `u2` - Water surface height at next time step (calculated)
    @differentiable(reverse)
    func evolved() -> Solution {
        var u2 = u1

        for x in 1 ..< resolution - 1 {
            for y in 1 ..< resolution - 1 {
                // FIXME: Should be u2[x][y] = ...
                u2.updated(x, y, with: 2 * u1[x][y] +
                    (c * c * Δt * Δt + c * α * Δt) * Δ(u1, x, y) -
                    u0[x][y] - c * α * Δt * Δ(u0, x, y)
                )
            }
        }

        return Solution(u0: u1, u1: u2, t: t + Δt)
    }
    
    /// Constructs intermediate solution with previous water level `u0`, current water level `u1` and time `t`.
    @differentiable(reverse, wrt: (u0, u1))
    private init(u0: [[Float]], u1: [[Float]], t: Float) {
        self.resolution = u0.count
        self.u0 = u0
        self.u1 = u1
        self.t = t
        
        precondition(u0.count == self.resolution)
        precondition(u0.allSatisfy { $0.count == self.resolution })
        precondition(u1.count == self.resolution)
        precondition(u1.allSatisfy { $0.count == self.resolution })
    }

    /// Applies discretized Laplace operator to scalar field `u` at grid points `x` and `y`.
    @differentiable(reverse)
    private func Δ(_ u: [[Float]], _ x: Int, _ y: Int) -> Float {
        (                u[x][y + 1]
        + u[x - 1][y] - (4 * u[x][y]) + u[x + 1][y] +
                         u[x][y - 1]                ) / Δx / Δx
    }
}


// MARK: - Cost calculated as mean L2 distance to a target image

extension Solution {
    /// Calculates mean squared error loss between the solution and a `target` grayscale image.
    @differentiable(reverse, wrt: self)
    func meanSquaredError(to target: Swim.Image<Gray, Float>) -> Float {
        precondition(target.width == resolution && target.height == resolution)

        var mse: Float = 0.0
        for x in 0 ..< resolution {
            for y in 0 ..< resolution {
                let error = target[x, y][.gray] - u1[x][y]
                mse += error * error * Δx * Δx
            }
        }
        return mse
    }
}


// MARK: - Evolution of the solution in time

extension Array where Element == Solution {
    
    /// Creates an array of shallow water equation solutions by evolving the `initialSolution` forward `numSteps`-times.
    @differentiable(reverse)
    init(evolve initialSolution: Element, for numSteps: Int) {
        self.init()
        
        var currentSolution = initialSolution
        for _ in 0..<numSteps {
            self.append(currentSolution)
            currentSolution = currentSolution.evolved()
        }
        self.append(currentSolution)
    }
}
