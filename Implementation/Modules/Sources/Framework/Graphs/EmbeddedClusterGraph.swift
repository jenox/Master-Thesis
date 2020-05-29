//
//  EmbeddedClusterGraph.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 05.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift
import Collections

public struct EmbeddedClusterGraph {
    public typealias Vertex = ClusterName

    public internal(set) var vertices: OrderedSet<Vertex> = []
    public internal(set) var neighbors: [Vertex: OrderedSet<Vertex>] = [:]
    public internal(set) var outerFaceBoundary: [Vertex] = []

    init() {
    }
}

extension EmbeddedClusterGraph: PlanarGraph {
    public var edges: DirectedEdgeIterator<Vertex> {
        return DirectedEdgeIterator(vertices: self.vertices, neighbors: self.neighbors)
    }

    public func vertices(adjacentTo vertex: Vertex) -> OrderedSet<Vertex> {
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
    public var internalVertices: AnyBidirectionalCollection<Vertex> {
        return AnyBidirectionalCollection(self.vertices.filter({ !self.outerFaceBoundary.contains($0) }))
    }

    public var externalVertices: AnyBidirectionalCollection<Vertex> {
        return AnyBidirectionalCollection(self.outerFaceBoundary)
    }

    public var internalEdges: AnyBidirectionalCollection<(Vertex, Vertex)> {
        let externalEdges = self.externalEdges

        var internalEdges = self.edges.filter(<)
        internalEdges.removeAll(where: { (u,v) in externalEdges.contains(where: { (x,y) in (u,v)==(x,y) || (u,v)==(y,x) }) })

        return AnyBidirectionalCollection(internalEdges)
    }

    public var externalEdges: AnyBidirectionalCollection<(Vertex, Vertex)> {
        return AnyBidirectionalCollection(self.outerFaceBoundary.adjacentPairs(wraparound: true))
    }

    public var outerFace: Face<Vertex> {
        return .init(vertices: self.outerFaceBoundary)
    }

    public var internalFaces: AnyBidirectionalCollection<Face<Vertex>> {
        var faces = Array(self.allFaces())
        faces.remove(at: faces.firstIndex(of: self.outerFace)!)

        return AnyBidirectionalCollection(faces)
    }
}

extension MutablePolygonalDual {
    public var embeddedClusterGraph: EmbeddedClusterGraph {
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

extension MutablePolygonalDual {
    /// In counterclockwise order.
    func faces(incidentTo face: Face<UniquelyIdentifiedVertex>) -> OrderedSet<Face<UniquelyIdentifiedVertex>> {
        // for performance reasons, only consider non-bends
        // we might temporarily have vertices with degree ≥ 4
        var faces: OrderedSet<Face<UniquelyIdentifiedVertex>> = []
        for joint in face.vertices where !self.isBend(joint) {
//            self.facesinci
            for neighboringFace in self.faces(incidentTo: joint).rotated(shiftingElementToStart: face) {
                faces.insert(neighboringFace)
            }
        }

        let removed = faces.remove(face)
        assert(removed)

        return faces
    }

    func name(of face: Face<UniquelyIdentifiedVertex>) -> String? {
        return self.faces.first(where: { face == .init(vertices: self.boundary(of: $0)) })?.rawValue
    }

    func faceID(of face: Face<UniquelyIdentifiedVertex>) -> FaceID? {
        return self.facePayloads.first(where: { face == .init(vertices: $0.value.boundary) })?.key
    }
}
