//
//  ForceComputer.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 22.02.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry

struct ConcreteForceComputer: ForceComputer {
    var force1Strength: CGFloat = 25
    var force2Strength: CGFloat = 0
    var force3Strength: CGFloat = 10
    var force4Strength: CGFloat = 1
    var force5Strength: CGFloat = 1

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

        // Gravity
        for v in graph.vertices {
            forces[v]! += 0.001 * graph.vector(from: v, to: .zero)
        }

        return forces
    }

    func forces(in graph: PolygonalDual) -> [PolygonalDual.Vertex: CGVector] {
        var forces = Dictionary(uniqueKeys: graph.vertices, initialValue: CGVector.zero)

        let totalweight = graph.faces.map(graph.weight(of:)).reduce(0, +).rawValue
        let totalarea = graph.faces.map(graph.area(of:)).reduce(0, +)

        // Vertex-vertex repulsion
        if self.force1Strength > 0 {
            for (u, v) in graph.vertices.strictlyTriangularPairs() {
                let uv = graph.vector(from: u, to: v)
                let d = uv.length

                forces[u]! -= self.force1Strength / pow(d, 2) * uv.normalized
                forces[v]! += self.force1Strength / pow(d, 2) * uv.normalized
            }
        }

        // Vertex-vertex attraction
        if self.force2Strength > 0 {
            for (u, v) in graph.edges where u < v {
                let uv = graph.vector(from: u, to: v)
                let d = uv.length

                forces[u]! += self.force2Strength * log(d / 100) * uv.normalized
                forces[v]! -= self.force2Strength * log(d / 100) * uv.normalized
            }
        }

        // Vertex-edge repulsion
        if self.force3Strength > 0 {
            for (u, (v, w)) in graph.vertices.cartesianProduct(with: graph.edges) where v < w && u != v && u != w {
                let segment = graph.segment(from: v, to: w)
                let p = segment.closestPoint(to: graph.position(of: u))

                let up = graph.vector(from: u, to: p)
                let d = up.length

                forces[u]! -= self.force3Strength / pow(d, 2) * up.normalized
            }
        }

        // Pressure
        if self.force4Strength > 0 {
            for face in graph.faces {
                let weight = graph.weight(of: face).rawValue
                let area = graph.area(of: face)
                let pressure = CGFloat((weight / totalweight) / (area / totalarea))

                let polygon = graph.polygon(for: face)

                for (index, vertex) in graph.boundary(of: face).enumerated() {
                    forces[vertex]! += self.force4Strength * log(pressure) * polygon.normalAndAngle(at: index).normal
                }
            }
        }

        // Angle
        if self.force5Strength > 0 {
            for face in graph.faces {
                let polygon = graph.polygon(for: face)

                for (index, vertex) in graph.boundary(of: face).enumerated() {
                    let (normal, angle) = polygon.normalAndAngle(at: index)
                    let inside = Angle(turns: 1) - angle
                    let desired = Angle(degrees: 180 * (CGFloat(polygon.points.count) - 2) / CGFloat(polygon.points.count))

                    // small angle -> move inside -> negative sign
                    // large angle -> move outside -> positive sign
                    let over = (inside - desired) / (Angle(turns: 1) - desired) // fraction over
                    let under = (desired - inside) / desired // fraction under
                    let factor = inside > desired ? over : -under

                    forces[vertex]! += self.force5Strength * factor * normal
                }
            }
        }

        return forces
    }
}

private extension Dictionary {
    init<S>(uniqueKeys keys: S, initialValue: Value) where S: Sequence, S.Element == Key {
        self.init(uniqueKeysWithValues: zip(keys, sequence(first: initialValue, next: { $0 })))
    }
}
