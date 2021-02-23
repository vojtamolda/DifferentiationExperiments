import _Differentiation


// MARK: Workaround for non-differentiable coroutines
// https://bugs.swift.org/browse/TF-1078
// https://bugs.swift.org/browse/TF-1080

extension Array where Element == [Float] {
    @differentiable(reverse where Element == [Float])
    mutating func updated(_ x: Int, _ y: Int, with newValue: Float) {
        self[x][y] = newValue
    }
 
    @derivative(of: updated)
    mutating func vjpUpdated(_ x: Int, _ y: Int, with newValue: Float)
      -> (value: Void, pullback: (inout TangentVector) -> (Float.TangentVector)) {
        self.updated(x, y, with: newValue)
        
        func pullback(dSelf: inout TangentVector) -> (Float.TangentVector) {
            let dElement = dSelf[x][y]
            dSelf.base[x].base[y] = .zero
            return dElement
        }
        let value: Void = ()
        return (value, pullback)
    }
}
