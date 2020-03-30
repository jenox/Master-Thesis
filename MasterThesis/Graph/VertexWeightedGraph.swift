//
//  Data.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 12.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry

struct UndirectedEdge: Equatable, Hashable {
    var first: ClusterName
    var second: ClusterName

    func hash(into hasher: inout Hasher) {
        Set([self.first, self.second]).hash(into: &hasher)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return Set([lhs.first, lhs.second]) == Set([rhs.first, rhs.second])
    }
}

// Input graph: straight-line plane, vertex-weighted
// internally triangulated, 2-connected
struct VertexWeightedGraph {
    typealias Vertex = ClusterName
    typealias Weight = ClusterWeight

    init() {}

    private(set) var vertices: [Vertex] = []
    private(set) var edges: [(Vertex, Vertex)] = []
    private var data: [Vertex: (CGPoint, Weight)] = [:]
    private var adjacencies: [Vertex: [Vertex]] = [:]

    mutating func insert(_ vertex: Vertex, at position: CGPoint, weight: Weight) {
        precondition(self.data[vertex] == nil)

        self.vertices.append(vertex)
        self.data[vertex] = (position, weight)
        self.adjacencies[vertex] = []
    }

    func containsEdge(between endpoint1: Vertex, and endpoint2: Vertex) -> Bool {
        return self.vertices(adjacentTo: endpoint1).contains(endpoint2)
    }

    mutating func insertEdge(between endpoint1: Vertex, and endpoint2: Vertex) {
        precondition(endpoint1 != endpoint2)
        precondition(!self.vertices(adjacentTo: endpoint1).contains(endpoint2))

        self.edges.append((endpoint1, endpoint2))
        self.adjacencies[endpoint1]!.append(endpoint2)
        self.adjacencies[endpoint2]!.append(endpoint1)
    }

    mutating func removeEdge(between u: Vertex, and v: Vertex) {
        precondition(u != v)
        precondition(self.vertices(adjacentTo: u).contains(v))

        self.edges.removeAll(where: { $0 == (u,v) || $0 == (v,u) })
        self.adjacencies[u]!.removeAll(where: { $0 == v })
        self.adjacencies[v]!.removeAll(where: { $0 == u })
    }

    func vertices(adjacentTo vertex: Vertex) -> [Vertex] {
        return self.adjacencies[vertex]!
    }

    // https://mathoverflow.net/questions/23811/reporting-all-faces-in-a-planar-graph
    // https://mosaic.mpi-cbg.de/docs/Schneider2015.pdf
    // https://www.boost.org/doc/libs/1_36_0/boost/graph/planar_face_traversal.hpp
    var faces: (inner: [Face<Vertex>], outer: Face<Vertex>) {
        var faces: [Face<Vertex>] = []
        var edges: OrderedSet<DirectedEdge> = []

        for vertex in self.vertices {
            for neighbor in self.vertices(adjacentTo: vertex) {
                edges.insert(DirectedEdge(from: vertex, to: neighbor))
            }
        }

        while let edge = edges.popFirst() {
            var vertices: [Vertex] = [edge.source, edge.target]
            var last = edge

            while true {
                let candidates = Set(self.vertices(adjacentTo: last.target).map({ DirectedEdge(from: last.target, to: $0) })).intersection(edges).subtracting([last.inverted()])
                let best = candidates.min(by: { (self.angle(of: $0) - self.angle(of: last.inverted())).counterclockwise })!

                last = best
                edges.remove(best)

                if vertices.contains(best.target) {
                    faces.append(Face(vertices: vertices.reversed()))
                    break
                } else {
                    vertices.append(best.target)
                }
            }
        }

        // outer face has negative area!
        let index = faces.partition(by: { self.area(of: $0) >= 0 })
        precondition(index == 1)

        return (inner: Array(faces.dropFirst()), outer: faces[0])
    }

    func position(of vertex: Vertex) -> CGPoint {
        return self.data[vertex]!.0
    }

    func weight(of vertex: Vertex) -> Weight {
        return self.data[vertex]!.1
    }

    func area(of face: Face<Vertex>) -> CGFloat {
        let positions = face.vertices.map({ self.position(of: $0) })

        var sum = positions.last!.x * positions.first!.y - positions.last!.y * positions.first!.x

        for (a, b) in zip(positions, positions.dropFirst()) {
            sum += a.x * b.y - a.y * b.x
        }

        return sum / 2
    }

    func angle(of edge: DirectedEdge) -> Angle {
        let vector = CGVector(from: self.position(of: edge.source), to: self.position(of: edge.target))

        return Angle.atan2(vector.dy, vector.dx)
    }

    mutating func setWeight(of vertex: Vertex, to weight: Weight) {
        self.data[vertex]!.1 = weight
    }
}
