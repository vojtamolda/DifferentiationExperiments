import _Differentiation
import Foundation
import Darwin


// MARK: - Forward Mode Differentiation

func cube(_ x: Double) -> Double {
    return x * x * x
}

let 𝛁cube = gradient(of: cube)

print("cube(3) = \(cube(3))")
print("𝛁cube(3) = \(𝛁cube(3))")
print()


// MARK: - Reverse Mode Differentiation

func sqr(_ x: Double) -> Double {
    return x * x
}

let 𝛁sqr2 = gradient(at: 2, of: sqr)
print("𝛁sqr(2) = \(𝛁sqr2)")

let sqr2result = valueWithGradient(at: 2, of: sqr)
print("sqr(2) = \(sqr2result.value)")
print("𝛁sqr(2) = \(sqr2result.gradient)")

func mult(_ x: Double, _ y: Double) -> Double {
    return x * y
}

let 𝛁mult21 = gradient(at: 2, 1, of: mult)
print("𝛁mult(2, 1) = \(𝛁mult21)")
print()


// MARK: - Differentiable Types

infix operator • : MultiplicationPrecedence

struct Point: Differentiable {
    var x, y : Double
    
    func norm() -> Double {
        return (x * x + y * y).squareRoot()
    }
    
    static func • (left: Point, right: Point) -> Double {
        return left.x * right.x + left.y * right.y
    }
}

let point = Point(x: 1, y: 2)
let fixed = Point(x: 2, y: 1)

let 𝛁dot = gradient(at: point) { p in p • fixed }
print("𝛁dot(point, fixed) = \(𝛁dot)")

let 𝛁norm = gradient(at: point) { p in p.norm() }
print("𝛁norm(point) = \(𝛁norm)")
print()


// MARK: - Custom Derivative

func sqrtStdCLib(_ x: Double) -> Double {
    return sqrt(x)
}

@derivative(of: sqrtStdCLib)
func sqrtStdCLibGrad(_ x: Double) -> (value: Double, pullback: (Double) -> (Double)) {
    return (value: sqrtStdCLib(x),
            pullback: { chain in chain * (1 / (2 * sqrtStdCLib(x))) } )
}

let 𝛁sqrtStdCLibAt2 = valueWithGradient(at: 2, of: sqrtStdCLib)
print("𝛁sqrtStdCLib(2) = \(𝛁sqrtStdCLibAt2.gradient)")
print()


// MARK: - Differentiation of Control Flow

@differentiable(reverse, wrt: x)
func babylonianSqrt(_ x: Double, n: Int = 10) -> Double {
    var sqrtX = (1 + x) / 2

    for _ in 0 ..< n {
        sqrtX = (sqrtX + x / sqrtX) / 2
    }

    return sqrtX
}

let 𝛁babylonianSqrt = gradient { x in babylonianSqrt(x) }
print("𝛁babylonianSqrt(2) = \(𝛁babylonianSqrt(2))")
print()
