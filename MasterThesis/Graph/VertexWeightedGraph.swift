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

    func vertices(adjacentTo vertex: Vertex) -> OrderedSet<Vertex> {
        return self.payloads[vertex]!.neighbors
    }

    func position(of vertex: Vertex) -> CGPoint {
        return self.payloads[vertex]!.position
    }

    mutating func move(_ vertex: Vertex, to position: CGPoint) {
        self.payloads[vertex]!.position = position
    }
}
