import _Differentiation
import Foundation


struct Ball: Differentiable, AdditiveArithmetic {
    var position: Vec2
    var velocity: Vec2

    static let ballRadius = Float(1)

    @differentiable(reverse)
    init(position: Vec2, velocity: Vec2) {
        self.position = position
        self.velocity = velocity
    }

    @differentiable(reverse)
    func updating(position: Vec2) -> Ball {
        Ball(position: position, velocity: velocity)
    }

    @differentiable(reverse)
    func updating(velocity: Vec2) -> Ball {
        Ball(position: position, velocity: velocity)
    }

    @differentiable(reverse)
    func moved(_ delta: Vec2) -> Ball {
        updating(position: position + delta)
    }

    @differentiable(reverse)
    func impulsed(_ delta: Vec2) -> Ball {
        updating(velocity: velocity + delta)
    }
}

struct BallTup: Differentiable {
    var ball1: Ball
    var ball2: Ball
    var collisionEnergy: Float

    @differentiable(reverse)
    init(_ ball1: Ball, _ ball2: Ball, _ collisionEnergy: Float) {
        self.ball1 = ball1
        self.ball2 = ball2
        self.collisionEnergy = collisionEnergy
    }
}

struct Wall {
    var p1: Vec2
    var p2: Vec2
}

struct SimulationParameters {
    var dt: Float = 0.02
    var lambda: Float = 0.0
}

extension Ball {
    @differentiable(reverse)
    func stepped(_ params: SimulationParameters) -> Ball {
        let frictionAcceleration = Float(1)
        let friction = Vec2(magnitude: frictionAcceleration * params.dt, direction: velocity.direction)
        var newVelocity = friction.magnitude > velocity.magnitude ? Vec2(0, 0) : velocity - friction

        if Float.random(in: 0..<1) > exp(-params.lambda * params.dt) {
            newVelocity = newVelocity + newVelocity.magnitude * Vec2(Float.random(in: (-0.5...0.5)), Float.random(in: (-0.5...0.5)))
        }

        return Ball(
            position: position + params.dt * newVelocity,
            velocity: newVelocity)
    }

    func touches(_ other: Ball) -> Bool {
        return (position - other.position).magnitude <= 2 * Ball.ballRadius
    }

    private func projected(to wall: Wall) -> Float {
        (wall.p1.magnitudeSquared + position.dot(wall.p2 - wall.p1) - wall.p1.dot(wall.p2)) / (wall.p2 - wall.p1).magnitudeSquared
    }
    
    func touches(_ wall: Wall) -> Bool {
        let t = projected(to: wall)
        if t < 0 || t > 1 { return false }
        let projection = (1 - t) * wall.p1 + t * wall.p2
        return (position - projection).magnitudeSquared <= Ball.ballRadius * Ball.ballRadius
    }

    @differentiable(reverse)
    func bounced(on wall: Wall) -> Ball {
        let tangent = wall.p2 - wall.p1
        let unitTangent = tangent / tangent.magnitude
        let unitNormal = Vec2(-unitTangent.y, unitTangent.x)
        let t = projected(to: wall)
        let projection = (1 - t) * wall.p1 + t * wall.p2
        let displacement = position - projection
        if velocity.dot(displacement) > 0 { return self }
        let newVelocity = velocity.dot(unitTangent) * unitTangent - velocity.dot(unitNormal) * unitNormal
        return Ball(position: position, velocity: newVelocity)
    }

    @differentiable(reverse)
    static func collided(_ a: Ball, _ b: Ball) -> BallTup {
        updateCollisionVelocities(a, b)
    }

    private static func updateCollisionVelocities(_ ball1: Ball, _ ball2: Ball) -> BallTup {
        // Perfectly elastic collision. This is the impulse along the normal that preserves kinetic energy.
        let p = ball2.position - ball1.position
        let v = ball2.velocity - ball1.velocity
        let vdotp = v.dot(p)
        if vdotp > 0 { return BallTup(ball1, ball2, 0) }
        let impulse = (-vdotp / p.magnitudeSquared) * p
        return BallTup(ball1.impulsed(-1 * impulse), ball2.impulsed(impulse), impulse.magnitudeSquared)
    }
}
