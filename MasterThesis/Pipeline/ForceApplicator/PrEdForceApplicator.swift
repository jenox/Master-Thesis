//
//  ForceApplicator.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 22.02.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry

class PrEdForceApplicator: ForceApplicator {
    func apply<Graph>(_ forces: [Graph.Vertex: CGVector], to graph: inout Graph) where Graph: StraightLineGraph {
        let upperBounds = self.computeMaximumAmplitudes(in: graph)

        for (vertex, force) in forces where force != .zero {
            let upperBound = upperBounds[vertex]!.upperBound(inDirectionOf: force)
            var displacement = force

            if displacement.length > upperBound {
                displacement = upperBound * displacement.normalized
            }

            graph.displace(vertex, by: displacement)
        }
    }

    private func computeMaximumAmplitudes<Graph>(in graph: Graph) -> [Graph.Vertex: UpperBounds] where Graph: StraightLineGraph {
        var upperBounds: [Graph.Vertex: UpperBounds] = [:]
        for vertex in graph.vertices {
            upperBounds[vertex] = UpperBounds(numberOfArcs: 8)
        }

        for (v, (a, b)) in graph.vertices.cartesianProduct(with: graph.edges) where v != a && v != b {
            if let projected = graph.position(of: v).projected(onto: graph.segment(from: a, to: b)) {
                let vector = graph.vector(from: v, to: projected)

                // If vector becomes too short, floating point inaccuracies can
                // still result in edge crossings being created — restrict
                // involved vertices altogether
                if vector.length >= 1e-12 {
                    upperBounds[v]!.addUpperBound(vector.length / 3, inDirectionOf: vector, padding: 2)
                    upperBounds[a]!.addUpperBound(vector.length / 3, inDirectionOf: -vector, padding: 2)
                    upperBounds[b]!.addUpperBound(vector.length / 3, inDirectionOf: -vector, padding: 2)
                } else {
                    upperBounds[v]!.addUpperBound(0)
                    upperBounds[a]!.addUpperBound(0)
                    upperBounds[b]!.addUpperBound(0)
                }
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

        return Int(fractionalIndex) % self.numberOfArcs
    }
}
