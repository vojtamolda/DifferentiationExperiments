import _Differentiation
import Foundation


struct Brain: Differentiable {
    var amplitudes: [Double]
    @noDerivative var phases: [Double]
    @noDerivative let frequency: Double = 1.0
    
    init(for animal: Animal) {
        amplitudes = Array(repeating: 0.005, count: animal.muscles.count)
        phases = (0 ..< animal.muscles.count).map { _ in
            Double.random(in: -Double.pi ... +Double.pi)
        }
    }
    
    @differentiable(reverse)
    func actuations(at time: Double) -> [Double] {
        var actuations = [Double](repeating: 0, count: withoutDerivative(at: amplitudes.count))

        for i in withoutDerivative(at: 0 ..< amplitudes.count) {
            let amplitude = amplitudes[i]
            let phase = phases[i]
            let actuation = amplitude * sin(2 * Double.pi * frequency * time + phase)

            actuations = actuations.updated(at: i, with: actuation)
            
        }
        return actuations
    }
}




// MARK: -
// FIXME: Workaround for derivatives and functions in different files
func sin(_ x: Double) -> Double {
    Darwin.sin(x)
}

@derivative(of: sin)
func vjpSin(_ x: Double) -> (value: Double, pullback: (Double) -> (Double)) {
    (value: sin(x), pullback: { chain in chain * Darwin.cos(x) } )
}
