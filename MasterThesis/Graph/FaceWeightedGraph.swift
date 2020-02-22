//
//  FaceWeightedGraph.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 12.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Foundation
import CoreGraphics

// "Dual" graph: straight line plane, face-weighted
struct FaceWeightedGraph {
    init() {}

    enum Vertex: Hashable, CustomStringConvertible {
        case internalFace(Face<Character>)
        case outerEdge(UndirectedEdge)
        case subdivision1(UUID)
        case subdivision2(UUID)
        case subdivision3(UUID)

        var description: String {
            switch self {
            case .internalFace(let face):
                return face.vertices.map(String.init).joined(separator: "-")
            case .outerEdge(let edge):
                return "\(edge.first)-\(edge.second)"
            case .subdivision1:
                return "#"
            case .subdivision2:
                return "@"
            case .subdivision3:
                return "*"
            }
        }
    }

    private(set) var vertices: [Vertex] = []
    private(set) var locations: [Vertex: CGPoint] = [:]
    private(set) var adjacencies: [Vertex: [Vertex]] = [:]
    private(set) var edges: [(Vertex, Vertex)] = []

    private(set) var faces: [Face<Vertex>] = []
    private(set) var faceNames: [Face<Vertex>: Character] = [:]
    private(set) var faceWeights: [Face<Vertex>: Double] = [:]

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

    mutating func registerFace(_ face: Face<Vertex>, named name: Character, weight: Double) {
        precondition(face.vertices.allSatisfy(self.vertices.contains))
        precondition(!self.faces.contains(face))

        self.faces.append(face)
        self.faceNames[face] = name
        self.faceWeights[face] = weight
    }

    func position(of vertex: Vertex) -> CGPoint {
        return self.locations[vertex]!
    }

    mutating func setPosition(_ position: CGPoint, of vertex: Vertex) {
        self.locations[vertex] = position
    }

    func name(of face: Face<Vertex>) -> Character {
        return self.faceNames[face]!
    }

    func area(of face: Face<Vertex>) -> Double {
        return Double(Polygon(points: face.vertices.map(self.position(of:))).area)
    }

    func weight(of face: Face<Vertex>) -> Double {
        return self.faceWeights[face]!
    }

//    mutating func subdivideEdges() {
//        for edge in self.edges {
//            self.subdivide(edge)
//        }
//    }
//
//    private mutating func subdivide(_ edge: (Vertex, Vertex)) {
//        guard let index = self.edges.firstIndex(where: { $0.0 == edge.0 && $0.1 == edge.1 }) else { fatalError() }
//
//        let vertex = Vertex.subdivision(UUID())
//        let position = [self.position(of: edge.0), self.position(of: edge.1)].centroid
//
//        self.insert(vertex, at: position)
//        self.edges[index].1 = vertex
//        self.edges.append((vertex, edge.1))
//
//        for (index, face) in self.faces.enumerated() {
//            guard let position = face.indexOfEdge(between: edge.0, and: edge.1) else { continue }
//
//            var vertices = face.vertices
//            vertices.insert(vertex, at: position + 1)
//
//            let newface = Face(vertices: vertices)
//
//            self.faces[index] = newface
//            self.faceNames[newface] = self.faceNames.removeValue(forKey: face)!
//        }
//    }

    func vector(from vertex: Vertex, to point: CGPoint) -> CGVector {
        return CGVector(from: self.position(of: vertex), to: point)
    }

    func distance(from vertex1: Vertex, to vertex2: Vertex) -> CGFloat {
        return self.position(of: vertex1).distance(to: self.position(of: vertex2))
    }

    func segment(from vertex1: Vertex, to vertex2: Vertex) -> Segment {
        return Segment(a: self.position(of: vertex1), b: self.position(of: vertex2))
    }
}
