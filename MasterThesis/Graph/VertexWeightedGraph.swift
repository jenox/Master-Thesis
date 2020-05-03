//
//  Data.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 12.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry

struct VertexWeightedGraphEdges {
    fileprivate init(graph: VertexWeightedGraph) {
        self.graph = graph
    }
    private let graph: VertexWeightedGraph
}

extension VertexWeightedGraphEdges: Collection {
    typealias Element = (VertexWeightedGraph.Vertex, VertexWeightedGraph.Vertex)
    typealias Iterator = IndexingIterator<VertexWeightedGraphEdges>
    typealias SubSequence = Slice<VertexWeightedGraphEdges>
    typealias Indices = DefaultIndices<VertexWeightedGraphEdges>

    struct Index: Comparable {
        var sourceIndex: Int
        var incidentEdgeIndex: Int

        static func < (lhs: Index, rhs: Index) -> Bool {
            return (lhs.sourceIndex, lhs.incidentEdgeIndex) < (rhs.sourceIndex, rhs.incidentEdgeIndex)
        }
    }

    var startIndex: Index {
        let index = Index(sourceIndex: 0, incidentEdgeIndex: 0)
        return self.wraparound(index)
    }

    var endIndex: Index {
        return Index(sourceIndex: self.graph.vertices.count, incidentEdgeIndex: 0)
    }

    func index(after index: Index) -> Index {
        let index = Index(sourceIndex: index.sourceIndex, incidentEdgeIndex: index.incidentEdgeIndex + 1)
        return self.wraparound(index)
    }

    subscript(position: Index) -> Element {
        let source = self.graph.vertices[position.sourceIndex]
        let target = self.graph.vertices(adjacentTo: source)[position.incidentEdgeIndex]

        return (source, target)
    }

    private func wraparound(_ index: Index) -> Index {
        var index = index

        while index.sourceIndex < self.graph.vertices.count && index.incidentEdgeIndex == self.graph.vertices(adjacentTo: self.graph.vertices[index.sourceIndex]).count {
            index = Index(sourceIndex: index.sourceIndex + 1, incidentEdgeIndex: 0)
        }
        return index
    }
}

// Input graph: straight-line plane, vertex-weighted
// internally triangulated, 2-connected
struct VertexWeightedGraph {
    typealias Vertex = ClusterName
    typealias Weight = ClusterWeight
    fileprivate typealias Payload = (neighbors: OrderedSet<Vertex>, position: CGPoint, weight: Weight)

    init() {}

    fileprivate(set) var vertices: OrderedSet<Vertex> = []
    fileprivate var payload: [Vertex: Payload] = [:]

    var edges: VertexWeightedGraphEdges {
        return VertexWeightedGraphEdges(graph: self)
    }

    mutating func insert(_ vertex: Vertex, at position: CGPoint, weight: Weight) {
        precondition(self.payload[vertex] == nil)

        self.vertices.insert(vertex)
        self.payload[vertex] = ([], position, weight)
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

        var neighbors = self.payload[u]!.neighbors
        let index = neighbors.firstIndex(where: { self.angle(from: u, to: $0).counterclockwise > angle }) ?? neighbors.endIndex
        neighbors.insert(v, at: index)
        self.payload[u]!.neighbors = neighbors
    }

    mutating func removeEdge(between u: Vertex, and v: Vertex) {
        precondition(u != v)
        precondition(self.vertices(adjacentTo: u).contains(v))

        self.payload[u]!.neighbors.remove(v)
        self.payload[v]!.neighbors.remove(u)
    }

    func vertices(adjacentTo vertex: Vertex) -> OrderedSet<Vertex> {
        return self.payload[vertex]!.neighbors
    }

    func weight(of vertex: Vertex) -> Weight {
        return self.payload[vertex]!.weight
    }

    mutating func setWeight(of vertex: Vertex, to weight: Weight) {
        self.payload[vertex]!.weight = weight
    }
}

extension VertexWeightedGraph: StraightLineGraph {
    typealias Vertices = OrderedSet<Vertex>
    typealias Edges = VertexWeightedGraphEdges

    func position(of vertex: Vertex) -> CGPoint {
        return self.payload[vertex]!.position
    }

    mutating func move(_ vertex: Vertex, to position: CGPoint) {
        self.payload[vertex]!.position = position
    }
}
