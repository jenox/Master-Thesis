//
//  PolygonalDual.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 03.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry

protocol PolygonalDualRequirements: StraightLineGraph {
    var faces: OrderedSet<ClusterName> { get }
    var embeddedClusterGraph: EmbeddedClusterGraph { get }

    func vertex(adjacentTo u: UniquelyIdentifiedVertex, and v: UniquelyIdentifiedVertex) -> UniquelyIdentifiedVertex?
    func polygon(for face: ClusterName) -> Polygon
    func area(of face: ClusterName) -> Double
    func weight(of face: ClusterName) -> ClusterWeight
    mutating func setWeight(of face: ClusterName, to value: ClusterWeight)
    func boundary(of face: ClusterName) -> [UniquelyIdentifiedVertex]
}

enum PolygonalDualIntergrityViolation: Error {
    case fatal
    case invalidVertexDegree
    case asymmetricAdjacencies
    case corruptFaceRepresentation1
    case corruptFaceRepresentation2
    case corruptFaceRepresentation3
    case corruptFaceRepresentation4
    case nonSimplePolygonalFaces1
    case nonSimplePolygonalFaces2
    case nonSimplePolygonalFaces3
    case nonSimplePolygonalFaces4
    case edgeCrossing
}

public struct PolygonalDual {
    public typealias Vertex = UniquelyIdentifiedVertex
    typealias FaceID = ClusterName
    typealias Weight = ClusterWeight

    init() {
        self.storage = .init()
    }

    private(set) var storage: MutablePolygonalDual

    mutating func ensureValueSemantics() {
        if !isKnownUniquelyReferenced(&self.storage) {
            self.storage = self.storage.clone()
        }
    }

    mutating func insertVertex(at position: CGPoint) -> Vertex {
        self.ensureValueSemantics()
        return self.storage.insertVertex(at: position)
    }

    mutating func insertEdge(between u: Vertex, and v: Vertex) {
        self.ensureValueSemantics()
        self.storage.insertEdge(between: u, and: v)
    }

    mutating func removeEdge(between u: Vertex, and v: Vertex) {
        self.ensureValueSemantics()
        self.storage.removeEdge(between: u, and: v)
    }

    mutating func defineFace(named name: FaceID, boundedBy boundary: [Vertex], weight: Weight) {
        self.ensureValueSemantics()
        self.storage.defineFace(named: name, boundedBy: boundary, weight: weight)
    }

    public func ensureIntegrity(strict: Bool) {
        self.storage.ensureIntegrity(strict: strict)
    }

    func validateIntegrity(strict: Bool) -> Result<Void, PolygonalDualIntergrityViolation> {
        return self.storage.validateIntegrity(strict: strict)
    }

    public func isBend(_ vertex: UniquelyIdentifiedVertex) -> Bool {
        return self.degree(of: vertex) == 2
    }
}

extension PolygonalDual: StraightLineGraph {
    typealias Vertices = OrderedSet<Vertex>
    typealias Edges = DirectedEdgeIterator<Vertex>

    public var vertices: OrderedSet<Vertex> {
        return self.storage.vertices
    }

    public var edges: DirectedEdgeIterator<Vertex> {
        return self.storage.edges
    }

    func vertices(adjacentTo vertex: Vertex) -> OrderedSet<Vertex> {
        return self.storage.vertices(adjacentTo: vertex)
    }

    public func position(of vertex: Vertex) -> CGPoint {
        return self.storage.position(of: vertex)
    }

    mutating func move(_ vertex: Vertex, to position: CGPoint) {
        self.ensureValueSemantics()
        self.storage.move(vertex, to: position)
    }
}

extension PolygonalDual: PolygonalDualRequirements {
    public var faces: OrderedSet<ClusterName> {
        return self.storage.faces
    }

    public var embeddedClusterGraph: EmbeddedClusterGraph {
        return self.storage.embeddedClusterGraph
    }

    func vertex(adjacentTo u: Vertex, and v: Vertex) -> Vertex? {
        return self.storage.vertex(adjacentTo: u, and: v)
    }

    public func polygon(for face: ClusterName) -> Polygon {
        return self.storage.polygon(for: face)
    }

    func area(of face: FaceID) -> Double {
        return self.storage.area(of: face)
    }

    public func weight(of face: ClusterName) -> ClusterWeight {
        return self.storage.weight(of: face)
    }

    mutating func setWeight(of face: FaceID, to value: Weight) {
        self.ensureValueSemantics()
        self.storage.setWeight(of: face, to: value)
    }

    func boundary(of face: FaceID) -> [Vertex] {
        return self.storage.boundary(of: face)
    }
}

extension PolygonalDual: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.storage = try container.decode(MutablePolygonalDual.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.storage)
    }
}

extension MutablePolygonalDual: PolygonalDualRequirements {
}



final class MutablePolygonalDual {
    init() {}

    typealias Vertex = UniquelyIdentifiedVertex
    typealias FaceID = ClusterName
    typealias Weight = ClusterWeight

    struct VertexPayload: Codable {
        var neighbors: OrderedSet<Vertex>
        var position: CGPoint
    }

    struct FacePayload: Codable {
        var boundary: [Vertex]
        var weight: Weight
    }

    var vertices: OrderedSet<Vertex> = []
    var vertexPayloads: [Vertex: VertexPayload] = [:]
    var faces: OrderedSet<FaceID> = []
    var facePayloads: [FaceID: FacePayload] = [:]
    var currentVertexIdentifier: Int = 0

    private var cachedEdgesAndVerticesToCheck: ([Vertex: DirectedEdgeSet<Vertex>], [Vertex: OrderedSet<Vertex>])? = nil
}

extension MutablePolygonalDual: Codable {
    enum CodingKeys: String, CodingKey {
        case vertices = "vertices"
        case vertexPayloads = "vertexPayloads"
        case faces = "faces"
        case facePayloads = "facePayloads"
        case currentVertexIdentifier = "currentVertexIdentifier"
    }

    convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.vertices = try container.decode(OrderedSet<Vertex>.self, forKey: .vertices)
        self.vertexPayloads = try container.decode([Vertex: VertexPayload].self, forKey: .vertexPayloads)
        self.faces = try container.decode(OrderedSet<FaceID>.self, forKey: .faces)
        self.facePayloads = try container.decode([FaceID: FacePayload].self, forKey: .facePayloads)
        self.currentVertexIdentifier = try container.decode(Int.self, forKey: .currentVertexIdentifier)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.vertices, forKey: .vertices)
        try container.encode(self.vertexPayloads, forKey: .vertexPayloads)
        try container.encode(self.faces, forKey: .faces)
        try container.encode(self.facePayloads, forKey: .facePayloads)
        try container.encode(self.currentVertexIdentifier, forKey: .currentVertexIdentifier)
    }

    func clone() -> MutablePolygonalDual {
        let copy = MutablePolygonalDual()
        copy.vertices = self.vertices
        copy.vertexPayloads = self.vertexPayloads
        copy.faces = self.faces
        copy.facePayloads = self.facePayloads
        copy.currentVertexIdentifier = self.currentVertexIdentifier

        return copy
    }

    // ImPrEd implementation detail, but has to live here for efficient caching.
    var edgesAndVerticesToCheck: ([Vertex: DirectedEdgeSet<Vertex>], [Vertex: OrderedSet<Vertex>]) {
        if let cachedEdgesAndVerticesToCheck = self.cachedEdgesAndVerticesToCheck {
            return cachedEdgesAndVerticesToCheck
        } else {
            let objects = self.computeEdgesAndVerticesToCheck()
            self.cachedEdgesAndVerticesToCheck = objects
            return objects
        }
    }

    func invalidateCaches() {
        self.cachedEdgesAndVerticesToCheck = nil
    }
}

extension MutablePolygonalDual {
    func insertVertex(at position: CGPoint) -> Vertex {
        let vertex = Vertex(id: self.currentVertexIdentifier)
        self.currentVertexIdentifier += 1

        self.vertices.insert(vertex)
        self.vertexPayloads[vertex] = .init(neighbors: [], position: position)
        self.invalidateCaches()

        return vertex
    }

    func insertEdge(between u: Vertex, and v: Vertex) {
        assert(!self.vertexPayloads[u]!.neighbors.contains(v))
        assert(!self.vertexPayloads[v]!.neighbors.contains(u))

        self.insertEdge(from: u, to: v)
        self.insertEdge(from: v, to: u)
    }

    func removeEdge(between u: Vertex, and v: Vertex) {
        assert(self.vertexPayloads[u]!.neighbors.contains(v))
        assert(self.vertexPayloads[v]!.neighbors.contains(u))

        self.vertexPayloads[u]!.neighbors.remove(v)
        self.vertexPayloads[v]!.neighbors.remove(u)
        self.invalidateCaches()
    }

    func defineFace(named name: FaceID, boundedBy boundary: [Vertex], weight: Weight) {
        assert(self.facePayloads[name] == nil)
        assert(boundary.adjacentPairs(wraparound: true).allSatisfy(self.containsEdge(between:and:)))

        self.faces.insert(name)
        self.facePayloads[name] = .init(boundary: boundary, weight: weight)
        self.invalidateCaches()
    }
}

extension MutablePolygonalDual {
    func ensureIntegrity(strict: Bool) {
        // TODO: maybe check that cached is still what slow would give us?
        switch self.validateIntegrity(strict: strict) {
        case .success:
            break
        case .failure(let error):
            print("Integrity violation:", error)
            fatalError()
        }
    }

    func validateIntegrity(strict: Bool) -> Result<Void, PolygonalDualIntergrityViolation> {
        guard self.vertices.count >= 3 else { return .failure(.fatal) }
        guard Set(self.vertices) == Set(self.vertexPayloads.keys) else { return .failure(.fatal) }
        guard Set(self.faces) == Set(self.facePayloads.keys) else { return .failure(.fatal) }

        // symmetric adjacencies
        for vertex in self.vertices {
            for neighbor in self.vertexPayloads[vertex]!.neighbors {
                guard self.vertexPayloads[neighbor]!.neighbors.contains(vertex) else { return .failure(.asymmetricAdjacencies) }
            }
        }

        for vertex in self.vertices {
            guard (strict ? 2...3 : 2...4) ~= self.vertexPayloads[vertex]!.neighbors.count else { return .failure(.invalidVertexDegree) }
        }

        for vertex in self.vertices {
            guard self.degree(of: vertex) == self.faces(incidentTo: vertex).count else { return .failure(.invalidVertexDegree) }
        }

        let boundaries = self.facePayloads.map({ $0.value.boundary })
        let (internalFaces, outerFace) = self.internalFacesAndOuterFace()

        guard internalFaces.count == boundaries.count else { return .failure(.corruptFaceRepresentation1) }

        // edges on cached boundaries
        for boundary in boundaries {
            for (u,v) in boundary.adjacentPairs(wraparound: true) {
                guard self.vertexPayloads[u]!.neighbors.contains(v) else { return .failure(.corruptFaceRepresentation2) }
            }

            guard internalFaces.contains(Face(vertices: boundary)) else { return .failure(.corruptFaceRepresentation3) }
            guard self.polygon(on: boundary).area > 0 else { return .failure(.corruptFaceRepresentation4) }
        }

        for face in internalFaces {
            guard self.polygon(on: face.vertices).isSimple else { return .failure(.nonSimplePolygonalFaces1) }
            guard self.polygon(on: face.vertices).area > 0 else { return .failure(.nonSimplePolygonalFaces2) }
        }
        guard self.polygon(on: outerFace.vertices).isSimple else { return .failure(.nonSimplePolygonalFaces3) }
        guard self.polygon(on: outerFace.vertices).area < 0 else { return .failure(.nonSimplePolygonalFaces4) }

        // edge crossings? or is this already covered by simpleness?

        if strict {
            _ = self.embeddedClusterGraph
        }

        return .success(())
    }
}

extension MutablePolygonalDual {
    private func insertEdge(from u: Vertex, to v: Vertex) {
        var neighbors = self.vertexPayloads[u]!.neighbors
        let angles = neighbors.map({ self.angle(from: u, to: $0).counterclockwise })
        let index = angles.index(forInserting: self.angle(from: u, to: v).counterclockwise)
        neighbors.insert(v, at: index)
        self.vertexPayloads[u]!.neighbors = neighbors
        self.invalidateCaches()
    }

    func containsEdge(between u: Vertex, and v: Vertex) -> Bool {
        return self.vertexPayloads[u]!.neighbors.contains(v)
    }

    func vertex(adjacentTo u: Vertex, and v: Vertex) -> Vertex? {
        let vertices = Set(self.vertexPayloads[u]!.neighbors).intersection(self.vertexPayloads[v]!.neighbors)

        assert(vertices.count <= 1)
        return vertices.first
    }
}

extension MutablePolygonalDual: StraightLineGraph {
    typealias Vertices = OrderedSet<Vertex>
    typealias Edges = DirectedEdgeIterator<Vertex>

    var edges: DirectedEdgeIterator<Vertex> {
        return DirectedEdgeIterator(vertices: self.vertices, neighbors: self.vertexPayloads.mapValues(\.neighbors))
    }

    func vertices(adjacentTo vertex: Vertex) -> OrderedSet<Vertex> {
        return self.vertexPayloads[vertex]!.neighbors
    }

    func position(of vertex: Vertex) -> CGPoint {
        return self.vertexPayloads[vertex]!.position
    }

    func move(_ vertex: Vertex, to position: CGPoint) {
        self.vertexPayloads[vertex]!.position = position
        // don't invalidate here, just assume it doesn't break shit
    }
}

extension MutablePolygonalDual {
    func polygon(for face: FaceID) -> Polygon {
        return Polygon(points: self.boundary(of: face).map(self.position(of:)))
    }

    func area(of face: FaceID) -> Double {
        return Double(self.polygon(for: face).area)
    }

    func weight(of face: FaceID) -> Weight {
        return self.facePayloads[face]!.weight
    }

    func setWeight(of face: FaceID, to value: Weight) {
        self.facePayloads[face]!.weight = value
    }

    func boundary(of face: FaceID) -> [Vertex] {
        return self.facePayloads[face]!.boundary
    }
}

extension MutablePolygonalDual {
    func isBend(_ vertex: Vertex) -> Bool {
        return self.degree(of: vertex) == 2
    }

    func isJoint(_ vertex: Vertex) -> Bool {
        return self.degree(of: vertex) == 3
    }

    func computeBoundary(between left: [Vertex], and right: [Vertex]) -> (joined: [Vertex], shared: [Vertex])? {
        let set = Set(right)
        guard let index = left.firstIndex(where: set.contains(_:)) else { return nil }

        let rotated1 = Array(left.rotated(shiftingToStart: index))
        let count = rotated1.reversed().prefix(while: set.contains(_:)).count
        let rotated2 = Array(rotated1.rotated(shiftingToStart: (rotated1.count - count) % rotated1.count))
        let shared = Array(rotated2.prefix(while: set.contains(_:)))
        let rotated3 = Array(right.rotated(shiftingToStart: right.firstIndex(of: shared.last!)!))

        var joined = [rotated2[0]]
        joined.append(contentsOf: rotated3.dropFirst(shared.count))
        joined.append(rotated3[0])
        joined.append(contentsOf: rotated2.dropFirst(shared.count))

        return (joined, shared)
    }
}


// MARK: - Subdivision & Smoothing

extension MutablePolygonalDual {
    @discardableResult
    func subdivideEdge(between u: Vertex, and w: Vertex) -> Vertex {
        precondition(self.vertices(adjacentTo: u).contains(w))

        let v = self.insertVertex(at: self.segment(from: u, to: w).midpoint)

        self.vertexPayloads[u]!.neighbors.replace(w, with: v)
        self.vertexPayloads[v]!.neighbors = [u, w]
        self.vertexPayloads[w]!.neighbors.replace(u, with: v)

        for (face, payload) in self.facePayloads {
            if let index = Face(vertices: payload.boundary).indexOfEdge(between: u, and: w) {
                self.facePayloads[face]!.boundary.insert(v, at: index + 1)
            }
        }

        self.invalidateCaches()
        self.ensureIntegrity(strict: false)

        return v
    }

    func smooth(_ v: Vertex) throws {
        let neighbors = self.vertices(adjacentTo: v)
        let faces = self.faces(incidentTo: v)

        precondition(neighbors.count == 2)
        precondition(faces.count == 2)
        let (u, w) = (neighbors[0], neighbors[1])

        // No crossings and same orientation as before
        guard self.polygon(on: faces[0].smoothing(vertex: v).vertices).isSimpleAndSameOrientation(as: self.polygon(on: faces[0].vertices)) else { throw UnsupportedOperationError() }
        guard self.polygon(on: faces[1].smoothing(vertex: v).vertices).isSimpleAndSameOrientation(as: self.polygon(on: faces[1].vertices)) else { throw UnsupportedOperationError() }

        // Ensure cyclic order stays the same
        let uw = self.angle(from: u, to: w).counterclockwise
        let wu = self.angle(from: w, to: u).counterclockwise
        var nu = self.vertexPayloads[u]!.neighbors
        var nw = self.vertexPayloads[w]!.neighbors
        let iu = nu.firstIndex(of: v)!
        let iw = nw.firstIndex(of: v)!
        nu.remove(v)
        nw.remove(v)
        let ju = nu.map({ self.angle(from: u, to: $0).counterclockwise }).index(forInserting: uw)
        let jw = nw.map({ self.angle(from: w, to: $0).counterclockwise }).index(forInserting: wu)
        guard abs(iu - ju) % nu.count == 0 else { throw UnsupportedOperationError() }
        guard abs(iw - jw) % nu.count == 0 else { throw UnsupportedOperationError() }

        self.vertices.remove(v)
        self.vertexPayloads[v] = nil
        self.vertexPayloads[u]!.neighbors.replace(v, with: w)
        self.vertexPayloads[w]!.neighbors.replace(v, with: u)

        for (face, payload) in self.facePayloads {
            if let index = payload.boundary.firstIndex(of: v) {
                self.facePayloads[face]!.boundary.remove(at: index)
            }
        }

        self.invalidateCaches()
        self.ensureIntegrity(strict: false)
    }
}


// MARK: - Misc

extension Array where Element == Angle {
    var isSortedWithOneDiscontinuity: Bool {
        return self.adjacentPairs(wraparound: true).filter(>=).count <= 1
    }

    func index(forInserting angle: Angle) -> Int {
        guard self.count >= 2 else { return self.endIndex }

        if !self.isSortedWithOneDiscontinuity {
            print(self)
        }
        assert(self.isSortedWithOneDiscontinuity)

        let angle = angle >= self.first! ? angle : angle + .init(turns: 1)

        var array = self
        if let i = array.indices.dropFirst().first(where: { array[$0] < array[$0 - 1] }) {
            for j in i..<array.endIndex {
                array[j] += .init(turns: 1)
            }
        }

        let index = array.firstIndex(where: { $0 > angle }) ?? array.endIndex

        var copy = self
        copy.insert(angle, at: index)
        assert(self.isSortedWithOneDiscontinuity)

        return index
    }
}
