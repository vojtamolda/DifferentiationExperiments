import _Differentiation


struct World: Differentiable {
    /// Current state of all the balls.
    var balls: [Ball]

    /// Minimum ball distance (over all previous states) to each target.
    var targetDistances: [Float]

    /// Amount of time simulation has been running.
    var t: Float

    /// Positions of the targets.
    @noDerivative var targets: [Vec2]

    /// Positions of the walls.
    @noDerivative var walls: [Wall]

    @differentiable(reverse)
    init(
        balls: [Ball],
        targetDistances: [Float],
        t: Float,
        targets: [Vec2],
        walls: [Wall]
    ) {
        self.balls = balls
        self.targetDistances = targetDistances
        self.t = t
        self.targets = targets
        self.walls = walls
    }
}
