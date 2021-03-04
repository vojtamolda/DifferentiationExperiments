import _Differentiation
import Foundation


extension World {
    @differentiable(reverse)
    init(balls: [Ball], targets: [Vec2], walls: [Wall]) {
        self.init(
            balls: balls,
            targetDistances: Array(repeating: Float.infinity, count: withoutDerivative(at: targets.count)),
            t: 0,
            targets: targets,
            walls: walls
        )
    }

    @differentiable(reverse)
    init(ball1InitialVelocity: Vec2) {
        self.init(
            balls: [
                Ball(position: Vec2(-20, 0), velocity: ball1InitialVelocity),
                Ball(position: Vec2(-10, 0), velocity: Vec2(0, 0))
            ],
            targets: [
                Vec2(0, 5),
                Vec2(-5, 15),
                Vec2(-2, -20)
            ],
            walls: [
                Wall(p1: Vec2(7, -10), p2: Vec2(7, 20))
            ]
        )
    }
}

extension World {
    var still: Bool {
        if t > 7 { return true }
        for ball in balls {
            if ball.velocity.magnitude > 0 {
                return false
            }
        }
        return true
    }
}

extension World {
    @differentiable(reverse)
    func stepped(_ params: SimulationParameters = SimulationParameters()) -> World {
        // Integrate the ball velocity.
        var updatedBalls = balls.differentiableMap { $0.stepped(params) }

        // Collide the balls with the walls.
        updatedBalls = updatedBalls.differentiableMap { [walls = walls] (ball: Ball) -> Ball in
            for i in withoutDerivative(at: walls.indices) {
                let wall = walls[i]
                if ball.touches(wall) {
                    return ball.bounced(on: wall)
                }
            }
            return ball
        }

        // Collide the balls with each other.
        if updatedBalls[0].touches(updatedBalls[1]) {
            let collidedBalls = Ball.collided(updatedBalls[0], updatedBalls[1])
            updatedBalls = [collidedBalls.ball1, collidedBalls.ball2]
        }

        // Update min target distance.
        var newMinTargetDistance: [Float] = []
        for i in withoutDerivative(at: targets.indices) {
            let distTo1 = (updatedBalls[0].position - targets[i]).magnitude
            let distTo2 = (updatedBalls[1].position - targets[i]).magnitude
            var curTargetDistance = distTo1 < distTo2 ? distTo1 : distTo2
            if curTargetDistance < 2 * Ball.ballRadius { curTargetDistance = 2 * Ball.ballRadius }
            if curTargetDistance < targetDistances[i] {
                newMinTargetDistance = newMinTargetDistance + [curTargetDistance]
            } else {
                newMinTargetDistance = newMinTargetDistance + [targetDistances[i]]
            }
        }
        
        return World(
            balls: updatedBalls,
            targetDistances: newMinTargetDistance,
//            .withDerivative { [count = withoutDerivative(at: newMinTargetDistance.count)] (d: inout Array<Float>.DifferentiableView) -> () in
//                if d.base.count == 0 {
//                    d = Array.DifferentiableView(Array(repeating: 0, count: count))
//                }
//            },
            t: t + params.dt,
            targets: targets,
            walls: walls
        )
    }

    @differentiable(reverse)
    func steppedUntilStill(_ params: SimulationParameters, _ f: (World) -> () = { _ in }) -> World {
        var state = self
        while !state.still {
            f(state)
            state = state.stepped(params)
        }
        f(state)
        return state
    }
}

struct DrawingArrow {
    var offset: Vec2
    var color: String
    var direction: Vec2
}

func svg(states: [World], params: SimulationParameters = SimulationParameters(), vectors: [[DrawingArrow]] = [], delay: Float = 0) -> String {
    let scale = Float(7)
    let origin = Vec2(175, 70)
    let size = Vec2(350, 224)

    func transformed(_ position: Vec2) -> Vec2 {
        let p2 = Vector2(x: position.y, y: -position.x)
        return scale * p2 + origin
    }

    var r = ""
    r += """
    <svg width="\(Int(size.x))" height="\(Int(size.y))"
         xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">\n
    """

    let totalDuration = (states.last?.t ?? 0) + delay
    r += """
    <rect>
    <animate
    id="looper"
    begin="0;looper.end"
    attributeName="visibility"
    from="hide"
    to="hide"
    dur="\(totalDuration)s" />
    </rect>
    """

    func target(id: String, cx: String, cy: String, border: String) -> String {
        """
        <circle
        id="\(id)"
        r="\(scale * Ball.ballRadius)"
        cx="\(cx)"
        cy="\(cy)"
        stroke-width="3"
        stroke="\(border)" />\n
        """
    }

    func circle(id: String, cx: String, cy: String, fill: String) -> String {
        """
        <circle
        id="\(id)"
        r="\(scale * Ball.ballRadius)"
        cx="\(cx)"
        cy="\(cy)"
        fill="\(fill)" />\n
        """
    }

    func line(p1: Vec2, p2: Vec2) -> String {
        """
        <line
        x1="\(p1.x)"
        y1="\(p1.y)"
        x2="\(p2.x)"
        y2="\(p2.y)"
        style="stroke:#000;stroke-width:2" />\n
        """
    }

    func arrow(id: String, _ arrow: DrawingArrow, _ base: Vec2) -> String {
        let off2 = Vector2(x: arrow.offset.y, y: -arrow.offset.x)
        let p1 = base + off2
        let dir2 = Vector2(x: arrow.direction.y, y: -arrow.direction.x)
        let p2 = p1 + dir2
        return """
        <line
        id="\(id)"
        x1="\(p1.x)"
        y1="\(p1.y)"
        x2="\(p2.x)"
        y2="\(p2.y)"
        style="stroke:\(arrow.color);stroke-width:2" />\n
        """
    }

    for (index, finalPosition) in (states.first?.targets ?? []).enumerated() {
        let position = transformed(finalPosition)
        r += target(id: "target\(index)", cx: "\(position.x)", cy: "\(position.y)", border: "red")
    }

    for (index, ball) in (states.first?.balls ?? []).enumerated() {
        let position = transformed(ball.position)
        r += circle(id: "ball\(index)", cx: "\(position.x)", cy: "\(position.y)", fill: "orange")

        if vectors.count > index {
            for (index2, vector) in vectors[index].enumerated() {
                let id = "arrow\(index)_\(index2)"
                r += arrow(id: id, vector, position)
                r += """

                <animate
                xlink:href="#\(id)"
                attributeName="opacity"
                from="0"
                to="1"
                dur="\(params.dt)s"
                begin="looper.begin"
                fill="freeze" />
                <animate
                xlink:href="#\(id)"
                attributeName="opacity"
                from="1"
                to="0"
                dur="\(params.dt)s"
                begin="looper.begin+\(delay)s"
                fill="freeze" />
                """
            }
        }
    }

    for wall in (states.first?.walls ?? []) {
        r += line(p1: transformed(wall.p1), p2: transformed(wall.p2))
    }

    for (timeIndex, (state, nextState)) in zip(states, states.dropFirst(1)).enumerated() {
        let t = Float(timeIndex) * params.dt + delay
        for (ballIndex, (ballState, nextBallState)) in zip(state.balls, nextState.balls).enumerated() {
            func animate(attributeName: String, from: String, to: String) -> String {
                """
                <animate
                xlink:href="#ball\(ballIndex)"
                attributeName="\(attributeName)"
                from="\(from)"
                to="\(to)"
                dur="\(params.dt)s"
                begin="looper.begin+\(t)s" />\n
                """
            }
            let position = transformed(ballState.position)
            let nextPosition = transformed(nextBallState.position)
            r += animate(attributeName: "cx", from: String(position.x), to: String(nextPosition.x))
            r += animate(attributeName: "cy", from: String(position.y), to: String(nextPosition.y))
        }

        for (targetIndex, (targetDistance, nextTargetDistance)) in zip(state.targetDistances, nextState.targetDistances).enumerated() {
            if targetDistance > 2 && nextTargetDistance <= 2 {
                r += """
                <animate
                xlink:href="#target\(targetIndex)"
                attributeName="stroke"
                from="green"
                to="red"
                dur="\(params.dt)s"
                begin="looper.begin"
                fill="freeze" />
                """
                r += """
                <animate
                xlink:href="#target\(targetIndex)"
                attributeName="stroke"
                from="red"
                to="green"
                dur="\(params.dt)s"
                begin="looper.begin+\(t)s"
                fill="freeze" />
                """
            }
        }
    }

    r += "</svg>\n"
    return r
}

func drawSVG(file: String, states: [World], params: SimulationParameters = SimulationParameters(), vectors: [[DrawingArrow]] = [], delay: Float = 0) {
    let contents = svg(states: states, params: params, vectors: vectors, delay: delay)
    try! contents.write(toFile: file, atomically: true, encoding: .utf8)
}

func drawSimulation(file: String, ball1InitialVelocity: Vec2, params: SimulationParameters = SimulationParameters()) {
    let initialState = World(ball1InitialVelocity: ball1InitialVelocity)
    let vectors = initialState.balls.enumerated().map { (index: Int, ball: Ball) -> [DrawingArrow] in
        let scaledVelocity = 2 * ball.velocity
        let vs = [DrawingArrow(offset: Vec2(0, 0), color: "blue", direction: scaledVelocity)]
        return vs
    }
    var allStates: [World] = []
    initialState.steppedUntilStill(params) { allStates.append($0) }
    drawSVG(file: file, states: allStates, params: params, vectors: vectors, delay: 1)
}

func drawGradients(file: String, ball1InitialVelocity: Vec2, params: SimulationParameters = SimulationParameters(), grad: Vec2) {
    let initialState = World(ball1InitialVelocity: ball1InitialVelocity)
    let vGrads = [-10 * grad]
    let vectors = initialState.balls.enumerated().map { (index: Int, ball: Ball) -> [DrawingArrow] in
        let scaledVelocity = 2 * ball.velocity
        var vs = [DrawingArrow(offset: Vec2(0, 0), color: "blue", direction: scaledVelocity)]
        if vGrads.count > index {
            vs.append(DrawingArrow(offset: scaledVelocity, color: "green", direction: vGrads[index]))
        }
        return vs
    }
    drawSVG(file: file, states: [initialState], params: params, vectors: vectors, delay: 3600)
}
