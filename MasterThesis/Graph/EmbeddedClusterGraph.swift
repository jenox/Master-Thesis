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
    var outerFace: [Vertex] = []

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
        // planarity
        // internally triconnected
        // 2-connected

        // how do planarity and internal triangulatedness fit together in the intermediate step of edge flip?
    }
}

extension EmbeddedClusterGraph {
    /// We can insert into all (triangular) internal faces.
    var insertionPositionsInside: [(Vertex, Vertex, Vertex)] {
        fatalError()
    }

    // we can insert at all external edges
    var insertionPositionsOutside: [(Vertex, Vertex)] {
        return Array(self.outerFace.adjacentPairs(wraparound: true))
    }

    // only if remains internally triangulated
    var removableInternalVertices: [Vertex] {
        fatalError()
    }

    // only if remains 2-connected. because we only allow removing degree 2, just check we have 3+ remaining?
    var removableExternalVertices: [Vertex] {
        fatalError()
    }

    // only if neighbors not already adjacent.
    var flippableInternalEdges: [(Vertex, Vertex)] {
        fatalError()
    }

    // only if graph remains 2-connected. both vertices must have deg ≥ 3.
    var removableEdges: [(Vertex, Vertex)] {
        fatalError()
    }

    // only if preserved triangulatedness.
    var insertableEdges: [(Vertex, Vertex, Vertex)] {
        fatalError()
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

        graph.outerFace = []
        for neighboringFace in self.faces(incidentTo: self.internalFacesAndOuterFace().outer) {
            graph.outerFace.append(self.faceID(of: neighboringFace)!)
        }

        return graph
    }
}

extension PolygonalDual {
    typealias _Face = Face<UniquelyIdentifiedVertex>

    // have function to determine faces incident to some face
    // have function to check if face is outer face
    // have function to check if face is incident to outer face

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
