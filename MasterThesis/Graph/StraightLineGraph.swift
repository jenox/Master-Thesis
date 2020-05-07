//
//  GraphProtocol.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 31.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry

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
}

protocol StraightLineGraph: PlanarGraph {
    func position(of vertex: Vertex) -> CGPoint
    mutating func move(_ vertex: Vertex, to position: CGPoint)
}

extension StraightLineGraph {
    mutating func displace(_ vertex: Vertex, by displacement: CGVector) {
        self.move(vertex, to: self.position(of: vertex) + displacement)
    }

    func segment(from u: Vertex, to v: Vertex) -> Segment {
        return Segment(from: self.position(of: u), to: self.position(of: v))
    }

    func vector(from u: Vertex, to v: Vertex) -> CGVector {
        return CGVector(from: self.position(of: u), to: self.position(of: v))
    }

    func vector(from u: Vertex, to point: CGPoint) -> CGVector {
        return CGVector(from: self.position(of: u), to: point)
    }

    func distance(from u: Vertex, to v: Vertex) -> CGFloat {
        return self.vector(from: u, to: v).length
    }

    func polygon(on vertices: [Vertex]) -> Polygon {
        return Polygon(points: vertices.map(self.position(of:)))
    }

    func angle(from u: Vertex, to v: Vertex) -> Angle {
        let vector = self.vector(from: u, to: v)
        return Angle.atan2(vector.dy, vector.dx)
    }

    func internalFacesAndOuterFace() -> (internal: [Face<Vertex>], outer: Face<Vertex>) {
        var faces = self.allFaces()
        let index = faces.partition(by: { self.polygon(on: $0.vertices).area >= 0 })
        precondition(index == 1)
        return (internal: Array(faces.dropFirst()), outer: faces[0])
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