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

    struct Vertex: Hashable, CustomStringConvertible, ExpressibleByIntegerLiteral {
        private static var nextID: Int = 0
        private let id: Int

        init(integerLiteral value: Int) {
            self.id = value
        }

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

    mutating func move(_ vertex: Vertex, to position: CGPoint) {
        self.vertexPayloads[vertex]!.position = position
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

    mutating func flipBorder(between a: String, and b: String) throws {
        let boundary1 = self.boundary(of: a) // "left"
        let boundary2 = self.boundary(of: b) // "right"
        var shared = boundary1.filter(boundary2.contains)
        let c = self.faces.first(where: { $0 != a && $0 != b && self.boundary(of: $0).contains(shared.first!) })! // "below"
        let d = self.faces.first(where: { $0 != a && $0 != b && self.boundary(of: $0).contains(shared.last!) })! // "above"

        assert(shared.makeAdjacentPairIterator().dropLast().allSatisfy(self.containsEdge(between:and:)))
        assert(shared.count(where: { !self.isSubdivisionVertex($0) }) == 2)
        assert(shared.dropFirst().dropLast().allSatisfy(self.isSubdivisionVertex(_:)))

        while shared.count >= 3 {
            // contract edge x-y; a,b other neighbors to x
            let others = self.vertices(adjacentTo: shared[0]).filter({ $0 != shared[1] })
            assert(others.count == 2)

            let y = self.position(of: shared[1])
            // TODO: maybe binary search this down from 0.5 while preserving crossings?
            let xa = self.segment(from: shared[0], to: others[0]).point(at: 0.3)
            let xb = self.segment(from: shared[0], to: others[1]).point(at: 0.3)

            self.contractEdge(from: shared[1], into: shared[0])
            self.move(shared[0], to: y)
            self.subdivideEdge(between: shared[0], and: others[0], at: xa)
            self.subdivideEdge(between: shared[0], and: others[1], at: xb)

            shared.remove(at: 1)
            shared.reverse()
        }

        assert(!self.isSubdivisionVertex(shared[0]))
        assert(!self.isSubdivisionVertex(shared[1]))

        print(shared)
        let middle = CGPoint.centroid(of: shared.map(self.position(of:)))
        let vector = CGVector(from: self.position(of: shared[0]), to: middle).rotated(by: .init(degrees: 90))
        self.move(shared[0], to: middle + 0.1 * vector)
        self.move(shared[1], to: middle - 0.1 * vector)

        self.facePayloads[a]!.boundary.removeAll(where: { $0 == 3 })
        self.facePayloads[b]!.boundary.removeAll(where: { $0 == 6 })
        self.facePayloads[c]!.boundary.insert(3, at: Face(vertices: self.boundary(of: c)).indexOfEdge(between: 6, and: 56)! + 1)
        self.facePayloads[d]!.boundary.insert(6, at: Face(vertices: self.boundary(of: d)).indexOfEdge(between: 3, and: 27)! + 1)
        self.edges.replaceFirst(of: (3,27),(27,3), with: (6,27), by: ==)
        self.edges.replaceFirst(of: (6,56),(56,6), with: (3,56), by: ==)
        self.vertexPayloads[27]!.adjacencies.replaceFirst(of: 3, with: 6, by: ==)
        self.vertexPayloads[56]!.adjacencies.replaceFirst(of: 6, with: 3, by: ==)
        self.vertexPayloads[3]!.adjacencies.replaceFirst(of: 27, with: 56, by: ==)
        self.vertexPayloads[6]!.adjacencies.replaceFirst(of: 56, with: 27, by: ==)

        self.ensureIntegrity()
    }

    func ensureIntegrity() {
        // make sure adjacendies are symmetric
        // make sure edges are in sync with adjacencies
        // make sures faces are valid
        // make sure no crossings
        for (u,v) in self.edges {
            assert(self.vertexPayloads[u]!.adjacencies.contains(v))
        }
    }

    @discardableResult
    private mutating func subdivideEdge(between u: Vertex, and w: Vertex, at position: CGPoint? = nil) -> Vertex {
        assert(self.vertices(adjacentTo: u).contains(w))

        let position = position ?? CGPoint.centroid(of: [u, w].map(self.position(of:)))

        let v = self.insertVertex(at: position)
//        print("subdivide \(u)-\(w) with \(v)")
        self.edges.replaceFirst(of: (u,w), (w,u), with: (u,v), by: ==)
        self.edges.append((v,w))
        self.vertexPayloads[u]!.adjacencies.replaceFirst(of: w, with: v, by: ==)
        self.vertexPayloads[w]!.adjacencies.replaceFirst(of: u, with: v, by: ==)
        self.vertexPayloads[v]!.adjacencies = [u, w]

        for (face, payload) in self.facePayloads {
            if let index = Face(vertices: payload.boundary).indexOfEdge(between: u, and: w) {
                self.facePayloads[face]!.boundary.insert(v, at: index + 1)
            }
        }

        return v
    }

    private mutating func contractEdge(from y: Vertex, into x: Vertex) {
        assert(self.vertices(adjacentTo: x).contains(y))
        assert(self.vertex(adjacentTo: x, and: y) == nil)
        assert(!self.isSubdivisionVertex(x))
        assert(self.isSubdivisionVertex(y))

//        print("contract \(y) into \(x)")

        let z = self.vertices(adjacentTo: y).first(where: { $0 != x })!

        self.edges.deleteFirst(of: (x,y), (y,x), by: ==)
        self.edges.replaceFirst(of: (y,z), (z,y), with: (x,z), by: ==)
        self.vertices.deleteFirst(of: y, by: ==)
        self.vertexPayloads[y] = nil
        self.vertexPayloads[x]!.adjacencies.replaceFirst(of: y, with: z, by: ==)
        self.vertexPayloads[z]!.adjacencies.replaceFirst(of: y, with: x, by: ==)

        for (face, payload) in self.facePayloads {
            if let index = payload.boundary.firstIndex(of: y) {
                self.facePayloads[face]!.boundary.remove(at: index)
            }
        }
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
