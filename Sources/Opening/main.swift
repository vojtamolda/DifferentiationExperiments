import _Differentiation
import Plotly


// MARK: - Back to high school

/// A simple, differentiable, quadratic function.
@differentiable(reverse)
func f(_ x: Double) -> Double {
    return x*x + x + 1
}

/// Creates a chart of function a `function` and its derivative in the specified `interval`.
func createDerivativeChart(of function: @differentiable(reverse) (Double) -> Double,
                           in interval: StrideThrough<Double>) -> Figure {
    // Derivative of `function`, i.e. function that returns the slope at point `x`.
    let derivative: (_ x: Double) -> Double = { x in gradient(at: x, of: function) }

    let functionTrace = Scatter(
        name: "$$f(x)$$",
        x: interval,
        y: interval.map(function),
        mode: .lines
    )
    
    let derivativeTrace = Scatter(
        name: "$$f'(x)$$",
        x: interval,
        y: interval.map(derivative),
        mode: .lines
    )
    
    let layout = Layout(
        font: .init(
            family: "'Computer Modern Serif', 'Times New Roman', serif",
            size: 16
        ),
        height: 600,
        paperBackgroundColor: Color.transparent
    )
    
    let config = Config(
        staticPlot: true,
        responsive: true
    )

    return Figure(
        data: [functionTrace, derivativeTrace],
        layout: layout,
        config: config
    )
}

let derivativeChart = createDerivativeChart(of: f, in: stride(from: -3, through: +3, by: 0.15))
try derivativeChart.show()
try derivativeChart.write(toFile: "Derivative.html")


// MARK: - Curve fitting

/// Representation of a point in the 2D plane.
struct Point {
    var x, y: Double
}

/// Representation of a straight line in the 2D plane.
struct Line: Differentiable, AdditiveArithmetic {
    typealias TangentVector = Self

    /// Ratio of `y` over `x` coordinates.
    var slope: Double
    /// Intercept when crossing the `y` axis.
    var offset: Double

    /// Calculates the `y` coordinate when the independent variable has value `x`.
    @differentiable(reverse)
    func y(at x: Double) -> Double {
        return (slope * x) + offset
    }
    
    /// Calculates sum of squared horizontal differences when the line passes through the provided a cloud of `points`.
    @differentiable(reverse)
    func meanSquaredError(passingThrough points: [Point]) -> Double {
        var sumOfSqrErrors = 0.0

        for point in points {
            let Δy = y(at: point.x) - point.y
            sumOfSqrErrors += Δy * Δy
        }

        return sumOfSqrErrors.squareRoot() / Double(points.count)
    }

    /// Returns a representation of the line scaled by the provided `factor`.
    func scaled(by factor: Double) -> Line {
        return Line(slope: factor * slope, offset: offset * factor)
    }
}

/// Fits the initial `line` to the provided cloud of `points` using gradient descent and returns the result after each iteration.
func fit(initialization line: Line, to points: [Point],
         learningRate α: Double = 0.02, iterations: Int = 20) -> [Line] {
    var line = line
    var lines = [line]

    for _ in 1 ... iterations {
        let 𝛁line = gradient(at: line) { line -> Double in
            return line.meanSquaredError(passingThrough: points)
        }
        
        line.move(by: 𝛁line.scaled(by: -α))
        lines.append(line)
    }

    return lines
}

let range = -50 ... +50
let x = range.map { Double($0) + Double.random(in: -1 ... +1) }
let y = range.map { Double($0) + Double.random(in: -1 ... +1) }
let points = zip(x, y).map { Point(x: $0, y: $1) }
let lines = fit(initialization: Line(slope: 0, offset: 0), to: points)

/// Creates an animated chart showing a sequence of lines fitted to a `points` cloud.
func createFittingAnimation(of lines: [Line], to points: [Point]) -> Figure {
    var frames = [Frame]()
    var sliderSteps = [Layout.Slider.Step]()
    
    let pointsTrace = Scatter(
        name: "Points",
        x: points.map(\.x),
        y: points.map(\.y),
        mode: .markers
    )

    for (offset, line) in lines.enumerated() {
        let fitTrace = Scatter(
            name: "Line",
             x: range,
             y: range.map{ line.y(at: Double($0)) },
             mode: .lines
        )

        let frame = Frame(
            name: "\(offset)",
            data: [pointsTrace, fitTrace]
        )
        frames.append(frame)

        let sliderStep = Layout.Slider.Step(
            method: .animate,
            args: [[.string(frame.name!)]],
            label: frame.name!
        )
        sliderSteps.append(sliderStep)
    }

    let playButton = Layout.UpdateMenu.Button(
        method: .animate,
        args: [.null, .object([
            "mode": "immediate",
            "fromcurrent": true,
            "transition": ["duration": 0],
            "frame": ["duration": 100]
            ])
        ],
        label: "▶"
    )

    let slider = Layout.Slider(
        active: Double(frames.count - 1),
        steps: sliderSteps,
        length: 0.9,
        x: 0.1,
        padding: .init(t: 50, b: 10),
        xAnchor: .left,
        y: 0.0, yAnchor: .top,
        transition: .init(duration: 0),
        currentValue: .init(visible: true, prefix: "Iteration: "),
        name: "Iteration"
    )

    let layout = Layout(
        font: Font(
            family: "'Computer Modern Serif', 'Times New Roman', serif",
            size: 16
        ),
        height: 600,
        paperBackgroundColor: Color.transparent,
        updateMenus: [
            Layout.UpdateMenu(
                type: .buttons,
                direction: .left,
                showActive: false,
                buttons: [playButton],
                x: 0.1, xAnchor: .right,
                y: 0.03, yAnchor: .top,
                padding: .init(t: 87, r: 10)
            )
        ],
        sliders: [slider]
    )

    let config = Config(
        staticPlot: true,
        responsive: true
    )

    return Figure(
        data: frames[Int(layout.sliders?[0].active ?? 0)].data,
        layout: layout,
        frames: frames,
        config: config
    )
}


let curveFittingAnimation = createFittingAnimation(of: lines, to: points)
try curveFittingAnimation.show()
try curveFittingAnimation.write(toFile: "Curve Fitting.html")


// MARK: - Output charts as a single </div>

let derivativeChartDiv = try HTML.create(from: derivativeChart, plotly: .excluded,
                                         mathJax: .excluded, document: false)
try derivativeChartDiv.write(toFile: "Derivative.div.html", atomically: true, encoding: .utf8)

let curveFittingAnimationDiv = try HTML.create(from: curveFittingAnimation, plotly: .excluded,
                                               mathJax: .excluded, document: false)
try curveFittingAnimationDiv.write(toFile: "Curve Fitting.div.html", atomically: true, encoding: .utf8)
