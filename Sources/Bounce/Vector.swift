import _Differentiation


/// Dot product operator. Can be typed with `⌥ (option) - 8` on macOS.
infix operator • : MultiplicationPrecedence

/// Vector in the 2D plane.
struct Vector: Differentiable {
    /// Horizontal component of the vector.
    var x: Double
    /// Vertical component of the vector.
    var y: Double

    /// Unit vector point the the horizontal direction.
    static let unitX = Vector(x: 1, y: 0)
    /// Unit vector point the the vertical direction.
    static let unitY = Vector(x: 0, y: 1)
    
    /// Length of the vector.
    @differentiable(reverse)
    var magnitude: Double { (x * x + y * y).squareRoot() }

    /// Vector normalized have unit length and identical direction.
    @differentiable(reverse)
    var normalized: Vector { Vector(x: x / magnitude, y: y / magnitude) }
    
    /// Perpendicular vector, rotated by 90°.
    @differentiable(reverse)
    var perpendicular: Vector { Vector(x: y , y: -x) }
    
    /// Multiplies vector by a scalar value.
    @differentiable(reverse)
    static func * (_ lhs: Double, _ rhs: Vector) -> Vector {
        Vector(x: lhs * rhs.x, y: lhs * rhs.y)
    }

    /// Calculates dot product of two vectors.
    @differentiable(reverse)
    static func • (_ lhs: Vector, _ rhs: Vector) -> Double {
        lhs.x * rhs.x + lhs.y * rhs.y
    }
}

extension Vector: AdditiveArithmetic {
    static let zero = Vector(x: 0, y: 0)

    @differentiable(reverse)
    static func + (_ lhs: Vector, _ rhs: Vector) -> Vector {
        Vector(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    @differentiable(reverse)
    static func - (_ lhs: Vector, _ rhs: Vector) -> Vector {
        Vector(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}
