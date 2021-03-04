import _Differentiation
import Plotly


struct Coop: Differentiable {
    var animal: Animal
    var brain: Brain

    @noDerivative let time: Double
    @noDerivative let timeStep = 0.001

    @differentiable(reverse)
    init(animal: Animal, brain: Brain, time: Double) {
        self.animal = animal
        self.brain = brain
        self.time = time
    }

    @differentiable(reverse)
    func evolved() -> Coop {
        let actuations = brain.actuations(at: time)
        let evolvedAnimal = animal.evolved(timeStep: timeStep, actuations: actuations)
        return Coop(animal: evolvedAnimal, brain: brain, time: time + timeStep)
    }

    @differentiable(reverse)
    func evolved(until terminationTime: Double) -> Coop {
        var world = self
        while world.time <= terminationTime {
            world = world.evolved()
        }
        return world
    }
}


// MARK: -

struct Evolution: Differentiable {
    var states: [Coop]
    
    init(states: [Coop]) {
        self.states = states
    }
}

extension Evolution {
    struct Visualization {
        var states: [Coop]
            
        var animation: Figure {
            var frames = [Frame]()
            var sliderSteps = [Layout.Slider.Step]()
            for (offset, world) in states.enumerated() {
                if (offset % 100) != 0 { continue }
                
                let joints = world.animal.visualization.joints
                let muscles = world.animal.visualization.muscles

                let frame = Frame(name: String(format: "%.2f", world.time),
                                  data: [muscles, joints])
                frames.append(frame)

                let sliderStep = Layout.Slider.Step(method: .animate,
                                                    args: [[.string(frame.name!)]],
                                                    label: frame.name!)
                sliderSteps.append(sliderStep)
            }

            let layout = Layout(
                title: "Animal Animation",
                width: 600, height: 600,
                sliders: [
                    Layout.Slider(active: 0, steps: sliderSteps,
                                  currentValue: .init(visible: true,
                                                      prefix: "Time: ", suffix: " s"),
                                  name: "Time")
                ]
            )

            return Figure(data: frames[Int(layout.sliders?[0].active ?? 0)].data,
                          layout: layout, frames: frames)
        }
    }
    var visualization: Visualization { Visualization(states: states) }
}


// MARK: - Animal in the Coop before Learning

let α = 0.01
let specimen = Animal.dog
var brain = Brain(for: specimen)

var coop = Coop(animal: specimen, brain: brain, time: 0.0)
var states = [coop]
while coop.time < 10.0 {
    coop = coop.evolved()
    states.append(coop)
}

var evolution = Evolution(states: states)
try evolution.visualization.animation.show()


// MARK: - Gradient Descent Optimization

@differentiable(reverse)
func distanceAtTheEndOfSimulation(_ initialCoop: Coop) -> Double {
    let terminalCoop = initialCoop.evolved(until: 10.0)
    return terminalCoop.animal.head.position.x
}

var losses = [Double]()
for _ in 0 ..< 50 {
    let coop = Coop(animal: specimen, brain: brain, time: 10.0)
    let (distance, 𝛁coop) = valueWithGradient(at: coop) { coop in
        return distanceAtTheEndOfSimulation(coop)
    }

    brain.move(by: 𝛁coop.brain) // TODO: scaled(by: α)
    losses.append(distance)

    print(𝛁coop.brain)
    print(distance)
}

try Figure(data: [Scatter(x: [Int](0 ..< losses.count), y: losses)],
           layout: Layout(title: "Distance at End of Simulation")).show()

try Figure(data: [Bar<[Int], [Double]>(y: brain.amplitudes)],
           layout: Layout(title: "Amplitudes")).show()
try Figure(data: [Bar<[Int], [Double]>(y: brain.phases)],
           layout: Layout(title: "Phases")).show()


// MARK: - Animal in the Wilderness after Learning

coop = Coop(animal: specimen, brain: brain, time: 0.0)
states = [coop]
while coop.time < 10.0 {
    coop = coop.evolved()
    states.append(coop)
}

evolution = Evolution(states: states)
try evolution.visualization.animation.show()
