import Plotly


extension World {
    /// Scatter plot trace displaying balls.
    var ballsTrace: Plotly.Trace {
        Scatter(
            name: "Balls",
            x: balls.map(\.position.x),
            y: balls.map(\.position.y),
            hoverText: .variable(balls.indices.map { "Ball \($0)" }),
            mode: .markers,
            marker: .init(size: 15, coloring: .constant(.green))
        )
    }
    
    /// Scatter plot trace displaying springs as lines.
    var springsTrace: Plotly.Trace {
        let attachments = springs.flatMap { spring -> [Vector?] in
            [balls[spring.attached.from].position, balls[spring.attached.to].position, nil]
        }
        let labels = springs.indices.flatMap { i -> [String] in
            ["Spring \(i)", "Spring \(i)", ""]
        }
        return Scatter(
            name: "Springs",
            x: attachments.map { $0?.x ?? nil },
            y: attachments.map { $0?.y ?? nil },
            hoverText: .variable(labels),
            mode: .lines,
            line: .init(color: .lightGreen, width: 1)
        )
    }
}


extension Collection where Element == World {
    /// Chart that shows animated evolution of a sequence of world states.
    var animationChart: Plotly.Figure {
        var frames = [Frame]()
        var sliderSteps = [Layout.Slider.Step]()
        for (offset, world) in enumerated() {
            if (offset % 10) != 0 { continue }

            let frame = Frame(name: String(format: "%.2f", world.time),
                              data: [world.springsTrace, world.ballsTrace])
            frames.append(frame)

            let sliderStep = Layout.Slider.Step(method: .animate, args: [[.string(frame.name!)]],
                                                label: frame.name!)
            sliderSteps.append(sliderStep)
        }

        let slider = Layout.Slider(
            //active: Double(frames.count - 1),
            steps: sliderSteps,
            length: 0.9,
            x: 0.1,
            padding: .init(t: 50, b: 10),
            xAnchor: .left,
            y: 0.0, yAnchor: .top,
            transition: .init(duration: 0),
            currentValue: .init(visible: true, prefix: "Time: ", suffix: " s"),
            name: "Time"
        )
        
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
        
        let layout = Layout(
            title: "Mass-Spring System Animation",
            width: 600, height: 600,
            updateMenus: [
                Layout.UpdateMenu(
                    type: .buttons,
                    direction: .left,
                    showActive: false,
                    buttons: [playButton],
                    x: 0.1, xAnchor: .right,
                    y: 0.03, yAnchor: .top,
                    padding: .init(t: 80, r: 10)
                )
            ],
            sliders: [slider]
        )

        return Figure(data: frames[Int(layout.sliders?[0].active ?? 0)].data,
                      layout: layout, frames: frames)
    }

    /// Chart that displays evolution of the area of the triangle formed by the first 3 balls.
    var areaChart: Plotly.Figure {
        let areaTrace = Scatter(
            x: map(\.time),
            y: map(\.area),
            mode: .lines
        )
        
        let layout = Layout(
            title: "Triangle Area Evolution",
            xAxis: .preset(title: "Time [s]"),
            yAxis: .preset(title: "Triangle Area")
        )

        return Figure(data: [areaTrace], layout: layout)
    }
}
