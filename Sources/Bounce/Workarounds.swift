import _Differentiation


extension Array {
    /// Workaround for non-differentiable array index subscript.
    ///
    /// More details about non-differentiable co-routines ca be found here:
    /// https://bugs.swift.org/browse/TF-1078)
    @differentiable(reverse where Element: Differentiable)
    func updated(at index: Int, with newValue: Element) -> [Element] {
        var result = self
        result[index] = newValue
        return result
    }
}

extension Array where Element: Differentiable {
    /// Custom VJP (Vector-Jacobian Product) of the array subscript workaround method.
    @derivative(of: updated)
    func vjpUpdated(at index: Int, with newValue: Element)
    -> (value: [Element], pullback: (TangentVector) -> (TangentVector, Element.TangentVector)) {
        return (
            value: updated(at: index, with: newValue),
            pullback: { v in
                var dself = v
                dself.base[index] = .zero
                return (dself, v[index])
            }
        )
    }
}
