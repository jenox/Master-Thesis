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
    var internalVertices: AnyBidirectionalCollection<Vertex> {
        return AnyBidirectionalCollection(self.vertices.filter({ !self.outerFaceBoundary.contains($0) }))
    }

    var externalVertices: AnyBidirectionalCollection<Vertex> {
        return AnyBidirectionalCollection(self.outerFaceBoundary)
    }

    var internalEdges: AnyBidirectionalCollection<(Vertex, Vertex)> {
        let externalEdges = self.externalEdges

        var internalEdges = self.edges.filter(<)
        internalEdges.removeAll(where: { (u,v) in externalEdges.contains(where: { (x,y) in (u,v)==(x,y) || (u,v)==(y,x) }) })

        return AnyBidirectionalCollection(internalEdges)
    }

    var externalEdges: AnyBidirectionalCollection<(Vertex, Vertex)> {
        return AnyBidirectionalCollection(self.outerFaceBoundary.adjacentPairs(wraparound: true))
    }

    var outerFace: Face<Vertex> {
        return .init(vertices: self.outerFaceBoundary)
    }

    var internalFaces: AnyBidirectionalCollection<Face<Vertex>> {
        return AnyBidirectionalCollection(self.allFaces().filter({ $0 != self.outerFace }))
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
