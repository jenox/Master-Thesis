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

    mutating func setWeight(of face: String, to value: Double) throws {
        struct Error: Swift.Error {}

        guard self.facePayloads[face] != nil else { throw Error() }
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

    func degree(of vertex: Vertex) -> Int {
        return self.vertices(adjacentTo: vertex).count
    }

    func isSubdivisionVertex(_ vertex: Vertex) -> Bool {
        switch self.degree(of: vertex) {
        case 2: return true
        case 3: return false
        default: fatalError()
        }
    }

    func contains(_ vertex: Vertex) -> Bool {
        return self.vertexPayloads[vertex] != nil
    }

    mutating func contractEdgeIfPossible(between a: Vertex, and b: Vertex) {
        assert(self.vertex(adjacentTo: a, and: b) == nil)

        // cannot contract edge between 2 3-degree vertices
        // we have u-v-w with v having no further neighbors
        guard let v = [a, b].first(where: { self.degree(of: $0) == 2 }) else { return }
        let u = v == a ? b : a
        let w = self.vertices(adjacentTo: v).first(where: { $0 != u })!

        // TODO: must be able to be contracted WITHOUT introducing crossings

        // contract v "into" u
        var copy = self
        copy.edges.deleteFirst(of: (u,v), (v,u), by: ==)
        copy.edges.replaceFirst(of: (v,w), (w,v), with: (u,w), by: ==)
        copy.vertices.deleteFirst(of: v, by: ==)
        copy.vertexPayloads[v] = nil
        copy.vertexPayloads[u]!.adjacencies.replaceFirst(of: v, with: w, by: ==)
        copy.vertexPayloads[w]!.adjacencies.replaceFirst(of: v, with: u, by: ==)

        guard copy.isCrossingFree() else {
            print("Could not contract edge \(a)-\(b): would create edge crossing!")
            return
        }

        print("Contracting edge \(a)-\(b)...")

        self = copy

        // Fix faces
        for (face, payload) in self.facePayloads {
            if let index = payload.boundary.firstIndex(of: v) {
                self.facePayloads[face]!.boundary.remove(at: index)
            }
        }
    }

    func firstEdgeCrossing() -> (Segment, Segment)? {
        for ((u,v),(w,x)) in self.edges.cartesian(with: self.edges) where Set([u,v,w,x]).count == 4 {
            let s1 = self.segment(from: u, to: v)
            let s2 = self.segment(from: w, to: x)
            if s1.intersects(s2) {
                return (s1, s2)
            }
        }

        return nil
    }

    func isCrossingFree() -> Bool {
        return self.firstEdgeCrossing() == nil
    }
}

private extension Array {
    mutating func deleteFirst(of values: Element..., by isEqual: (Element, Element) -> Bool) {
        let index = self.firstIndex(where: { element in values.contains(where: { isEqual($0, element) }) })!
        self.swapAt(index, self.indices.last!)
        self.removeLast()
    }

    mutating func replaceFirst(of values: Element..., with replacement: Element, by isEqual: (Element, Element) -> Bool) {
        let index = self.firstIndex(where: { element in values.contains(where: { isEqual($0, element) }) })!
        self[index] = replacement
    }
}
