//
//  Data.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 12.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry

// Input graph: straight-line plane, vertex-weighted
// internally triangulated, 2-connected
struct VertexWeightedGraph {
    typealias Vertex = ClusterName
    typealias Weight = ClusterWeight
    fileprivate typealias Payload = (neighbors: OrderedSet<Vertex>, position: CGPoint, weight: Weight)

    init() {}

    fileprivate(set) var vertices: OrderedSet<Vertex> = []
    fileprivate var payloads: [Vertex: Payload] = [:]

    mutating func insert(_ vertex: Vertex, at position: CGPoint, weight: Weight) {
        precondition(self.payloads[vertex] == nil)

        self.vertices.insert(vertex)
        self.payloads[vertex] = ([], position, weight)
    }

    func containsEdge(between endpoint1: Vertex, and endpoint2: Vertex) -> Bool {
        return self.vertices(adjacentTo: endpoint1).contains(endpoint2)
    }

    mutating func insertEdge(between endpoint1: Vertex, and endpoint2: Vertex) {
        precondition(endpoint1 != endpoint2)
        precondition(!self.vertices(adjacentTo: endpoint1).contains(endpoint2))

        self.insertEdge(from: endpoint1, to: endpoint2)
        self.insertEdge(from: endpoint2, to: endpoint1)
    }

    private mutating func insertEdge(from u: Vertex, to v: Vertex) {
        let angle = self.angle(from: u, to: v).counterclockwise

        var neighbors = self.payloads[u]!.neighbors
        let index = neighbors.firstIndex(where: { self.angle(from: u, to: $0).counterclockwise > angle }) ?? neighbors.endIndex
        neighbors.insert(v, at: index)
        self.payloads[u]!.neighbors = neighbors
    }

    mutating func removeEdge(between u: Vertex, and v: Vertex) {
        precondition(u != v)
        precondition(self.vertices(adjacentTo: u).contains(v))

        self.payloads[u]!.neighbors.remove(v)
        self.payloads[v]!.neighbors.remove(u)
    }

    func vertices(adjacentTo vertex: Vertex) -> OrderedSet<Vertex> {
        return self.payloads[vertex]!.neighbors
    }

    func weight(of vertex: Vertex) -> Weight {
        return self.payloads[vertex]!.weight
    }

    mutating func setWeight(of vertex: Vertex, to weight: Weight) {
        self.payloads[vertex]!.weight = weight
    }
}

extension VertexWeightedGraph: StraightLineGraph {
    typealias Vertices = OrderedSet<Vertex>
    typealias Edges = DirectedEdgeIterator<Vertex>

    var edges: DirectedEdgeIterator<Vertex> {
        return DirectedEdgeIterator(vertices: self.vertices, neighbors: self.payloads.mapValues(\.neighbors))
    }

    func position(of vertex: Vertex) -> CGPoint {
        return self.payloads[vertex]!.position
    }

    mutating func move(_ vertex: Vertex, to position: CGPoint) {
        self.payloads[vertex]!.position = position
    }
}

extension VertexWeightedGraph {
    // https://mathoverflow.net/questions/23811/reporting-all-faces-in-a-planar-graph
    // https://mosaic.mpi-cbg.de/docs/Schneider2015.pdf
    // https://www.boost.org/doc/libs/1_36_0/boost/graph/planar_face_traversal.hpp
    /// Traps if not simple, connected, or planar.
    var faces: (inner: [Face<Vertex>], outer: Face<Vertex>) {
        var faces: [Face<Vertex>] = []
        var markedEdges: DirectedEdgeSet<Vertex> = []

        for (u, v) in self.edges where !markedEdges.contains((u, v)) {
            assert(u != v)

            var boundingVertices = [u, v]
            markedEdges.insert((u, v))

            while boundingVertices.first != boundingVertices.last {
                let neighbors = self.vertices(adjacentTo: boundingVertices[boundingVertices.count - 1])
                let incoming = neighbors.firstIndex(of: boundingVertices[boundingVertices.count - 2])!
                let outgoing = (incoming == 0 ? neighbors.count : incoming) - 1

                markedEdges.insert((boundingVertices.last!, neighbors[outgoing]))
                boundingVertices.append(neighbors[outgoing])
            }

            faces.append(.init(vertices: boundingVertices.dropLast()))
        }

        // https://stackoverflow.com/a/22017359/796103
        guard self.vertices.count - markedEdges.count / 2 + faces.count == 2 else { fatalError() }

        let index = faces.partition(by: { self.polygon(on: $0.vertices).area >= 0 })
        precondition(index == 1)
        return (inner: Array(faces.dropFirst()), outer: faces[0])
    }

    func internalFaces(incidentTo edge: (Vertex, Vertex)) -> [Face<Vertex>] {
        var faces: [Face<Vertex>] = []
        var markedEdges: DirectedEdgeSet<Vertex> = []

        for (u, v) in [(edge.0, edge.1), (edge.1, edge.0)] where !markedEdges.contains((u, v)) {
            assert(u != v)

            var boundingVertices = [u, v]
            markedEdges.insert((u, v))

            while boundingVertices.first != boundingVertices.last {
                let neighbors = self.vertices(adjacentTo: boundingVertices[boundingVertices.count - 1])
                let incoming = neighbors.firstIndex(of: boundingVertices[boundingVertices.count - 2])!
                let outgoing = (incoming == 0 ? neighbors.count : incoming) - 1

                markedEdges.insert((boundingVertices.last!, neighbors[outgoing]))
                boundingVertices.append(neighbors[outgoing])
            }

            boundingVertices.removeLast()

            if self.polygon(on: boundingVertices).area > 0 {
                faces.append(.init(vertices: boundingVertices))
            }
        }

        return faces
    }
}
