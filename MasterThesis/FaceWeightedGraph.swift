//
//  FaceWeightedGraph.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 12.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics

// "Dual" graph: straight line plane, face-weighted
struct FaceWeightedGraph {
    init() {}

    enum Vertex: Hashable {
        case internalFace(Set<Character>)
        case outerEdge(Set<Character>)
    }

    private(set) var vertices: [Vertex] = []
    private(set) var locations: [Vertex: CGPoint] = [:]
    private(set) var adjacencies: [Vertex: [Vertex]] = [:]
    private(set) var edges: [(Vertex, Vertex)] = []

    private(set) var faces: Set<Set<Vertex>> = []

    mutating func insert(_ vertex: Vertex, at position: CGPoint) {
        precondition(!self.vertices.contains(vertex))

        self.vertices.append(vertex)
        self.locations[vertex] = position
        self.adjacencies[vertex] = []
    }

    mutating func insertEdge(between endpoint1: Vertex, and endpoint2: Vertex) {
        precondition(endpoint1 != endpoint2)
        precondition(!self.adjacencies[endpoint1]!.contains(endpoint2))
        precondition(!self.adjacencies[endpoint2]!.contains(endpoint1))

        self.adjacencies[endpoint1]!.append(endpoint2)
        self.adjacencies[endpoint2]!.append(endpoint1)
        self.edges.append((endpoint1, endpoint2))
    }

    mutating func register(face: Set<Vertex>) {
        precondition(face.intersection(self.vertices).count == face.count)
        precondition(!self.faces.contains(face))

        self.faces.insert(face)
    }

    func position(of vertex: Vertex) -> CGPoint {
        return self.locations[vertex]!
    }
}
