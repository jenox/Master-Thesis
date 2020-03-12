//
//  FaceWeightedGraph.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 12.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Foundation
import CoreGraphics

// "Dual" graph: straight line plane, face-weighted
struct FaceWeightedGraph {
    init() {}

    struct Vertex: Hashable, CustomStringConvertible {
        private static var nextID: Int = 0
        private let id: Int

        init() {
            self.id = Self.nextID
            Self.nextID += 1
        }

        var description: String {
            return "\(self.id)"
        }
    }

    private struct VertexPayload {
        var position: CGPoint
        var adjacencies: [Vertex]
    }

    private struct FacePayload {
        var weight: Double
        var boundary: [Vertex]
    }

    private(set) var vertices: [Vertex] = []
    private(set) var edges: [(Vertex, Vertex)] = []
    private var vertexPayloads: [Vertex: VertexPayload] = [:]

    private(set) var faces: [String] = []
    private var facePayloads: [String: FacePayload] = [:]

    mutating func insertVertex(at position: CGPoint) -> Vertex {
        let vertex = Vertex()

        self.vertices.append(vertex)
        self.vertexPayloads[vertex] = VertexPayload(position: position, adjacencies: [])

        return vertex
    }

    mutating func displace(_ vertex: Vertex, by displacement: CGVector) {
        self.vertexPayloads[vertex]!.position += displacement
    }

    func position(of vertex: Vertex) -> CGPoint {
        return self.vertexPayloads[vertex]!.position
    }

    mutating func insertEdge(between vertex1: Vertex, and vertex2: Vertex) {
        assert(!self.vertexPayloads[vertex1]!.adjacencies.contains(vertex2))
        assert(!self.vertexPayloads[vertex2]!.adjacencies.contains(vertex1))

        self.vertexPayloads[vertex1]!.adjacencies.append(vertex2)
        self.vertexPayloads[vertex2]!.adjacencies.append(vertex1)
        self.edges.append((vertex1, vertex2))
    }

    func containsEdge(between vertex1: Vertex, and vertex2: Vertex) -> Bool {
        return self.vertexPayloads[vertex1]!.adjacencies.contains(vertex2)
    }

    func vertices(adjacentTo vertex: Vertex) -> [Vertex] {
        return self.vertexPayloads[vertex]!.adjacencies
    }

    func vertex(adjacentTo first: Vertex, and second: Vertex) -> Vertex? {
        let vertices = Set(self.vertexPayloads[first]!.adjacencies).intersection(self.vertexPayloads[second]!.adjacencies)
        assert(vertices.count <= 1)
        return vertices.first
    }

    mutating func defineFace(named name: String, boundedBy boundary: [Vertex], weight: Double) {
        assert(self.facePayloads[name] == nil)
        assert(boundary.makeAdjacentPairIterator().allSatisfy(self.containsEdge(between:and:)))

        self.faces.append(name)
        self.facePayloads[name] = FacePayload(weight: weight, boundary: boundary)
    }

    func polygon(for face: String) -> Polygon {
        return Polygon(points: self.boundary(of: face).map(self.position(of:)))
    }

    func area(of face: String) -> Double {
        return Double(self.polygon(for: face).area)
    }

    func weight(of face: String) -> Double {
        return self.facePayloads[face]!.weight
    }

    mutating func setWeight(of face: String, to value: Double) {
        self.facePayloads[face]!.weight = value
    }

    func boundary(of face: String) -> [Vertex] {
        return self.facePayloads[face]!.boundary
    }

    func segment(from vertex1: Vertex, to vertex2: Vertex) -> Segment {
        return Segment(a: self.position(of: vertex1), b: self.position(of: vertex2))
    }

    func distance(from vertex1: Vertex, to vertex2: Vertex) -> CGFloat {
        return self.position(of: vertex1).distance(to: self.position(of: vertex2))
    }

    func vector(from vertex: Vertex, to point: CGPoint) -> CGVector {
        return CGVector(from: self.position(of: vertex), to: point)
    }
}
