//
//  ForceApplicator.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 22.02.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics

class ForceApplicator {
    func apply(_ forces: [FaceWeightedGraph.Vertex: CGVector], to graph: inout FaceWeightedGraph) {
        let upperBounds = self.computeMaximumAmplitudes(in: graph)

        for (vertex, force) in forces where force != .zero {
            let upperBound = upperBounds[vertex]!.upperBound(inDirectionOf: force)
            var displacement = force

            if displacement.length > upperBound {
                displacement = upperBound * displacement.normalized
            }

            graph.setPosition(graph.position(of: vertex) + displacement, of: vertex)
        }
    }

    private func computeMaximumAmplitudes(in graph: FaceWeightedGraph) -> [FaceWeightedGraph.Vertex: UpperBounds] {
        var upperBounds: [FaceWeightedGraph.Vertex: UpperBounds] = [:]
        for vertex in graph.vertices {
            upperBounds[vertex] = UpperBounds(numberOfArcs: 8)
        }

        for (v, (a, b)) in graph.vertices.cartesian(with: graph.edges) where v != a && v != b {
            if let projected = graph.position(of: v).projected(onto: graph.segment(from: a, to: b)) {
                let vector = graph.vector(from: v, to: projected)

                upperBounds[v]!.addUpperBound(vector.length / 3, inDirectionOf: vector, padding: 2)
                upperBounds[a]!.addUpperBound(vector.length / 3, inDirectionOf: -vector, padding: 2)
                upperBounds[b]!.addUpperBound(vector.length / 3, inDirectionOf: -vector, padding: 2)
            } else {
                let distanceToA = graph.distance(from: v, to: a)
                let distanceToB = graph.distance(from: v, to: b)

                upperBounds[a]!.addUpperBound(distanceToA / 3)
                upperBounds[b]!.addUpperBound(distanceToB / 3)
                upperBounds[v]!.addUpperBound(min(distanceToA, distanceToB) / 3)
            }
        }

        return upperBounds
    }
}

private struct UpperBounds {
    init(numberOfArcs: Int = 8) {
        self.numberOfArcs = numberOfArcs
        self.amplitudes = Array(repeating: .infinity, count: numberOfArcs)
    }

    let numberOfArcs: Int
    private var amplitudes: [CGFloat]

    mutating func addUpperBound(_ upperBound: CGFloat) {
        for index in 0..<self.numberOfArcs {
            self.amplitudes[index].formMinimum(with: upperBound)
        }
    }

    mutating func addUpperBound(_ upperBound: CGFloat, inDirectionOf vector: CGVector, padding: Int) {
        let index = self.index(for: vector)
        let count = self.numberOfArcs

        for offset in -padding...padding {
            self.amplitudes[(index + offset + count) % count].formMinimum(with: upperBound)
        }
    }

    func upperBound(inDirectionOf vector: CGVector) -> CGFloat {
        return self.amplitudes[self.index(for: vector)]
    }

    private func index(for vector: CGVector) -> Int {
        let direction = Angle.direction(of: vector)
        let fractionalIndex = CGFloat(self.numberOfArcs) * direction.counterclockwise.turns

        return Int(fractionalIndex)
    }
}
