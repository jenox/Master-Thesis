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
    var airPressureStrength: CGFloat = 3 // 1
    var angularResolutionStrength: CGFloat = 0.5 // 1
    var vertexVertexRepulsionStrength: CGFloat = 25 // 25
    var vertexEdgeRepulsionStrength: CGFloat = 10 // 10

    func forces(in graph: PolygonalDual) -> [PolygonalDual.Vertex: CGVector] {
        var forces = Dictionary(uniqueKeys: graph.vertices, initialValue: CGVector.zero)

        let totalweight = graph.faces.map(graph.weight(of:)).reduce(0, +).rawValue
        let totalarea = graph.faces.map(graph.area(of:)).reduce(0, +)

        // Precompute stuff to check like in ImPrEd
        var verticesToCheck: [PolygonalDual.Vertex: OrderedSet<PolygonalDual.Vertex>] = [:]
        var edgesToCheck: [PolygonalDual.Vertex: DirectedEdgeSet<PolygonalDual.Vertex>] = [:]
        for face in graph.allFaces() {
            for vertex in face.vertices {
                for (u,v) in face.vertices.adjacentPairs(wraparound: true) where vertex != u && vertex != v {
                    edgesToCheck[vertex, default: []].insert((u,v))
                }
                for v in face.vertices where v != vertex {
                    verticesToCheck[vertex, default: []].insert(v)
                }
            }
        }

        // Air Pressure (Alam)
        if self.airPressureStrength > 0 {
            let outerfaceedges = graph.internalFacesAndOuterFace().outer.vertices.adjacentPairs(wraparound: true)

            for face in graph.faces {
                let weight = graph.weight(of: face).rawValue
                let area = graph.area(of: face)
                let pressure = CGFloat((weight / totalweight) / (area / totalarea))

                let edges = graph.boundary(of: face).adjacentPairs(wraparound: true)
                let length = edges.map(graph.distance(from:to:)).reduce(0, +)

                for (u, v) in edges {
                    if !outerfaceedges.contains(where: { $0 == (u,v) || $0 == (v,u) }) {
                    }

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

//        // Angular Resolution (ours)
//        if self.angularResolutionStrength > 0 {
//            for face in graph.faces {
//                let polygon = graph.polygon(for: face)
//
//                for (index, vertex) in graph.boundary(of: face).enumerated() {
//                    let (normal, angle) = polygon.normalAndAngle(at: index)
//                    let inside = Angle(turns: 1) - angle
//                    let desired = Angle(degrees: 180 * (CGFloat(polygon.points.count) - 2) / CGFloat(polygon.points.count))
//
//                    // small angle -> move inside -> negative sign
//                    // large angle -> move outside -> positive sign
//                    let over = (inside - desired) / (Angle(turns: 1) - desired) // fraction over
//                    let under = (desired - inside) / desired // fraction under
//                    let factor = inside > desired ? over : -under
//
//                    forces[vertex]! += self.angularResolutionStrength * sanitize(factor * normal)
//                }
//            }
//        }

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

//        // Angular Resolution (ABS13) | bad like this. blows things up, would need strong gravity.
//        if self.angularResolutionStrength > 0 {
//            for v in graph.vertices {
//                for (u, w) in graph.vertices(adjacentTo: v).adjacentPairs(wraparound: true) {
//                    let currentAngle = graph.angle(from: u, via: v, to: w).counterclockwise
//                    let preferredAngle = Angle(degrees: 360) / graph.degree(of: v)
//                    let fraction = (currentAngle - preferredAngle) / currentAngle
//
//                    let bisector = graph.vector(from: v, to: u).normalized + graph.vector(from: v, to: w).normalized
//                    let vector: CGVector
//
//                    if bisector.length < 1e-10 {
//                        vector = CGVector(
//                            from: graph.position(of: v) + graph.vector(from: v, to: u).normalized,
//                            to: graph.position(of: v) + graph.vector(from: v, to: w).normalized
//                        ).normalized
//                    } else {
//                        vector = bisector.rotated(by: .degrees(90)).normalized
//                    }
//
//                    forces[u]! += self.angularResolutionStrength * sanitize(fraction * vector)
//                    forces[w]! += self.angularResolutionStrength * -sanitize(fraction * vector)
//                }
//            }
//        }

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

//        // Vertex-edge repulsion (PrEd) | bad like this. very unstable.
//        if self.vertexEdgeRepulsionStrength > 0 {
//            for (v, edges) in edgesToCheck {
//                for (u, w) in edges {
//                    precondition(v != u && v != w)
//
//                    let segment = graph.segment(from: u, to: w)
//                    if let p = segment.orthogonalProjection(of: graph.position(of: v)) {
//                        let factor = 1 / pow(graph.position(of: v).distance(to: p), 2)
//                        let vector = -graph.vector(from: v, to: p).normalized
//
//                        forces[v]! += self.vertexEdgeRepulsionStrength * sanitize(factor * vector)
//                        forces[u]! -= self.vertexEdgeRepulsionStrength * sanitize(factor * vector)
//                        forces[w]! -= self.vertexEdgeRepulsionStrength * sanitize(factor * vector)
//                    }
//                }
//            }
//        }

        return forces
    }

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
