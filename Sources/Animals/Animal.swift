import _Differentiation
import Plotly


struct Animal: Differentiable {

    struct Joint: Differentiable, Hashable {
        var mass: Double = 1.0
        var position, velocity: Vector
    }
    var joints: [Joint]
    
    @differentiable(reverse)
    var head: Joint {
        return joints[headIdx]
    }
    @noDerivative
    private var headIdx: Int

    struct Muscle: Differentiable, Hashable {
        var freeLength, stiffness, damping: Double
        @noDerivative var actuation: Double?

        struct Attached: Hashable {
            var from, to: Int
        }
        @noDerivative var attached: Attached

        init(freeLength: Double, stiffness: Double, damping: Double,
             attached: (from: Int, to: Int), actuation: Double? = nil) {
            self.freeLength = freeLength
            self.stiffness = stiffness
            self.damping = damping
            self.attached = Attached(from: attached.from, to: attached.to)
            self.actuation = actuation
        }

        init(freeLengthFrom joints: [Joint], stiffness: Double, damping: Double,
             attached: (from: Int, to: Int), actuation: Double? = nil) {
            self.init(freeLength: 0.0, stiffness: stiffness, damping: damping,
                  attached: attached, actuation: actuation)
            self.freeLength = length(joints: joints)
        }

        @differentiable(reverse)
        func force(joints: [Joint], activation: Double = 0) -> Vector {
            let (fromJoint, toJoint) = (joints[attached.from], joints[attached.to])
            let distance = fromJoint.position - toJoint.position
            let velocity = fromJoint.velocity - toJoint.velocity
            
            var actuatedLength = self.freeLength
            if let actuation = self.actuation {
                 actuatedLength += activation * actuation
            }

            let dampingForce = damping * velocity
            let tensionForce = stiffness * (actuatedLength * distance.normalized - distance)
            return tensionForce - dampingForce
        }
        
        @differentiable(reverse)
        func length(joints: [Joint]) -> Double {
            let (fromJoint, toJoint) = (joints[attached.from], joints[attached.to])
            return (fromJoint.position - toJoint.position).magnitude
        }
    }
    var muscles: [Muscle]

    @differentiable(reverse)
    init(joints: [Joint], muscles: [Muscle], headIdx: Int) {
        self.joints = joints
        self.muscles = muscles
        self.headIdx = headIdx
    }

    @differentiable(reverse)
    func evolved(timeStep: Double, gravity: Vector = [0, -9.81], ground: Double = 0.0,
                 actuations: [Double]) -> Animal {
        precondition(actuations.count == muscles.count)

        var forces = [Vector](repeating: .zero, count: withoutDerivative(at: joints.count))
        for i in withoutDerivative(at: 0 ..< muscles.count) {
            let muscle = muscles[i]

            let force = muscle.force(joints: joints, activation: actuations[i])
            forces = forces.updated(at: muscle.attached.from,
                                    with: forces[muscle.attached.from] + force)
            forces = forces.updated(at: muscle.attached.to,
                                    with: forces[muscle.attached.to] - force)

            // FIXME: Once co-routine differentiation is implemented use the code below
            // forces[muscle.attached.from] += force
            // forces[muscle.attached.to] -= force
        }

        var evolvedJoints = [Joint]()
        for i in withoutDerivative(at: 0 ..< joints.count) {
            var joint = joints[i]
            var timeOfImpact = 0.0
            
            let oldVelocity = joint.velocity + timeStep * (forces[i] / joint.mass + gravity)
            let oldPosition = joint.position
            
            var evolvedVelocity = oldVelocity
            let evolvedPosition = oldPosition + timeStep * oldVelocity

            // FIXME: (evolvedPosition.y < ground && evolvedVelocity.y < 1e-4) doesn't work
            if evolvedPosition.y < ground {
                if evolvedVelocity.y < 1e-4 {
                    timeOfImpact = (ground - oldPosition.y) / oldVelocity.y
                    evolvedVelocity = .zero
                }
            }

            joint.velocity = evolvedVelocity
            joint.position = oldPosition + timeOfImpact * oldVelocity + (timeStep - timeOfImpact) * evolvedVelocity
            
            evolvedJoints.append(joint)
        }
        
        return Animal(joints: evolvedJoints, muscles: muscles, headIdx: headIdx)
    }
    

}


extension Animal {
    static var triangle: Animal {
        let joints = [
            Joint(position: .zero, velocity: .zero),
            Joint(position: .unitX, velocity: .zero),
            Joint(position: .unitY, velocity: .zero)
        ]
        let muscles = [
            Muscle(freeLengthFrom: joints, stiffness: 1.0, damping: 1.0,
                   attached: (from: 0, to: 1)),
            Muscle(freeLengthFrom: joints, stiffness: 1.0, damping: 1.0,
                   attached: (from: 1, to: 2)),
            Muscle(freeLengthFrom: joints, stiffness: 1.0, damping: 1.0,
                   attached: (from: 2, to: 0))
        ]
        return Animal(joints: joints, muscles: muscles, headIdx: 0)
    }
    
    static var worm: Animal {
        let stiffness = 10_000.0
        let actuation = 0.15
        let damping = 1.0

        let joints = [
            Joint(position: [0, 0], velocity: .zero),
            Joint(position: [1, 0.3], velocity: .zero),
            Joint(position: [2, 0], velocity: .zero),
            Joint(position: [0, 1], velocity: .zero),
            Joint(position: [1, 1], velocity: .zero),
            Joint(position: [2, 1], velocity: .zero)
        ]
        let muscles = [
            Muscle(freeLengthFrom: joints, stiffness: stiffness, damping: damping,
                   attached: (from: 0, to: 1), actuation: actuation),
            Muscle(freeLengthFrom: joints, stiffness: stiffness, damping: damping,
                   attached: (from: 1, to: 2), actuation: actuation),
            Muscle(freeLengthFrom: joints, stiffness: stiffness, damping: damping,
                   attached: (from: 3, to: 4), actuation: actuation),
            Muscle(freeLengthFrom: joints, stiffness: stiffness, damping: damping,
                   attached: (from: 4, to: 5), actuation: actuation),
            Muscle(freeLengthFrom: joints, stiffness: stiffness, damping: damping,
                   attached: (from: 0, to: 3), actuation: actuation),
            Muscle(freeLengthFrom: joints, stiffness: stiffness, damping: damping,
                   attached: (from: 2, to: 5), actuation: actuation),
            Muscle(freeLengthFrom: joints, stiffness: stiffness, damping: damping,
                   attached: (from: 0, to: 4), actuation: actuation),
            Muscle(freeLengthFrom: joints, stiffness: stiffness, damping: damping,
                   attached: (from: 1, to: 4), actuation: actuation),
            Muscle(freeLengthFrom: joints, stiffness: stiffness, damping: damping,
                   attached: (from: 2, to: 4), actuation: actuation),
            Muscle(freeLengthFrom: joints, stiffness: stiffness, damping: damping,
                   attached: (from: 3, to: 1), actuation: actuation),
            Muscle(freeLengthFrom: joints, stiffness: stiffness, damping: damping,
                   attached: (from: 5, to: 1), actuation: actuation)
        ]
        return Animal(joints: joints, muscles: muscles, headIdx: 5)
    }

    static var dog: Animal {
        let stiffness = 10_000.0
        let actuation = 0.15
        let damping = 1.0

        var joints = [Joint]()
        var muscles = [Muscle]()
        
        let rearLeg: Vector = [0, 0.5]
        insertSquare(into: &joints, and: &muscles, bottomLeftCorner: rearLeg,
                     stiffness: stiffness, damping: damping, actuation: actuation)
        insertTriangle(into: &joints, and: &muscles, topLeftCorner: rearLeg,
                       stiffness: stiffness, damping: damping)

        let body0: Vector = [0, 1.5]
        let body1: Vector = [1, 1.5]
        let body2: Vector = [2, 1.5]
        insertSquare(into: &joints, and: &muscles, bottomLeftCorner: body0,
                     stiffness: stiffness, damping: damping)
        insertSquare(into: &joints, and: &muscles, bottomLeftCorner: body1,
                     stiffness: stiffness, damping: damping)
        insertSquare(into: &joints, and: &muscles, bottomLeftCorner: body2,
                     stiffness: stiffness, damping: damping)

        let frontLeg: Vector = [2, 0.5]
        insertSquare(into: &joints, and: &muscles, bottomLeftCorner: frontLeg,
                     stiffness: stiffness, damping: damping, actuation: actuation)
        insertTriangle(into: &joints, and: &muscles, topLeftCorner: frontLeg,
                       stiffness: stiffness, damping: damping)

        return Animal(joints: joints, muscles: muscles, headIdx: 0)
    }
    
    static var giraffe: Animal {
        let stiffness = 10_000.0
        let actuation = 0.15
        let damping = 1.0

        var joints = [Joint]()
        var muscles = [Muscle]()
        
        let rearPaw: Vector = [0, 0]
        let rearLeg: Vector = [0, 1]
        insertSquare(into: &joints, and: &muscles, bottomLeftCorner: rearPaw,
                     stiffness: stiffness, damping: damping, actuation: actuation)
        insertSquare(into: &joints, and: &muscles, bottomLeftCorner: rearLeg,
                     stiffness: stiffness, damping: damping, actuation: actuation)

        let body0: Vector = [0, 2]
        let body1: Vector = [1, 2]
        let body2: Vector = [2, 2]
        insertSquare(into: &joints, and: &muscles, bottomLeftCorner: body0,
                     stiffness: stiffness, damping: damping)
        insertSquare(into: &joints, and: &muscles, bottomLeftCorner: body1,
                     stiffness: stiffness, damping: damping)
        insertSquare(into: &joints, and: &muscles, bottomLeftCorner: body2,
                     stiffness: stiffness, damping: damping)
        
        let head: Vector = [2, 4]
        let neck: Vector = [2, 3]
        insertSquare(into: &joints, and: &muscles, bottomLeftCorner: head,
                     stiffness: stiffness, damping: damping)
        insertSquare(into: &joints, and: &muscles, bottomLeftCorner: neck,
                     stiffness: stiffness, damping: damping)

        let frontPaw: Vector = [2, 0]
        let frontLeg: Vector = [2, 1]
        insertSquare(into: &joints, and: &muscles, bottomLeftCorner: frontPaw,
                     stiffness: stiffness, damping: damping, actuation: actuation)
        insertSquare(into: &joints, and: &muscles, bottomLeftCorner: frontLeg,
                     stiffness: stiffness, damping: damping, actuation: actuation)

        return Animal(joints: joints, muscles: muscles, headIdx: 0)
    }

    static private func insertTriangle(into joints: inout [Joint], and muscles: inout [Muscle],
                               topLeftCorner position: Vector, stiffness: Double = 10_000.0,
                               damping: Double = 1.0, size: Double = 1.0) {

        let topLeft = Joint(position: position + [0, 0], velocity: .zero)
        let topRight = Joint(position: position + [size, 0], velocity: .zero)
        let bottomCenter = Joint(position: position + [size / 2, -size / 2], velocity: .zero)
        
        let topLeftIdx = joints.append(unique: topLeft)
        let topRightIdx = joints.append(unique: topRight)
        let bottomCenterIdx = joints.append(unique: bottomCenter)
        
        let top = Muscle(freeLengthFrom: joints, stiffness: stiffness, damping: damping,
                         attached: (from: topLeftIdx, to: topRightIdx))
        let left = Muscle(freeLengthFrom: joints, stiffness: stiffness, damping: damping,
                          attached: (from: topLeftIdx, to: bottomCenterIdx))
        let right = Muscle(freeLengthFrom: joints, stiffness: stiffness, damping: damping,
                           attached: (from: topRightIdx, to: bottomCenterIdx))

        muscles.append(unique: top)
        muscles.append(unique: left)
        muscles.append(unique: right)
    }

    static private func insertSquare(into joints: inout [Joint], and muscles: inout [Muscle],
                             bottomLeftCorner position: Vector, stiffness: Double = 10_000.0,
                             damping: Double = 1.0, size: Double = 1.0, actuation: Double? = nil) {

        let bottomLeft = Joint(position: position + [0, 0], velocity: .zero)
        let bottomRight = Joint(position: position + [size, 0], velocity: .zero)
        let topRight = Joint(position: position + [size, size], velocity: .zero)
        let topLeft = Joint(position: position + [0, size], velocity: .zero)

        let bottomLeftIdx = joints.append(unique: bottomLeft)
        let bottomRightIdx = joints.append(unique: bottomRight)
        let topRightIdx = joints.append(unique: topRight)
        let topLeftIdx = joints.append(unique: topLeft)

        let bottom = Muscle(freeLengthFrom: joints, stiffness: stiffness, damping: damping,
                            attached: (from: bottomLeftIdx, to: bottomRightIdx))
        let right = Muscle(freeLengthFrom: joints, stiffness: stiffness, damping: damping,
                           attached: (from: bottomRightIdx, to: topRightIdx), actuation: actuation)
        let top = Muscle(freeLengthFrom: joints, stiffness: stiffness, damping: damping,
                         attached: (from: topRightIdx, to: topLeftIdx))
        let left = Muscle(freeLengthFrom: joints, stiffness: stiffness, damping: damping,
                          attached: (from: topLeftIdx, to: bottomLeftIdx), actuation: actuation)
        let diagonal0 = Muscle(freeLengthFrom: joints, stiffness: stiffness, damping: damping,
                               attached: (from: bottomLeftIdx, to: topRightIdx))
        let diagonal1 = Muscle(freeLengthFrom: joints, stiffness: stiffness, damping: damping,
                               attached: (from: bottomRightIdx, to: topLeftIdx))

        muscles.append(unique: bottom)
        muscles.append(unique: right)
        muscles.append(unique: top)
        muscles.append(unique: left)
        muscles.append(unique: diagonal0)
        muscles.append(unique: diagonal1)
    }
}



extension Animal {
    struct Visualization {
        var animal: Animal

        var joints: Trace {
            Scatter(
                name: "Joints",
                hoverInfo: .text,
                x: animal.joints.map { $0.position.x },
                y: animal.joints.map { $0.position.y },
                text: .variable(animal.joints.map { String(describing: $0) }),
                mode: .markers,
                marker: .init(size: 15, coloring: .constant(.green))
            )
        }

        var muscles: Trace {
            let muscleAttachments = animal.muscles.flatMap { muscle in
                [animal.joints[muscle.attached.from], animal.joints[muscle.attached.to], nil]
            }
            return Scatter(
                name: "Muscles",
                hoverInfo: .text,
                x: muscleAttachments.map { $0?.position.x },
                y: muscleAttachments.map { $0?.position.y },
                text: .variable(animal.muscles.map { String(describing: $0) }),
                mode: .lines,
                line: .init(color: .lightGreen, width: 1)
            )
        }
    }

    var visualization: Visualization { Visualization(animal: self) }
}


extension Array where Array.Element: Equatable {
    @discardableResult
    mutating func append(unique element: Element) -> Index {
        if let elementIdx = firstIndex(of: element) {
            return elementIdx
        } else {
            append(element)
            return count - 1
        }
    }
}
