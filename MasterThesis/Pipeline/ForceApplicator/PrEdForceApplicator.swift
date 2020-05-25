//
//  ForceApplicator.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 22.02.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry

struct PrEdForceApplicator: ForceApplicator {
    var airPressureStrength: CGFloat = 3
    var angularResolutionStrength: CGFloat = 0.5
    var vertexVertexRepulsionStrength: CGFloat = 25
    var vertexEdgeRepulsionStrength: CGFloat = 10

    func forces(in graph: VertexWeightedGraph) -> [VertexWeightedGraph.Vertex: CGVector] {
        var forces = Dictionary(uniqueKeys: graph.vertices, initialValue: CGVector.zero)

        // Vertex-vertex repulsion
        for (u, v) in graph.vertices.strictlyTriangularPairs() {
            let uv = graph.vector(from: u, to: v)
            let d = uv.length

            forces[u]! -= 1000 / pow(d, 2) * uv.normalized
            forces[v]! += 1000 / pow(d, 2) * uv.normalized
        }

        // Vertex-vertex attraction
        for (u, v) in graph.edges where u.rawValue < v.rawValue {
            let uv = graph.vector(from: u, to: v)
            let d = uv.length

            forces[u]! += 1 * log(d / 100) * uv.normalized
            forces[v]! -= 1 * log(d / 100) * uv.normalized
        }

        // Vertex-edge repulsion to avoid degenerate triangles
        for (u, (v, w)) in graph.vertices.cartesianProduct(with: graph.edges) where u != v && u != w {
            let segment = graph.segment(from: v, to: w)
            let p = segment.closestPoint(to: graph.position(of: u))

            let up = graph.vector(from: u, to: p)
            let d = up.length

            forces[u]! -= 1000 / pow(d, 2) * up.normalized
        }

        return forces
    }

    func applyForces(to graph: inout VertexWeightedGraph) throws {
        self.apply(self.forces(in: graph), to: &graph, edgesToCheck: graph.computeEdgesAndVerticesToCheck().0)
    }

    func forces(in graph: PolygonalDual) -> [PolygonalDual.Vertex: CGVector] {
        let (edgesToCheck, verticesToCheck) = graph.storage.edgesAndVerticesToCheck

        return self.forces(in: graph, edgesToCheck: edgesToCheck, verticesToCheck: verticesToCheck)
    }

    private func forces(in graph: PolygonalDual, edgesToCheck: [PolygonalDual.Vertex: DirectedEdgeSet<PolygonalDual.Vertex>], verticesToCheck: [PolygonalDual.Vertex: OrderedSet<PolygonalDual.Vertex>]) -> [PolygonalDual.Vertex: CGVector] {
        var forces = Dictionary(uniqueKeys: graph.vertices, initialValue: CGVector.zero)

        let totalweight = graph.faces.map(graph.weight(of:)).reduce(0, +).rawValue
        let totalarea = graph.faces.map(graph.area(of:)).reduce(0, +)

        // Air Pressure (Alam)
        if self.airPressureStrength > 0 {
            for face in graph.faces {
                let weight = graph.weight(of: face).rawValue
                let area = graph.area(of: face)
                let pressure = CGFloat((weight / totalweight) / (area / totalarea))

                let edges = graph.boundary(of: face).adjacentPairs(wraparound: true)
                let length = edges.map(graph.distance(from:to:)).reduce(0, +)

                for (u, v) in edges {
                    let fraction = graph.distance(from: u, to: v) / length
                    let vector = graph.vector(from: u, to: v).rotated(by: .degrees(-90)).normalized

                    forces[u]! += self.airPressureStrength * sanitize(pressure * fraction * vector)
                    forces[v]! += self.airPressureStrength * sanitize(pressure * fraction * vector)
                }
            }

            do {
                let edges = graph.internalFacesAndOuterFace().outer.vertices.adjacentPairs(wraparound: true)
                let length = edges.map(graph.distance(from:to:)).reduce(0, +)

                for (u, v) in edges {
                    let fraction = graph.distance(from: u, to: v) / length
                    let vector = graph.vector(from: u, to: v).rotated(by: .degrees(-90)).normalized

                    forces[u]! += self.airPressureStrength * sanitize(1 * fraction * vector)
                    forces[v]! += self.airPressureStrength * sanitize(1 * fraction * vector)
                }
            }
        }

        if self.angularResolutionStrength > 0 {
            for v in graph.vertices {
                for (u, w) in graph.vertices(adjacentTo: v).adjacentPairs(wraparound: true) {
                    let currentAngle = graph.angle(from: u, via: v, to: w).counterclockwise
                    let preferredAngle = Angle(degrees: 360) / graph.degree(of: v)
                    let fraction = (preferredAngle - currentAngle) / currentAngle

                    let bisector = graph.vector(from: v, to: u).normalized.rotated(by: currentAngle / 2)

                    forces[v]! += self.angularResolutionStrength * fraction * bisector
                }
            }
        }

        // Vertex-vertex repulsion
        if self.vertexVertexRepulsionStrength > 0 {
            for (u, vs) in verticesToCheck {
                for v in vs {
                    precondition(u != v)

                    let uv = graph.vector(from: u, to: v)
                    let d = uv.length

                    forces[u]! -= self.vertexVertexRepulsionStrength * sanitize(uv.normalized / pow(d, 2))
                    forces[v]! += self.vertexVertexRepulsionStrength * sanitize(uv.normalized / pow(d, 2))
                }
            }
        }

        // Vertex-edge repulsion (ours)
        if self.vertexEdgeRepulsionStrength > 0 {
            for (u, edges) in edgesToCheck {
                for (v,w) in edges {
                    precondition(u != v && u != w)

                    let segment = graph.segment(from: v, to: w)
                    let p = segment.closestPoint(to: graph.position(of: u))

                    let up = graph.vector(from: u, to: p)
                    let d = up.length

                    let angle = Angle(from: CGVector(from: p, to: graph.position(of: u)), to: graph.vector(from: v, to: w).rotated(by: .degrees(90)))
                    let factor = abs(cos(angle))

                    forces[u]! -= self.vertexEdgeRepulsionStrength * factor * sanitize(up.normalized / pow(d, 2))
                }
            }
        }

        return forces
    }

    func applyForces(to graph: inout PolygonalDual) throws {
        let (edgesToCheck, verticesToCheck) = graph.storage.edgesAndVerticesToCheck
        let forces = self.forces(in: graph, edgesToCheck: edgesToCheck, verticesToCheck: verticesToCheck)
        self.apply(forces, to: &graph, edgesToCheck: edgesToCheck)
    }
}


extension PrEdForceApplicator {
    private func apply<Graph>(_ forces: [Graph.Vertex: CGVector], to graph: inout Graph, edgesToCheck: [Graph.Vertex: DirectedEdgeSet<Graph.Vertex>]) where Graph: StraightLineGraph {
        let upperBounds = self.computeMaximumAmplitudes(in: graph, edgesToCheck: edgesToCheck)

        for (vertex, force) in forces where force != .zero {
            let upperBound = upperBounds[vertex]!.upperBound(inDirectionOf: force)
            var displacement = force

            if displacement.length > upperBound {
                displacement = upperBound * displacement.normalized
            }

            graph.displace(vertex, by: displacement)
        }

        // Centering
        let centroid = CGPoint.centroid(of: graph.vertices.map(graph.position(of:)))
        for vertex in graph.vertices {
            graph.displace(vertex, by: 1e-1 * CGVector(from: centroid, to: .zero))
        }
    }

    private func computeMaximumAmplitudes<Graph>(in graph: Graph, edgesToCheck: [Graph.Vertex: DirectedEdgeSet<Graph.Vertex>]) -> [Graph.Vertex: UpperBounds] where Graph: StraightLineGraph {
        var upperBounds: [Graph.Vertex: UpperBounds] = [:]
        for vertex in graph.vertices {
            upperBounds[vertex] = UpperBounds(numberOfArcs: 8)
        }

        for (v, edges) in edgesToCheck {
            for (a, b) in edges {
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

private func sanitize(_ vector: CGVector) -> CGVector {
    if vector.dx.isNaN || vector.dy.isNaN {
        print("oh noes!")
    }
    return vector
}

private extension Dictionary {
    init<S>(uniqueKeys keys: S, initialValue: Value) where S: Sequence, S.Element == Key {
        self.init(uniqueKeysWithValues: zip(keys, sequence(first: initialValue, next: { $0 })))
    }
}
