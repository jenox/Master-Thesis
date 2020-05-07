//
//  PolygonalDual.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 03.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry

struct PolygonalDual {
    init() {}

    typealias Vertex = UniquelyIdentifiedVertex
    typealias FaceID = ClusterName
    typealias Weight = ClusterWeight

    typealias VertexPayload = (neighbors: OrderedSet<Vertex>, position: CGPoint)
    typealias FacePayload = (boundary: [Vertex], weight: Weight)

    var vertices: OrderedSet<Vertex> = []
    var vertexPayloads: [Vertex: VertexPayload] = [:]
    var faces: OrderedSet<FaceID> = []
    var facePayloads: [FaceID: FacePayload] = [:]
}

extension PolygonalDual {
    mutating func insertVertex(at position: CGPoint) -> Vertex {
        let vertex = Vertex()

        self.vertices.insert(vertex)
        self.vertexPayloads[vertex] = ([], position)

        return vertex
    }

    mutating func insertEdge(between u: Vertex, and v: Vertex) {
        assert(!self.vertexPayloads[u]!.neighbors.contains(v))
        assert(!self.vertexPayloads[v]!.neighbors.contains(u))

        self.insertEdge(from: u, to: v)
        self.insertEdge(from: v, to: u)
    }

    mutating func removeEdge(between u: Vertex, and v: Vertex) {
        assert(self.vertexPayloads[u]!.neighbors.contains(v))
        assert(self.vertexPayloads[v]!.neighbors.contains(u))

        self.vertexPayloads[u]!.neighbors.remove(v)
        self.vertexPayloads[v]!.neighbors.remove(u)
    }

    mutating func defineFace(named name: FaceID, boundedBy boundary: [Vertex], weight: Weight) {
        assert(self.facePayloads[name] == nil)
        assert(boundary.adjacentPairs(wraparound: true).allSatisfy(self.containsEdge(between:and:)))

        self.faces.insert(name)
        self.facePayloads[name] = (boundary, weight)
    }
}

extension PolygonalDual {
    func ensureIntegrity(strict: Bool) {
        switch self.validateIntegrity(strict: strict) {
        case .success:
            break
        case .failure(let error):
            print("Integrity violation:", error)
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

        return .success(())
    }
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

extension Polygon {
    /// https://stackoverflow.com/questions/4001745/testing-whether-a-polygon-is-simple-or-complex
    /// http://geomalgorithms.com/a09-_intersect-3.html#simple_Polygon()
    var isSimple: Bool {
        let segments = self.points.adjacentPairs(wraparound: true).map(Segment.init)

        return !segments.cartesianPairs().contains(where: { $0.intersects($1) })
    }
}

extension PolygonalDual {
    private mutating func insertEdge(from u: Vertex, to v: Vertex) {
        let angle = self.angle(from: u, to: v).counterclockwise

        var neighbors = self.vertexPayloads[u]!.neighbors
        let index = neighbors.firstIndex(where: { self.angle(from: u, to: $0).counterclockwise > angle }) ?? neighbors.endIndex
        neighbors.insert(v, at: index)
        self.vertexPayloads[u]!.neighbors = neighbors
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

extension PolygonalDual: StraightLineGraph {
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

    mutating func move(_ vertex: Vertex, to position: CGPoint) {
        self.vertexPayloads[vertex]!.position = position
    }
}

extension PolygonalDual {
    func polygon(for face: FaceID) -> Polygon {
        return Polygon(points: self.boundary(of: face).map(self.position(of:)))
    }

    func area(of face: FaceID) -> Double {
        return Double(self.polygon(for: face).area)
    }

    func weight(of face: FaceID) -> Weight {
        return self.facePayloads[face]!.weight
    }

    mutating func setWeight(of face: FaceID, to value: Weight) {
        self.facePayloads[face]!.weight = value
    }

    func boundary(of face: FaceID) -> [Vertex] {
        return self.facePayloads[face]!.boundary
    }
}

extension PolygonalDual {
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

extension PolygonalDual {
    mutating func subdivideEdge(between u: Vertex, and w: Vertex) -> Vertex {
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

        self.ensureIntegrity(strict: false)

        return v
    }

    mutating func smooth(_ v: Vertex) throws {
        let neighbors = self.vertices(adjacentTo: v)
        let faces = self.faces(incidentTo: v)

        precondition(neighbors.count == 2)
        precondition(faces.count == 2)
        let (u, w) = (neighbors[0], neighbors[1])

        // No crossings
        guard self.polygon(on: faces[0].smoothing(vertex: v).vertices).isSimple else { throw UnsupportedOperationError() }
        guard self.polygon(on: faces[1].smoothing(vertex: v).vertices).isSimple else { throw UnsupportedOperationError() }

        // Ensure cyclic order stays the same
        let uw = self.angle(from: u, to: w).counterclockwise
        let wu = self.angle(from: w, to: u).counterclockwise
        var nu = self.vertexPayloads[u]!.neighbors
        var nw = self.vertexPayloads[w]!.neighbors
        let iu = nu.firstIndex(of: v)!
        let iw = nw.firstIndex(of: v)!
        nu.remove(v)
        nw.remove(v)
        let ju = nu.firstIndex(where: { self.angle(from: u, to: $0).counterclockwise > uw }) ?? nu.endIndex
        let jw = nw.firstIndex(where: { self.angle(from: w, to: $0).counterclockwise > wu }) ?? nw.endIndex
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

        self.ensureIntegrity(strict: false)
    }
}
