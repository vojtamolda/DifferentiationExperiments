import _Differentiation
import Foundation
import Plotly


/// Adapted from `numpy.linspace`: https://numpy.org/devdocs/reference/generated/numpy.linspace.html.
///
/// Returns:
/// - samples: `count` evenly spaced samples, calculated over the closed interval `range`.
/// - step: The spacing between samples.
func linspace(_ range: ClosedRange<Float>, count: Int = 50) -> (samples: [Float], step: Float) {
  let low = range.lowerBound
  let high = range.upperBound
  let step = (high - low) / Float(count - 1)
  let samples = stride(from: 0, to: Float(count), by: 1).map { $0 * step }
  return (samples, step)
}

/// Returns solution to an ODE system `y' = f` on the interval specified by `range`.
///
/// - Parameters:
///  - f: Function rhs
///  - range: SSdgs
///  - y0: Initial condition
///
@differentiable(reverse, wrt: y0)
func rk4(_ f: @differentiable(reverse) @escaping (Float, Float) -> Float,
         range: ClosedRange<Float>, y0: Float) -> [Float] {
    let N = 50
    precondition(N > 2, "N too small")

    let (x, h) = linspace(range, count: N)
    var y: [Float] = [y0]

    for i in x.indices.dropLast() {
        let k1 = h * f(x[i], y[i])
        let k2 = h * f(x[i] + h / 2.0, y[i] + k1 / 2.0)
        let k3 = h * f(x[i] + h / 2.0, y[i] + k2 / 2.0)
        let k4 = h * f(x[i + 1], y[i] + k3)
        var intermediate = k1 + (2.0 * k2) + (2.0 * k3) + k4
        intermediate /= 6.0
        y.append(y[i] + (k1 + (2.0 * k2) + (2.0 * k3) + k4) / 6.0)
    }
    return y
}

let Ca0: Float = 1.0
let k_1: Float = 3.0
let k1: Float = 3.0

func dCdt(_ t: Float, _ Ca: Float) -> Float {
    -k1 * Ca + k_1 * (Ca0 - Ca)
}


let tspan = linspace(0...0.5).samples
let Ca = rk4(dCdt, range: 0...0.5, y0: Ca0)


@differentiable(reverse, wrt: (k1, k_1))
func A(Ca0: Float, k1: Float, k_1: Float, t: Float) -> Float {
    let _: @differentiable(reverse) (Float, Float) -> Float = { (_: Float, Ca: Float) -> Float in
        -k1 * Ca + k_1 * (Ca0 - Ca)
    }
    // Workaround code currently crashes the compiler (https://bugs.swift.org/browse/SR-12992):
    // let f: @differentiable (Float, Float) -> Float = dCdt
    // let Ca_ = rk4(withoutDerivative(at: f), range: 0...t, y0: Ca0)
    let Ca_ = rk4(dCdt, range: 0...t, y0: Ca0)
    return Ca_[Ca_.endIndex - 1]
}

let figure1 = Figure(
    data: [
        Scatter(name: "RK4", x: tspan, y: Ca),
        Scatter(name: "analytical", x: tspan, y: tspan.map { t in analytical_A(t: t, k1: k1, k_1: k_1) })
    ]
)
try figure1.write(toFile: "Figure 1.html")
try figure1.show()



@differentiable(reverse, wrt: (k1, k_1))
func analytical_A(t: Float, k1: Float, k_1: Float) -> Float {
    return Ca0 / (k1 + k_1) * (k1 * exp(-(k1 + k_1) * t) + k_1)
}


let dCadk1 = { Ca0, k1, k_1, t in gradient(at: k1, of: { k1 in A(Ca0: Ca0, k1: k1, k_1: k_1, t: t) }) }
let dCadk_1 = { Ca0, k1, k_1, t in gradient(at: k_1, of: { k_1 in A(Ca0: Ca0, k1: k1, k_1: k_1, t: t) }) }
print(dCadk1, type(of: dCadk1))

let dAdk1 = { k1, k_1, t in gradient(at: k1, of: { k1 in analytical_A(t: t, k1: k1, k_1: k_1) }) }
let dAdk_1 = { k1, k_1, t in gradient(at: k_1, of: { k_1 in analytical_A(t: t, k1: k1, k_1: k_1) }) }

let k1_sensitivity = tspan.map { t in dCadk1(Ca0, k1, k_1, t) }
let k_1_sensitivity = tspan.map { t in dCadk_1(Ca0, k1, k_1, t) }

let ak1_sensitivity = tspan.map { t in dAdk1(k1, k_1, t) }
let ak_1_sensitivity = tspan.map { t in dAdk_1(k1, k_1, t) }



let k1_analytical = Scatter(name: "k1 analytical", x: tspan, y: ak1_sensitivity)
let k1_numerical = Scatter(name: "k1 numerical", x: tspan, y: k1_sensitivity)

let k_1_analytical = Scatter(name: "k_1 analytical", x: tspan, y: ak_1_sensitivity)
let k_1_numerical = Scatter(name: "k_1 numerical", x: tspan, y: k_1_sensitivity)
 
let figure2 = Figure(data: [k1_analytical, k1_numerical, k_1_analytical, k_1_numerical])
try figure2.write(toFile: "Figure 2.html")
try figure2.show()
