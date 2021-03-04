import _Differentiation
import Foundation


public struct Vec2: Differentiable, AdditiveArithmetic {
    public var x: Float
    public var y: Float

    @differentiable(reverse)
    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }

    @differentiable(reverse)
    public init(_ x: Float, _ y: Float) {
        self.x = x
        self.y = y
    }

    @differentiable(reverse)
    public init(magnitude: Float, direction: Float) {
        self.x = magnitude * cos(direction)
        self.y = magnitude * sin(direction)
    }
}

public extension Vec2 {
    @differentiable(reverse)
    static func + (_ lhs: Vec2, _ rhs: Vec2) -> Vec2 {
        Vec2(lhs.x + rhs.x, lhs.y + rhs.y)
    }

    @differentiable(reverse)
    static func - (_ lhs: Vec2, _ rhs: Vec2) -> Vec2 {
        Vec2(lhs.x - rhs.x, lhs.y - rhs.y)
    }

    @differentiable(reverse)
    static func * (_ lhs: Float, _ rhs: Vec2) -> Vec2 {
        Vec2(lhs * rhs.x, lhs * rhs.y)
    }

    @differentiable(reverse)
    static func / (_ lhs: Vec2, _ rhs: Float) -> Vec2 {
        Vec2(lhs.x / rhs, lhs.y / rhs)
    }

    @differentiable(reverse)
    var magnitudeSquared: Float {
        x * x + y * y
    }

    @differentiable(reverse)
    var magnitude: Float {
        sqrt(magnitudeSquared)
    }

    @differentiable(reverse)
    var direction: Float {
        atan2(y, x)
    }

    @derivative(of: direction)
    func vjpDirection() -> (value: Float, pullback: (Float) -> Vec2) {
        func pullback(_ v: Float) -> Vec2 {
            let d = x * x + y * y
            return v * Vec2(-y / d, x / d)
        }
        return (direction, pullback)
    }

    @differentiable(reverse)
    func dot(_ other: Vec2) -> Float {
        x * other.x + y * other.y
    }
}
