import Foundation
import Plotly
import Swim


// MARK: Visualization of shallow water equation solution

/// Visualization of the solution at a particular time-step.
struct SolutionVisualization {
    let solution: Solution

    /// 3D plot of the water surface.
    var waterSurface: Plotly.Surface<[[Float]],[Float]> {
        let Δx = 1 / Float(solution.waterLevel.count)
        return Surface(
            z: solution.waterLevel,
            x: [Float](stride(from: Δx / 2, to: 1, by: Δx)),
            y: [Float](stride(from: Δx / 2, to: 1, by: Δx)),
            colorScale: .blues
        )
    }

    /// Top-down mosaic plot of the water level colored by its height.
    var waterLevel: Plotly.Heatmap<[[Float]],[Float]> {
        let Δx = 1 / Float(solution.waterLevel.count)
        return Heatmap(
            z: solution.waterLevel,
            x: [Float](stride(from: Δx / 2, to: 1, by: Δx)),
            y: [Float](stride(from: Δx / 2, to: 1, by: Δx)),
            zSmooth: .off,
            colorScale: .blues
        )
    }
    
    /// Top-down greyscale image of the water level colored by its height.
    var waterSchlieren: Swim.Image<Swim.Gray, Float> {
        let (width, height) = (solution.waterLevel.count, solution.waterLevel[0].count)
        let pixels = solution.waterLevel.flatMap { $0 }
        return Swim.Image(width: width, height: height, gray: pixels)
    }
}

extension Solution {
    var visualization: SolutionVisualization { SolutionVisualization(solution: self) }
}


// MARK: - Visualization of evolution of the solution in time

extension Array where Element == Solution {
    
    /// Visualization of the time evolution of the solution.
    struct EvolutionVisualization {
        let solutions: [Element]
        var interval = 8
        
        private let maxWaterLevel = 1.0
        private var playButton: Layout.UpdateMenu.Button {
            Layout.UpdateMenu.Button(
                method: .animate,
                args: [.null, .object([
                        "mode": "immediate",
                        "fromcurrent": true,
                        "transition": ["duration": 0],
                        "frame": ["duration": 50]
                    ])
                ],
                label: "▶"
            )
        }
        private var pauseButton: Layout.UpdateMenu.Button {
            Layout.UpdateMenu.Button(
                method: .animate,
                args: [[.null], .object([
                        "mode": "immediate",
                        "transition": ["duration": 0],
                        "frame": ["duration": 0, "redraw": false]
                    ])
                ],
                label: "❚❚"
            )
        }

        /// 3D animation of evolution of the water surface in time.
        var waterSurface: Figure {
            var frames = [Frame]()
            var sliderSteps = [Layout.Slider.Step]()
            for (offset, solution) in solutions.enumerated() {
                if !(offset % interval == 0 || offset == solutions.count - 1) { continue }

                var waterSurface = solution.visualization.waterSurface
                waterSurface.cMin = -maxWaterLevel
                waterSurface.cMax = +maxWaterLevel

                let frame = Frame(name: "\(offset)", data: [waterSurface])
                frames.append(frame)

                let sliderStep = Layout.Slider.Step(
                    method: .animate,
                    args: [[.string(frame.name!)]],
                    label: frame.name!
                )
                sliderSteps.append(sliderStep)
            }
            
            let layout = Layout(
                title: "Water Surface",
                width: 800, height: 800,
                updateMenus: [
                    Layout.UpdateMenu(
                        type: .buttons,
                        direction: .left,
                        showActive: false,
                        buttons: [playButton, pauseButton],
                        x: 0.1, xAnchor: .right,
                        y: 0.03, yAnchor: .top,
                        padding: .init(t: 87, r: 10)
                    )
                ],
                sliders: [
                    Layout.Slider(
                        active: 0,
                        steps: sliderSteps,
                        length: 0.9,
                        x: 0.1,
                        padding: .init(t: 50, b: 10),
                        xAnchor: .left,
                        y: 0.0, yAnchor: .top,
                        transition: .init(duration: 0),
                        currentValue: .init(visible: true, prefix: "Timestep: "),
                        name: "Timestep"
                    )
                ]
            )
            
            return Figure(
                data: frames[Int(layout.sliders?[0].active ?? 0)].data,
                layout: layout,
                frames: frames
            )
        }

        /// Top-down mosaic animation of the water level evolution colored by its height.
        var waterLevel: Figure {
            var frames = [Frame]()
            var sliderSteps = [Layout.Slider.Step]()
            for (offset, solution) in solutions.enumerated() {
                if !(offset % interval == 0 || offset == solutions.count - 1) { continue }

                
                var waterLevel = solution.visualization.waterLevel
                waterLevel.zMin = -maxWaterLevel
                waterLevel.zMax = +maxWaterLevel
                
                let frame = Frame(name: "\(offset)", data: [waterLevel])
                frames.append(frame)

                let sliderStep = Layout.Slider.Step(
                    method: .animate,
                    args: [[.string(frame.name!)]],
                    label: frame.name!
                )
                sliderSteps.append(sliderStep)
            }

            let layout = Layout(
                title: "Water Level",
                width: 800, height: 800,
                updateMenus: [
                    Layout.UpdateMenu(
                        type: .buttons,
                        direction: .left,
                        showActive: false,
                        buttons: [playButton, pauseButton],
                        x: 0.1, xAnchor: .right,
                        y: 0.03, yAnchor: .top,
                        padding: .init(t: 87, r: 10)
                    )
                ],
                sliders: [
                    Layout.Slider(
                        active: 0,
                        steps: sliderSteps,
                        length: 0.9,
                        x: 0.1,
                        padding: .init(t: 50, b: 10),
                        xAnchor: .left,
                        y: 0.0, yAnchor: .top,
                        transition: .init(duration: 0),
                        currentValue: .init(visible: true,prefix: "Timestep: "
                        ),
                        name: "Timestep"
                    )
                ]
            )

            return Figure(
                data: frames[Int(layout.sliders?[0].active ?? 0)].data,
                layout: layout,
                frames: frames
            )
        }
        
        /// Top-down greyscale video of the water level colored by its height.
        var waterSchlieren: Foundation.Data {
            let ffmpeg = Process()
            ffmpeg.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            ffmpeg.arguments = [
                "ffmpeg", "-v", "0",
                "-f", "bmp_pipe", "-i", "-",
                "-r", "15", "-f", "gif", "-"
            ]
            
            let path = ProcessInfo.processInfo.environment["PATH"] ?? ""
            ffmpeg.environment = ["PATH": "/usr/bin:/usr/local/bin:\(path)"]

            let inputPipe = Pipe()
            ffmpeg.standardInput = inputPipe
            let outputPipe = Pipe()
            ffmpeg.standardOutput = outputPipe
            
            var gifAnimation = Data()
            outputPipe.fileHandleForReading.readabilityHandler = { handle in
                gifAnimation.append(handle.availableData)
            }

            try! ffmpeg.run()

            for solution in solutions {
                let maxWaterLevel = Float(self.maxWaterLevel)
                let image = solution.visualization.waterSchlieren
                    .normalized(min: -maxWaterLevel, max: +maxWaterLevel)
                    .clipped(low: -maxWaterLevel, high: +maxWaterLevel)
                    .dataConverted { UInt8($0 * 127 / maxWaterLevel + 128) }
                    .toRGB()

                let imageData = try! image.fileData(format: .bitmap)
                inputPipe.fileHandleForWriting.write(imageData)
            }
            inputPipe.fileHandleForWriting.closeFile()

            ffmpeg.waitUntilExit()
            outputPipe.fileHandleForReading.closeFile()

            return gifAnimation
        }
        
    }
    
    var visualization: EvolutionVisualization { EvolutionVisualization(solutions: self) }
}


// MARK: - Utilities

fileprivate extension Swim.Image where P == Swim.Gray, T == Float {
    /// Returns image normalized from `min` and `max` range to standard 0 and 1 range.
    func normalized(min: T = -1, max: T = +1) -> Swim.Image<Swim.Gray, Float> {
        precondition(max > min)

        return dataConverted { pixel in
           return (pixel - min) / (max - min)
        }
    }
}

fileprivate extension Array where Element == [Float] {
  /// Returns a 2D grayscale image matrix clipped and normalized from the specified `range` to 0-255.
    func normalizedGrayscaleImage(to range: ClosedRange<Float> = -1 ... +1) -> Self {
        precondition(allSatisfy { $0.count == [1].count })

        var result = self
        for i in self.indices {
            for j in self[i].indices {
                let clipped = self[i][j].clipped(to: range)
                let normalized = (clipped - range.lowerBound) / range.span * Float(255.0)
                result[i][j] = normalized
            }
        }

        return result
    }
}

fileprivate extension BinaryFloatingPoint {
    func clipped(to range: ClosedRange<Self>) -> Self {
        if self < range.lowerBound { return range.lowerBound }
        if self > range.upperBound { return range.upperBound }
        return self
    }
}

fileprivate extension ClosedRange where Bound: AdditiveArithmetic {
    var span: Bound { upperBound - lowerBound }
}
