//
//  PlanarGraph.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 22.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

protocol PlanarGraph {
    associatedtype Vertex: Hashable

    var vertices: OrderedSet<Vertex> { get }
    var edges: DirectedEdgeIterator<Vertex> { get }

    func vertices(adjacentTo vertex: Vertex) -> OrderedSet<Vertex>
}

extension PlanarGraph {
    func degree(of vertex: Vertex) -> Int {
        return self.vertices(adjacentTo: vertex).count
    }

    // https://mathoverflow.net/questions/23811/reporting-all-faces-in-a-planar-graph
    // https://mosaic.mpi-cbg.de/docs/Schneider2015.pdf
    // https://www.boost.org/doc/libs/1_36_0/boost/graph/planar_face_traversal.hpp
    /// Traps if not simple, connected, or planar.
    func allFaces() -> [Face<Vertex>] {
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

        return faces
    }

    func faces(incidentTo vertex: Vertex) -> OrderedSet<Face<Vertex>> {
        var faces: OrderedSet<Face<Vertex>> = []
        var markedEdges: DirectedEdgeSet<Vertex> = []

        for neighbor in self.vertices(adjacentTo: vertex) {
            var boundingVertices = [vertex, neighbor]
            markedEdges.insert((vertex, neighbor))

            while boundingVertices.first != boundingVertices.last {
                let neighbors = self.vertices(adjacentTo: boundingVertices[boundingVertices.count - 1])
                let incoming = neighbors.firstIndex(of: boundingVertices[boundingVertices.count - 2])!
                let outgoing = (incoming == 0 ? neighbors.count : incoming) - 1

                markedEdges.insert((boundingVertices.last!, neighbors[outgoing]))
                boundingVertices.append(neighbors[outgoing])
            }

            boundingVertices.removeLast()
            faces.insert(.init(vertices: boundingVertices))
        }

        return faces
    }

    func faces(incidentTo edge: (Vertex, Vertex)) -> (Face<Vertex>, Face<Vertex>) {
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
            faces.append(.init(vertices: boundingVertices))
        }

        return faces.destructured2()!
    }

    func face(startingWith edge: (Vertex, Vertex)) -> Face<Vertex> {
        var boundingVertices = [edge.0, edge.1]

        while boundingVertices.first != boundingVertices.last {
            let neighbors = self.vertices(adjacentTo: boundingVertices[boundingVertices.count - 1])
            let incoming = neighbors.firstIndex(of: boundingVertices[boundingVertices.count - 2])!
            let outgoing = (incoming == 0 ? neighbors.count : incoming) - 1

            boundingVertices.append(neighbors[outgoing])
        }

        boundingVertices.removeLast()

        return .init(vertices: boundingVertices)
    }
}
