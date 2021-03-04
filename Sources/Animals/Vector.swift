import _Differentiation
import Foundation


infix operator • : MultiplicationPrecedence

struct Vector: Differentiable, AdditiveArithmetic, Hashable {
    var x, y: Double

    static let zero = Vector(x: 0, y: 0)
    static let unitX = Vector(x: 1, y: 0)
    static let unitY = Vector(x: 0, y: 1)
    
    @differentiable(reverse)
    var normalized: Vector { Vector(x: x / magnitude, y: y / magnitude) }
    
    @differentiable(reverse)
    var perpendicular: Vector { Vector(x: y , y: -x) }

    @differentiable(reverse)
    static func + (_ lhs: Vector, _ rhs: Vector) -> Vector {
        Vector(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    @differentiable(reverse)
    static func - (_ lhs: Vector, _ rhs: Vector) -> Vector {
        Vector(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    @differentiable(reverse)
    static func * (_ lhs: Double, _ rhs: Vector) -> Vector {
        Vector(x: lhs * rhs.x, y: lhs * rhs.y)
    }
    
    @differentiable(reverse)
    static func / (_ lhs: Vector, _ rhs: Double) -> Vector {
        Vector(x: lhs.x / rhs, y: lhs.y / rhs)
    }

    @differentiable(reverse)
    static func • (_ lhs: Vector, _ rhs: Vector) -> Double {
        lhs.x * rhs.x + lhs.y * rhs.y
    }

    @differentiable(reverse)
    var magnitude: Double {
        sqrt(x * x + y * y)
    }
}

extension Vector: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Double...) {
        precondition(elements.count == 2)
        x = elements[0]
        y = elements[1]
    }
}


// MARK: -
// FIXME: Workaround for derivatives and functions in different files
func sqrt(_ x: Double) -> Double {
    Darwin.sqrt(x)
}

@derivative(of: sqrt)
func vjpSqrt(_ x: Double) -> (value: Double, pullback: (Double) -> (Double)) {
    (value: sqrt(x), pullback: { chain in chain * (1 / (2 * sqrt(x))) } )
}


// MARK: -
// FIXME: Workaround for non-differentiable co-routines (https://bugs.swift.org/browse/TF-1078)
extension Array {
    @differentiable(reverse where Element: Differentiable)
    func updated(at index: Int, with newValue: Element) -> [Element] {
        var result = self
        result[index] = newValue
        return result
    }
}

extension Array where Element: Differentiable {
    @derivative(of: updated)
    func vjpUpdated(at index: Int, with newValue: Element) -> (
        value: [Element], pullback: (TangentVector) -> (TangentVector, Element.TangentVector)
        ) {
            let value = updated(at: index, with: newValue)
            return (value, { v in
                var dself = v
                dself.base[index] = .zero
                return (dself, v[index])
            })
    }
}
