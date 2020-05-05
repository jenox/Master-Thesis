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
        return self.allFaces().filter({ $0 != .init(vertices: self.outerFace) }).map({ $0.vertices.destructured3()! })
    }

    /// We can insert at all edges on the outer face.
    var insertionPositionsOutside: [(Vertex, Vertex)] {
        return Array(self.outerFace.adjacentPairs(wraparound: true))
    }

    /// We can only remove an internal vertex if the graph remains internally
    /// triangulated. This is the case if the vertex to be removed has degree 3.
    var removableInternalVertices: [Vertex] {
        return self.vertices.filter({ !self.outerFace.contains($0) && self.degree(of: $0) == 3 })
    }

    /// We can only remove an external vertex if the graph remains 2-connected.
    /// Because we only allow removing vertices with degree 2, this is the case
    /// if the graph would have 3+ vertices remaining.
    var removableExternalVertices: [Vertex] {
        guard self.vertices.count >= 4 else { return [] }

        return self.outerFace.filter({ self.degree(of: $0) == 2 })
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
