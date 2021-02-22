import _Differentiation
import Plotly


/// State of a simple world consisting of balls attached to springs embedded in the 2D plane.
struct World: Differentiable {
    
    /// State of a mass point.
    struct Ball: Differentiable {
        /// Mass of the ball
        var mass: Double = 1.0
        /// Current position of the ball.
        var position: Vector
        /// Current speed of the ball.
        var velocity: Vector
    }
    /// Balls that exist in the world.
    var balls: [Ball]

    /// State of a spring attached to two balls.
    struct Spring: Differentiable {
        /// Length of the spring when there are no forces acting on it.
        var freeLength: Double
        /// Resistance of the spring to compression and extension.
        var stiffness: Double
        /// Internal damping coefficient of the spring.
        var damping: Double
        
        /// Indices of the balls between which is the spring stretched.
        @noDerivative var attached: (from: Int, to: Int)

        /// Calculates the force acting on the spring give the `balls`.
        @differentiable(reverse)
        func force(balls: [Ball]) -> Vector {
            let (fromBall, toBall) = (balls[attached.from], balls[attached.to])
            let distance = fromBall.position - toBall.position
            let velocity = fromBall.velocity - toBall.velocity
            
            let dampingForce = damping * velocity
            let tensionForce = stiffness * (freeLength * distance.normalized - distance)
            return tensionForce - dampingForce
        }
    }
    /// Springs that exist in the world.
    var springs: [Spring]
    
    /// Current time.
    @noDerivative let time: Double
    /// Time increment value.
    @noDerivative let timeStep = 0.01

    /// Creates a world from the specified list `balls`, `springs` and `time`.
    @differentiable(reverse)
    init(balls: [Ball], springs: [Spring], time: Double) {
        self.balls = balls
        self.springs = springs
        self.time = time
    }

    /// Evolves the world forward by one time-step and returns the new state.
    @differentiable(reverse)
    func evolved() -> World {
        var forces = [Vector](repeating: .zero, count: withoutDerivative(at: balls.count))

        for i in withoutDerivative(at: springs.indices) {
            let spring = springs[i]

            let force = spring.force(balls: balls)
            forces = forces.updated(at: spring.attached.from,
                                    with: forces[spring.attached.from] + force)
            forces = forces.updated(at: spring.attached.to,
                                    with: forces[spring.attached.to] - force)

            // FIXME: Once co-routine differentiation is implemented use the code below
            // forces[spring.attached.from] += force
            // forces[spring.attached.to] -= force
        }

        var evolvedBalls = [Ball]()
        for i in withoutDerivative(at: balls.indices) {
            var ball = balls[i]
            ball.velocity = ball.velocity + (timeStep / ball.mass) * forces[i]
            ball.position = ball.position + timeStep * ball.velocity
            evolvedBalls.append(ball)
        }

        return World(balls: evolvedBalls, springs: springs, time: time + timeStep)
    }

    /// Evolves the world forward until `terminationTime` and returns the final state.
    @differentiable(reverse)
    func evolved(until terminationTime: Double) -> World {
        var world = self
        while world.time <= terminationTime {
            world = world.evolved()
        }
        return world
    }
}
