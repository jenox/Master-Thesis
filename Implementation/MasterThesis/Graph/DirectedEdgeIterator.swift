//
//  DirectedEdgeIterator.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 03.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

struct DirectedEdgeIterator<Vertex> where Vertex: Hashable {
    init(vertices: OrderedSet<Vertex>, neighbors: [Vertex: OrderedSet<Vertex>]) {
        self.vertices = vertices
        self.neighbors = neighbors
    }

    private let vertices: OrderedSet<Vertex>
    private let neighbors: [Vertex: OrderedSet<Vertex>]
}

extension DirectedEdgeIterator: Collection {
    typealias Element = (Vertex, Vertex)
    typealias Iterator = IndexingIterator<DirectedEdgeIterator>
    typealias SubSequence = Slice<DirectedEdgeIterator>
    typealias Indices = DefaultIndices<DirectedEdgeIterator>

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
        return Index(sourceIndex: self.vertices.count, incidentEdgeIndex: 0)
    }

    func index(after index: Index) -> Index {
        let index = Index(sourceIndex: index.sourceIndex, incidentEdgeIndex: index.incidentEdgeIndex + 1)
        return self.wraparound(index)
    }

    subscript(position: Index) -> Element {
        let source = self.vertices[position.sourceIndex]
        let target = self.neighbors[source]![position.incidentEdgeIndex]

        return (source, target)
    }

    private func wraparound(_ index: Index) -> Index {
        var index = index

        while index.sourceIndex < self.vertices.count && index.incidentEdgeIndex == self.neighbors[self.vertices[index.sourceIndex]]!.count {
            index = Index(sourceIndex: index.sourceIndex + 1, incidentEdgeIndex: 0)
        }
        return index
    }
}
