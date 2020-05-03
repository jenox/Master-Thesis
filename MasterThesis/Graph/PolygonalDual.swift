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
    typealias Face = ClusterName
    typealias Weight = ClusterWeight

    typealias VertexPayload = (neighbors: OrderedSet<Vertex>, position: CGPoint)
    typealias FacePayload = (boundary: [Vertex], weight: Weight)

    private(set) var vertices: OrderedSet<Vertex> = []
    private(set) fileprivate var vertexPayloads: [Vertex: VertexPayload] = [:]
    private(set) var faces: OrderedSet<Face> = []
    private(set) fileprivate var facePayloads: [Face: FacePayload] = [:]
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

    mutating func defineFace(named name: Face, boundedBy boundary: [Vertex], weight: Weight) {
        assert(self.facePayloads[name] == nil)
        assert(boundary.adjacentPairs(wraparound: true).allSatisfy(self.containsEdge(between:and:)))

        self.faces.insert(name)
        self.facePayloads[name] = (boundary, weight)
    }
}

extension PolygonalDual {
    func ensureIntegrity() {
        switch validateIntegrity() {
        case .success:
            break
        case .failure(let error):
            fatalError("Integrity violation: \(error)")
        }
    }

    func validateIntegrity() -> Result<Void, PolygonalDualIntergrityViolation> {
        guard self.vertices.count >= 3 else { return .failure(.tooFewVertices) }

        for vertex in self.vertices {
            guard 2...3 ~= self.vertexPayloads[vertex]!.neighbors.count else { return .failure(.invalidVertexDegree) }
        }

        // symmetric adjacencies
        for vertex in self.vertices {
            for neighbor in self.vertexPayloads[vertex]!.neighbors {
                guard self.vertexPayloads[neighbor]!.neighbors.contains(vertex) else { return .failure(.asymmetricAdjacencies) }
            }
        }

        let boundaries = self.facePayloads.map({ $0.value.boundary })
        let (internalFaces, outerFace) = self.internalFacesAndOuterFace()

        guard internalFaces.count == boundaries.count else { return .failure(.corruptFaceRepresentation) }

        // edges on cached boundaries
        for boundary in boundaries {
            for (u,v) in boundary.adjacentPairs(wraparound: true) {
                guard self.vertexPayloads[u]!.neighbors.contains(v) else { return .failure(.corruptFaceRepresentation) }
            }

            guard internalFaces.contains(MasterThesis.Face(vertices: boundary)) else { return .failure(.corruptFaceRepresentation) }
        }

        for face in internalFaces {
            guard self.polygon(on: face.vertices).isSimple else { return .failure(.nonSimplePolygonalFaces) }
        }
        guard self.polygon(on: outerFace.vertices).isSimple else { return .failure(.nonSimplePolygonalFaces) }

        // edge crossings? or is this already covered by simpleness?

        return .success(())
    }
}

enum PolygonalDualIntergrityViolation: Error {
    case tooFewVertices
    case invalidVertexDegree
    case asymmetricAdjacencies
    case corruptFaceRepresentation
    case nonSimplePolygonalFaces
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
    func polygon(for face: Face) -> Polygon {
        return Polygon(points: self.boundary(of: face).map(self.position(of:)))
    }

    func area(of face: Face) -> Double {
        return Double(self.polygon(for: face).area)
    }

    func weight(of face: Face) -> Weight {
        return self.facePayloads[face]!.weight
    }

    mutating func setWeight(of face: Face, to value: Weight) {
        self.facePayloads[face]!.weight = value
    }

    func boundary(of face: Face) -> [Vertex] {
        return self.facePayloads[face]!.boundary
    }
}

extension PolygonalDual {
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
}

//extension PolygonalDual {
//    mutating func contractEdgeIfPossible(between a: Vertex, and b: Vertex) {
//        assert(self.vertex(adjacentTo: a, and: b) == nil)
//
//        // cannot contract edge between 2 3-degree vertices
//        // we have u-v-w with v having no further neighbors
//        guard let v = [a, b].first(where: { self.degree(of: $0) == 2 }) else { return }
//        let u = v == a ? b : a
//        let w = self.vertices(adjacentTo: v).first(where: { $0 != u })!
//
//        // TODO: must be able to be contracted WITHOUT introducing crossings
//
//        // contract v "into" u
//        var copy = self
//        copy.edges.deleteFirst(of: (u,v), (v,u), by: ==)
//        copy.edges.replaceFirst(of: (v,w), (w,v), with: (u,w), by: ==)
//        copy.vertices.deleteFirst(of: v, by: ==)
//        copy.vertexPayloads[v] = nil
//        copy.vertexPayloads[u]!.adjacencies.replaceFirst(of: v, with: w, by: ==)
//        copy.vertexPayloads[w]!.adjacencies.replaceFirst(of: v, with: u, by: ==)
//
//        guard copy.isCrossingFree() else {
//            print("Could not contract edge \(a)-\(b): would create edge crossing!")
//            return
//        }
//
//        print("Contracting edge \(a)-\(b)...")
//
//        self = copy
//
//        // Fix faces
//        for (face, payload) in self.facePayloads {
//            if let index = payload.boundary.firstIndex(of: v) {
//                self.facePayloads[face]!.boundary.remove(at: index)
//            }
//        }
//    }
//
//    func firstEdgeCrossing() -> (Segment, Segment)? {
//        for ((u,v),(w,x)) in self.edges.strictlyTriangularPairs() where Set([u,v,w,x]).count == 4 {
//            let s1 = self.segment(from: u, to: v)
//            let s2 = self.segment(from: w, to: x)
//            if s1.intersects(s2) {
//                return (s1, s2)
//            }
//        }
//
//        return nil
//    }
//
//    func isCrossingFree() -> Bool {
//        return self.firstEdgeCrossing() == nil
//    }
//
//    func boundary(between left: Face, and right: Face) -> [Vertex]? {
//        let left = self.boundary(of: left)
//        let right = Set(self.boundary(of: right))
//        guard let index = left.firstIndex(where: right.contains) else { return nil }
//
//        let rotated = left.rotated(by: index)
//        let boundary = Array(rotated.reversed().prefix(while: right.contains).reversed() + rotated.prefix(while: right.contains))
//
//        assert(boundary.adjacentPairs(wraparound: false).allSatisfy(self.containsEdge(between:and:)))
//        assert(boundary.count(where: { !self.isSubdivisionVertex($0) }) == 2)
//        assert(boundary.dropFirst().dropLast().allSatisfy(self.isSubdivisionVertex(_:)))
//
//        return boundary
//    }
//
//    mutating func flipBorder(between left: Face, and right: Face) throws {
//        var shared = self.boundary(between: left, and: right)!
//        print("Boundary of \(left.rawValue) and \(right.rawValue): \(shared)")
//
//        while shared.count >= 3 {
//            // contract edge x-y; a,b other neighbors to x
//            let others = self.vertices(adjacentTo: shared[0]).filter({ $0 != shared[1] })
//            assert(others.count == 2)
//
//            let y = self.position(of: shared[1])
//            // TODO: maybe binary search this down from 0.5 while preserving crossings?
//            let xa = self.segment(from: shared[0], to: others[0]).point(at: 0.3)
//            let xb = self.segment(from: shared[0], to: others[1]).point(at: 0.3)
//
//            self.contractEdge(from: shared[1], into: shared[0])
//            self.move(shared[0], to: y)
//            self.subdivideEdge(between: shared[0], and: others[0], at: xa)
//            self.subdivideEdge(between: shared[0], and: others[1], at: xb)
//
//            shared.remove(at: 1)
//            shared.reverse()
//        }
//
//        assert(!self.isSubdivisionVertex(shared[0]))
//        assert(!self.isSubdivisionVertex(shared[1]))
//
//        let middle = CGPoint.centroid(of: shared.map(self.position(of:)))
//        let vector = CGVector(from: self.position(of: shared[0]), to: middle).rotated(by: .init(degrees: 90))
//        self.move(shared[0], to: middle + 0.01 * vector)
//        self.move(shared[1], to: middle - 0.01 * vector)
//
//        func relocate(_ a: Vertex, _ b: Vertex) {
//            let others = self.vertices(adjacentTo: a).filter({ $0 != b })
//            let c = others[0]
//            let d = others[1]
//
//            if !self.segment(from: a, to: c).intersects(self.segment(from: b, to: d)) {
//                self.edges.replaceFirst(of: (a,d),(d,a), with: (b,d), by: ==)
//                self.vertexPayloads[d]!.adjacencies.replaceFirst(of: a, with: b, by: ==)
//                self.vertexPayloads[a]!.adjacencies.deleteFirst(of: d, by: ==)
//                self.vertexPayloads[b]!.adjacencies.append(d)
//
//                let face = self.faces.first(where: { $0 != left && $0 != right && MasterThesis.Face(vertices: self.boundary(of: $0)).containsEdge(between: a, and: d) })!
//                let index = MasterThesis.Face(vertices: self.boundary(of: face)).indexOfEdge(between: a, and: d)!
//                self.facePayloads[face]!.boundary.insert(b, at: index + 1)
//            } else if !self.segment(from: a, to: d).intersects(self.segment(from: b, to: c)) {
//                self.edges.replaceFirst(of: (a,c),(c,a), with: (b,c), by: ==)
//                self.vertexPayloads[c]!.adjacencies.replaceFirst(of: a, with: b, by: ==)
//                self.vertexPayloads[a]!.adjacencies.deleteFirst(of: c, by: ==)
//                self.vertexPayloads[b]!.adjacencies.append(c)
//
//                let face = self.faces.first(where: { $0 != left && $0 != right && MasterThesis.Face(vertices: self.boundary(of: $0)).containsEdge(between: a, and: c) })!
//                let index = MasterThesis.Face(vertices: self.boundary(of: face)).indexOfEdge(between: a, and: c)!
//                self.facePayloads[face]!.boundary.insert(b, at: index + 1)
//            } else {
//                fatalError()
//            }
//        }
//
//        relocate(shared[0], shared[1])
//        relocate(shared[1], shared[0])
//
//        for face in [left, right] {
//            let boundary = self.boundary(of: face)
//            let vertex = [shared[0], shared[1]].first(where: { self.vertices(adjacentTo: $0).count(where: boundary.contains(_:)) == 1 })!
//            self.facePayloads[face]!.boundary.removeAll(where: { $0 == vertex })
//        }
//
//        self.ensureIntegrity()
//    }
//
//    func ensureIntegrity() {
//        // make sure adjacendies are symmetric
//        // make sure edges are in sync with adjacencies
//        // make sures faces are valid
//        // make sure no crossings
//        for (u,v) in self.edges {
//            assert(self.vertexPayloads[u]!.adjacencies.contains(v))
//        }
//    }
//
//    @discardableResult
//    private mutating func subdivideEdge(between u: Vertex, and w: Vertex, at position: CGPoint? = nil) -> Vertex {
//        assert(self.vertices(adjacentTo: u).contains(w))
//
//        let position = position ?? CGPoint.centroid(of: [u, w].map(self.position(of:)))
//
//        let v = self.insertVertex(at: position)
//        //        print("subdivide \(u)-\(w) with \(v)")
//        self.edges.replaceFirst(of: (u,w), (w,u), with: (u,v), by: ==)
//        self.edges.append((v,w))
//        self.vertexPayloads[u]!.adjacencies.replaceFirst(of: w, with: v, by: ==)
//        self.vertexPayloads[w]!.adjacencies.replaceFirst(of: u, with: v, by: ==)
//        self.vertexPayloads[v]!.adjacencies = [u, w]
//
//        for (face, payload) in self.facePayloads {
//            if let index = MasterThesis.Face(vertices: payload.boundary).indexOfEdge(between: u, and: w) {
//                self.facePayloads[face]!.boundary.insert(v, at: index + 1)
//            }
//        }
//
//        return v
//    }
//
//    private mutating func contractEdge(from y: Vertex, into x: Vertex) {
//        assert(self.vertices(adjacentTo: x).contains(y))
//        assert(self.vertex(adjacentTo: x, and: y) == nil)
//        assert(!self.isSubdivisionVertex(x))
//        assert(self.isSubdivisionVertex(y))
//
//        //        print("contract \(y) into \(x)")
//
//        let z = self.vertices(adjacentTo: y).first(where: { $0 != x })!
//
//        self.edges.deleteFirst(of: (x,y), (y,x), by: ==)
//        self.edges.replaceFirst(of: (y,z), (z,y), with: (x,z), by: ==)
//        self.vertices.deleteFirst(of: y, by: ==)
//        self.vertexPayloads[y] = nil
//        self.vertexPayloads[x]!.adjacencies.replaceFirst(of: y, with: z, by: ==)
//        self.vertexPayloads[z]!.adjacencies.replaceFirst(of: y, with: x, by: ==)
//
//        for (face, payload) in self.facePayloads {
//            if let index = payload.boundary.firstIndex(of: y) {
//                self.facePayloads[face]!.boundary.remove(at: index)
//            }
//        }
//    }
//}

//private extension Array {
//    mutating func deleteFirst(of values: Element..., by isEqual: (Element, Element) -> Bool) {
//        let index = self.firstIndex(where: { element in values.contains(where: { isEqual($0, element) }) })!
//        self.swapAt(index, self.indices.last!)
//        self.removeLast()
//    }
//
//    mutating func replaceFirst(of values: Element..., with replacement: Element, by isEqual: (Element, Element) -> Bool) {
//        let index = self.firstIndex(where: { element in values.contains(where: { isEqual($0, element) }) })!
//        self[index] = replacement
//    }
//
//    func rotated(by offset: Int) -> [Element] {
//        assert(self.indices.contains(offset))
//        return Array(self.dropFirst(offset)) + self.prefix(offset)
//    }
//}
