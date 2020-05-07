//
//  EmbeddedClusterGraph.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 05.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift
import Collections

struct EmbeddedClusterGraph {
    typealias Vertex = ClusterName

    var vertices: OrderedSet<Vertex> = []
    var neighbors: [Vertex: OrderedSet<Vertex>] = [:]
    var outerFaceBoundary: [Vertex] = []

    init() {
    }
}

extension EmbeddedClusterGraph: PlanarGraph {
    var edges: DirectedEdgeIterator<Vertex> {
        return DirectedEdgeIterator(vertices: self.vertices, neighbors: self.neighbors)
    }

    func vertices(adjacentTo vertex: Vertex) -> OrderedSet<Vertex> {
        return self.neighbors[vertex]!
    }
}

extension EmbeddedClusterGraph {
    func ensureIntegrity() throws {
        // Planar
        _ = self.allFaces()

        guard self.vertices.count >= 3 else { throw EmbeddedClusterGraphViolation.notEnoughVertices }

        // Biconnected
        guard Set(self.outerFaceBoundary).count == self.outerFaceBoundary.count else { throw EmbeddedClusterGraphViolation.notBiconnected }

        // Internally triangulated
        guard self.internalFaces.allSatisfy({ $0.vertices.count == 3 }) else { throw EmbeddedClusterGraphViolation.notInternallyTriangulated }

        // TODO: How do planarity and internal triangulatedness fit together in the intermediate step of edge flip?
    }
}

private enum EmbeddedClusterGraphViolation: Error {
    case notEnoughVertices
    case notPlanar
    case notBiconnected
    case notInternallyTriangulated
}

extension EmbeddedClusterGraph {
    private var internalVertices: AnyBidirectionalCollection<Vertex> {
        return AnyBidirectionalCollection(self.vertices.filter({ !self.outerFaceBoundary.contains($0) }))
    }

    private var externalVertices: AnyBidirectionalCollection<Vertex> {
        return AnyBidirectionalCollection(self.outerFaceBoundary)
    }

    private var internalEdges: AnyBidirectionalCollection<(Vertex, Vertex)> {
        let externalEdges = self.externalEdges

        var internalEdges = self.edges.filter(<)
        internalEdges.removeAll(where: { (u,v) in externalEdges.contains(where: { (x,y) in (u,v)==(x,y) || (u,v)==(y,x) }) })

        return AnyBidirectionalCollection(internalEdges)
    }

    private var externalEdges: AnyBidirectionalCollection<(Vertex, Vertex)> {
        return AnyBidirectionalCollection(self.outerFaceBoundary.adjacentPairs(wraparound: true))
    }

    private var outerFace: Face<Vertex> {
        return .init(vertices: self.outerFaceBoundary)
    }

    private var internalFaces: AnyBidirectionalCollection<Face<Vertex>> {
        return AnyBidirectionalCollection(self.allFaces().filter({ $0 != self.outerFace }))
    }
}

extension EmbeddedClusterGraph {
    /// We can insert into all (triangular) internal faces.
    var insertionPositionsInside: [(Vertex, Vertex, Vertex)] {
        var insertionPositionsInside: [(Vertex, Vertex, Vertex)] = []

        for face in self.internalFaces {
            let (u, v, w) = face.vertices.destructured3()!

            insertionPositionsInside.append((u, v, w))
            insertionPositionsInside.append((u, w, v))
            insertionPositionsInside.append((v, u, w))
            insertionPositionsInside.append((v, w, u))
            insertionPositionsInside.append((w, u, v))
            insertionPositionsInside.append((w, v, u))
        }

        return insertionPositionsInside
    }

    /// We can insert at all edges on the outer face.
    var insertionPositionsOutside: [(Vertex, Vertex)] {
        var insertionPositionsOutside: [(Vertex, Vertex)] = []

        for (u, v) in self.externalEdges {
            insertionPositionsOutside.append((u, v))
            insertionPositionsOutside.append((v, u))
        }

        return insertionPositionsOutside
    }

    /// We can only remove an internal vertex if the graph remains internally
    /// triangulated. This is the case if the vertex to be removed has degree 3.
    var removableInternalVertices: [Vertex] {
        return self.internalVertices.filter({ self.degree(of: $0) == 3 })
    }

    /// We can only remove an external vertex if the graph remains 2-connected.
    /// Because we only allow removing vertices with degree 2, this is the case
    /// if the graph would have 3+ vertices remaining.
    var removableExternalVertices: [Vertex] {
        guard self.vertices.count >= 4 else { return [] }

        return self.externalVertices.filter({ self.degree(of: $0) == 2 })
    }

    /// We can only flip an internal edge if the graph remains simple. This is
    /// the case if the "tips" of the (triangular) faces incident to the edge
    /// aren't already adjacent.
    var flippableInternalEdges: [(Vertex, Vertex)] {
        var flippableEdges: [(Vertex, Vertex)] = []

        for (u, v) in self.internalEdges {
            let (f, g) = self.faces(incidentTo: (u, v))
            assert(f != g)
            assert(f.vertices.count == 3 && f.vertices.contains(u) && f.vertices.contains(v))
            assert(g.vertices.count == 3 && g.vertices.contains(u) && g.vertices.contains(v))
            let x = Set(f.vertices).subtracting([u,v]).first!
            let y = Set(g.vertices).subtracting([u,v]).first!

            guard !self.vertices(adjacentTo: x).contains(y) else { continue }

            flippableEdges.append((u, v))
            flippableEdges.append((v, u))
        }

        return flippableEdges
    }

    /// We can only remove an edge on the outer face if the graph remains
    /// 2-connected. This is the case if the edge's endpoints both have degree
    /// ≥ 3.
    var removableEdges: [(Vertex, Vertex)] {
        var removableEdges: [(Vertex, Vertex)] = []

        for (u, v) in self.externalEdges {
            guard self.degree(of: u) >= 3 else { continue }
            guard self.degree(of: v) >= 3 else { continue }

            removableEdges.append((u, v))
            removableEdges.append((v, u))
        }

        return removableEdges
    }

    /// We can only insert an edge into the outer face if the graph remains
    /// internally triangulated. This is the case if the edge's endpoints
    /// already have at least one neighbor on the outer face in common.
    ///
    /// If the edge's endpoints have two neighbors on the outer face in common,
    /// we must explicitly specify which of them becomes an internal vertex.
    var insertableEdges: [(Vertex, Vertex, Vertex)] {
        var insertableEdges: [(Vertex, Vertex, Vertex)] = []

        for (u, v, w) in self.externalVertices.adjacentTriplets(wraparound: true) {
            guard !self.vertices(adjacentTo: u).contains(w) else { continue }

            insertableEdges.append((u, v, w))
            insertableEdges.append((w, v, u))
        }

        return insertableEdges
    }
}

extension PolygonalDual {
    var embeddedClusterGraph: EmbeddedClusterGraph {
        var graph = EmbeddedClusterGraph()
        graph.vertices = self.faces

        for faceID in self.faces {
            var isIncidentToOuterFace = false
            for neighboringFace in self.faces(incidentTo: .init(vertices: self.boundary(of: faceID))) {
                if let neighborID = self.faceID(of: neighboringFace) {
                    graph.neighbors[faceID, default: []].insert(neighborID)
                } else {
                    assert(!isIncidentToOuterFace)
                    isIncidentToOuterFace = true
                }
            }
        }

        graph.outerFaceBoundary = []
        for neighboringFace in self.faces(incidentTo: self.internalFacesAndOuterFace().outer) {
            graph.outerFaceBoundary.append(self.faceID(of: neighboringFace)!)
        }

        try! graph.ensureIntegrity()

        return graph
    }
}

extension PolygonalDual {
    typealias _Face = Face<UniquelyIdentifiedVertex>

    /// In counterclockwise order.
    func faces(incidentTo face: _Face) -> OrderedSet<_Face> {
        // for performance reasons, only consider non-bends
        // we might temporarily have vertices with degree ≥ 4
        var faces: OrderedSet<_Face> = []
        for joint in face.vertices where !self.isBend(joint) {
            for neighboringFace in self.faces(incidentTo: joint).rotated(shiftingToStart: face) {
                faces.insert(neighboringFace)
            }
        }

        let removed = faces.remove(face)
        assert(removed)

        return faces
    }

    func name(of face: _Face) -> String? {
        return self.faces.first(where: { face == .init(vertices: self.boundary(of: $0)) })?.rawValue
    }

    func faceID(of face: _Face) -> FaceID? {
        return self.facePayloads.first(where: { face == .init(vertices: $0.value.boundary) })?.key
    }
}

extension Collection {
    func destructured1() -> (Element)? {
        let array = Array(self)
        return array.count == 1 ? (array[0]) : nil
    }

    func destructured2() -> (Element, Element)? {
        let array = Array(self)
        return array.count == 2 ? (array[0], array[1]) : nil
    }

    func destructured3() -> (Element, Element, Element)? {
        let array = Array(self)
        return array.count == 3 ? (array[0], array[1], array[2]) : nil
    }
}

extension Collection where Element: Equatable {
    func rotated(shiftingToStart element: Element) -> RotatedCollection<Self> {
        self.rotated(shiftingToStart: self.firstIndex(of: element)!)
    }
}

extension Face {
    func filter(_ predicate: (T) -> Bool) -> Face {
        return .init(vertices: self.vertices.filter(predicate))
    }
}
