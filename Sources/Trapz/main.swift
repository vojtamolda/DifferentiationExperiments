import _Differentiation
import Foundation
import Plotly


// MARK: Autograd and the derivative of an integral function

@differentiable(reverse)
func trapz(x: [Double], y: [Double]) -> Double {
    precondition(x.count > 1 && x.count == y.count)

    var integral = 0.0
    for i in withoutDerivative(at: x.indices.dropFirst()) {
        let yMean = (y[i] + y[i - 1]) / 2
        let xStep = x[i] - x[i - 1]
        integral += yMean * xStep
    }

    return integral
}


// MARK: - Example 1

@differentiable(reverse)
func phi(alpha: Double) -> Double {
    let xStride = stride(from: 0, through: 1, by: 0.01)
    
    var y = [Double]()
    for x in xStride {
        y.append(alpha / (x * x + alpha * alpha))
    }

    return trapz(x: Array(xStride), y: y)
}

let dphi: (Double) -> (Double) = { alpha in
    gradient(at: alpha, of: phi)
}

func analytical_dphi(_ alpha: Double) -> Double {
    return -1 / (1 + alpha * alpha)
}

let alpha = stride(from: 0.05, through: 1, by: 0.01)

let figure1 = Figure(
    data: [
        Scatter(
            name: "analytical",
            x: alpha,
            y: alpha.map(analytical_dphi)
        ),
        Scatter(
            name: "AD",
            x: alpha,
            y: alpha.map(dphi)
        ),
        Scatter(
            name: "$$\\Delta$$",
            x: alpha,
            y: alpha.map { dphi($0) - analytical_dphi($0) },
            yAxis: .init(
                title: "$$\\Delta$$",
                domain: [0, 0.2]
            )
        )
    ],
    layout: .init(
        title: "$$\\phi(\\alpha) = \\int_0^1 \\frac{\\alpha}{x^2 + \\alpha^2} dx$$.",
        xAxis: .preset(
             title: "$$\\alpha$$"
        ),
        yAxis: .preset(
             title: "$$\\frac{d \\phi}{d \\alpha}$$",
             domain: [0.5, 1]
        )
    )
)

try figure1.write(toFile: "Example 1.html")
try figure1.show()


// MARK: - Example 2

@differentiable(reverse)
func f(x: Double) -> Double {
    let a = sin(x)
    let b = cos(x)

    var t = [Double]()
    for i in 0...100 {
        t.append(a + Double(i)/100.0 * (b - a) )
    }

    let y = t.differentiableMap { t in cosh( t * t ) }

    return trapz(x: t, y: y)
}

let df: (Double) -> (Double) = { x in
    gradient(at: x, of: f)
}

func analytical_df(_ x: Double) -> Double {
    return -(cosh(cos(x) * cos(x)) * sin(x) + cosh(sin(x) * sin(x)) * cos(x))
}

let x = stride(from: 0, through: 2 * Double.pi, by: 0.01)

let figure2 = Figure(
    data: [
        Scatter(
            name: "analytical",
            x: x,
            y: x.map(analytical_df)
        ),
        Scatter(
            name: "AD",
            x: x,
            y: x.map(df)
        ),
        Scatter(
            name: "$$\\Delta$$",
            x: x,
            y: x.map { df($0) - analytical_df($0) },
            yAxis: .init(
                title: "$$\\Delta$$",
                domain: [0, 0.2]
            )
        )
    ],
    layout: .init(
        title: "$$f(x) = \\int_{\\sin x}^{\\cos x} \\cosh t^2 dt$$",
        xAxis: .preset(
             title: "$$x$$"
        ),
        yAxis: .preset(
             title: "$$\\frac{d f}{d x}$$",
             domain: [0.5, 1]
        )
    )
)

try figure2.write(toFile: "Example 2.html")
try figure2.show()
