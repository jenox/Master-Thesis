//
//  Data.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 12.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry

public struct VertexWeightedGraph {
    public typealias Vertex = ClusterName
    public typealias Weight = ClusterWeight

    fileprivate struct Payload {
        var neighbors: OrderedSet<Vertex>
        var position: CGPoint
        var weight: Weight
    }

    public init() {}

    public fileprivate(set) var vertices: OrderedSet<Vertex> = []
    fileprivate var payloads: [Vertex: Payload] = [:]

    public mutating func insert(_ vertex: Vertex, at position: CGPoint, weight: Weight) {
        precondition(self.payloads[vertex] == nil)

        self.vertices.insert(vertex)
        self.payloads[vertex] = .init(neighbors: [], position: position, weight: weight)
    }

    func containsEdge(between endpoint1: Vertex, and endpoint2: Vertex) -> Bool {
        return self.vertices(adjacentTo: endpoint1).contains(endpoint2)
    }

    public mutating func insertEdge(between endpoint1: Vertex, and endpoint2: Vertex) {
        precondition(endpoint1 != endpoint2)
        precondition(!self.vertices(adjacentTo: endpoint1).contains(endpoint2))

        self.insertEdge(from: endpoint1, to: endpoint2)
        self.insertEdge(from: endpoint2, to: endpoint1)
    }

    private mutating func insertEdge(from u: Vertex, to v: Vertex) {
        var neighbors = self.payloads[u]!.neighbors
        let angles = neighbors.map({ self.angle(from: u, to: $0).counterclockwise })
        let index = angles.index(forInserting: self.angle(from: u, to: v).counterclockwise)
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

    public var edges: DirectedEdgeIterator<Vertex> {
        return DirectedEdgeIterator(vertices: self.vertices, neighbors: self.payloads.mapValues(\.neighbors))
    }

    func vertices(adjacentTo vertex: Vertex) -> OrderedSet<Vertex> {
        return self.payloads[vertex]!.neighbors
    }

    public func position(of vertex: Vertex) -> CGPoint {
        return self.payloads[vertex]!.position
    }

    mutating func move(_ vertex: Vertex, to position: CGPoint) {
        self.payloads[vertex]!.position = position
    }
}

extension VertexWeightedGraph.Payload: Codable {}
extension VertexWeightedGraph: Codable {}
