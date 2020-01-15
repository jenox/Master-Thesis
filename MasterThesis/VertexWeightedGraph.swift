//
//  Data.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 12.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics

// Input graph: straight-line plane, vertex-weighted
// internally triangulated, 2-connected
struct VertexWeightedGraph {
    typealias Vertex = Character
    typealias Weight = Double
    typealias Face = Set<Character>

    init() {}

    private var data: [Vertex: (CGPoint, Weight)] = [:]
    private var adjacencies: [Vertex: Set<Vertex>] = [:]

    mutating func insert(_ vertex: Vertex, at position: CGPoint, weight: Weight) {
        precondition(self.data[vertex] == nil)

        self.data[vertex] = (position, weight)
        self.adjacencies[vertex] = []
    }

    mutating func insertEdge(between endpoint1: Vertex, and endpoint2: Vertex) {
        precondition(endpoint1 != endpoint2)
        precondition(!self.vertices(adjacentTo: endpoint1).contains(endpoint2))

        self.adjacencies[endpoint1]!.insert(endpoint2)
        self.adjacencies[endpoint2]!.insert(endpoint1)
    }

    func vertices(adjacentTo vertex: Vertex) -> Set<Vertex> {
        return self.adjacencies[vertex]!
    }

    var vertices: Set<Vertex> {
        return Set(self.data.keys)
    }

    // https://mathoverflow.net/questions/23811/reporting-all-faces-in-a-planar-graph
    // https://mosaic.mpi-cbg.de/docs/Schneider2015.pdf
    // https://www.boost.org/doc/libs/1_36_0/boost/graph/planar_face_traversal.hpp
    var innerFaces: Set<Face> {
        var faces: Set<[Vertex]> = []
        var edges: Set<DirectedEdge> = []

        for vertex in self.data.keys {
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
                    faces.insert(vertices.reversed())
                    break
                } else {
                    vertices.append(best.target)
                }
            }
        }

        // outer face has negative area!
        precondition(faces.count(where: { self.area(of: $0) < 0 }) == 1)

        return Set(faces.filter({ self.area(of: $0) >= 0 }).map({ Set($0) }))
    }

    func position(of vertex: Vertex) -> CGPoint {
        return self.data[vertex]!.0
    }

    func weight(of vertex: Vertex) -> Weight {
        return self.data[vertex]!.1
    }

    private func area(of face: [Vertex]) -> CGFloat {
        let positions = face.map({ self.position(of: $0) })

        var sum = positions.last!.x * positions.first!.y - positions.last!.y * positions.first!.x

        for (a, b) in zip(positions, positions.dropFirst()) {
            sum += a.x * b.y - a.y * b.x
        }

        return sum / 2
    }

    private func angle(of edge: DirectedEdge) -> Angle {
        let vector = CGVector(from: self.position(of: edge.source), to: self.position(of: edge.target))

        return Angle.atan2(vector.dy, vector.dx)
    }
}

