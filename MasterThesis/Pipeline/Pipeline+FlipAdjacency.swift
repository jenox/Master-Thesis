//
//  Pipeline+FlipAdjacency.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 30.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry

extension VertexWeightedGraph {
    private struct Adjacency {
        let left: Vertex
        let right: Vertex
    }

    mutating func flipRandomEdge<T>(using generator: inout T) throws where T: RandomNumberGenerator {
        let flippableEdges = self.edges.filter({ $0.rawValue < $1.rawValue && self.incidentTriangleVertices(between: $0, and: $1) != nil })

        guard let (u, v) = flippableEdges.randomElement(using: &generator) else { throw UnsupportedOperationError() }

        try! self.flipEdge(between: u, and: v)
    }

    mutating func flipEdge(between u: Vertex, and v: Vertex) throws {
        guard self.vertices.contains(u) else { throw UnsupportedOperationError() }
        guard self.vertices.contains(v) else { throw UnsupportedOperationError() }
        guard let adjacency = self.incidentTriangleVertices(between: u, and: v) else { throw UnsupportedOperationError() }

        precondition(self.containsEdge(between: u, and: v))
        precondition(!self.containsEdge(between: adjacency.left, and: adjacency.right))

        self.removeEdge(between: u, and: v)
        self.insertEdge(between: adjacency.left, and: adjacency.right)
    }

    private func incidentTriangleVertices(between u: Vertex, and v: Vertex) -> Adjacency? {
        guard self.containsEdge(between: u, and: v) else { return nil }

        let sharedNeighbors = self.sharedNeighbors(between: u, and: v)
        precondition((1...).contains(sharedNeighbors.count))

        // We must have a triangle on either side to be able to flip an edge.
        let mapped = sharedNeighbors.map({ ($0, self.angle(from: v, by: u, to: $0)) })
        guard let left = mapped.filter({ $0.1 > .zero }).min(by: \.1)?.0 else { return nil }
        guard let right = mapped.filter({ $0.1 < .zero }).max(by: \.1)?.0 else { return nil }

        // The two vertices must not already be connected prior to the flip.
        guard !self.containsEdge(between: left, and: right) else { return nil }

        // For vertex-weighted graph only: the formed quadrilateral must be
        // strictly convex. Otherwise, by flipping the edge, we create a
        // quadrilateral face and potentially introduce crossings.
        let quadrilateral = Polygon(points: [u, left, v, right].map(self.position(of:)))
        guard quadrilateral.isStrictlyConvex else { return nil }

        return .init(left: left, right: right)
    }

    private func sharedNeighbors(between u: Vertex, and v: Vertex) -> Set<Vertex> {
        return Set(self.vertices(adjacentTo: u)).intersection(self.vertices(adjacentTo: v))
    }

    private func angle(from u: Vertex, by v: Vertex, to w: Vertex) -> Angle {
        return Angle(from: self.position(of: u), by: self.position(of: v), to: self.position(of: w))
    }
}

extension FaceWeightedGraph {
    private struct Adjacency {
        let left: Face
        let right: Face
        let above: Face
        let below: Face
        let boundary: [Vertex]
    }

    mutating func flipRandomAdjacency<T>(using generator: inout T) throws where T: RandomNumberGenerator {
        let flippableAdjacencies = self.faces.strictlyTriangularPairs().filter({ self.adjacency(between: $0, and: $1) != nil })

        guard let (f, g) = flippableAdjacencies.randomElement(using: &generator) else { throw UnsupportedOperationError() }

        try! self.flipAdjanency(between: f, and: g)
    }

    mutating func flipAdjanency(between f: Face, and g: Face) throws {
        guard self.faces.contains(f) else { throw UnsupportedOperationError() }
        guard self.faces.contains(g) else { throw UnsupportedOperationError() }
        guard let adjacency = self.adjacency(between: f, and: g) else { throw UnsupportedOperationError() }

        try! self.flipBorder(between: adjacency.left, and: adjacency.right)
    }

    private func adjacency(between left: Face, and right: Face) -> Adjacency? {
        guard left != right else { return nil }

        let boundaryF = self.boundary(of: left)
        let boundaryG = Set(self.boundary(of: right))

        guard let index = boundaryF.firstIndex(where: boundaryG.contains) else { return nil }

        // Shared boundary
        let rotated = boundaryF.rotated(shiftingToStart: index)
        let boundary = rotated.suffix(while: boundaryG.contains) + rotated.prefix(while: boundaryG.contains) as [Vertex]

        assert(boundary.adjacentPairs(wraparound: false).allSatisfy(self.containsEdge(between:and:)))
        assert(boundary.count(where: { !self.isSubdivisionVertex($0) }) == 2)
        assert(boundary.dropFirst().dropLast().allSatisfy(self.isSubdivisionVertex(_:)))

        let remainingFaces = Set(self.faces).subtracting([left, right])
        guard let above = remainingFaces.first(where: { self.boundary(of: $0).contains(boundary.last!) }) else { return nil }
        guard let below = remainingFaces.first(where: { self.boundary(of: $0).contains(boundary.first!) }) else { return nil }

        // Faces must not already be adjacent!
        guard Set(self.boundary(of: above)).isDisjoint(with: self.boundary(of: below)) else { return nil }

        return Adjacency(left: left, right: right, above: above, below: below, boundary: boundary)
    }
}

private extension BidirectionalCollection {
    func suffix(while predicate: (Element) throws -> Bool) rethrows -> AnyCollection<Element> {
        return AnyCollection(try self.reversed().prefix(while: predicate).reversed())
    }
}

private extension Polygon {
    var isStrictlyConvex: Bool {
        return self.internalAngles.allSatisfy({ $0.turns < 0.5 })
    }

    private var internalAngles: [Angle] {
        return self.points.adjacentTriplets(wraparound: true).map(Angle.init(from:by:to:)).map(\.counterclockwise)
    }
}

//extension Line {
//    /// http://geomalgorithms.com/a02-_lines.html
//    func signedDistance(to point: CGPoint) -> CGFloat {
//        let (x, y) = (point.x, point.y)
//        let (x0, y0) = (self.a.x, self.a.y)
//        let (x1, y1) = (self.b.x, self.b.y)
//
//        return (x*(y0-y1) + y*(x1-x0) + x0*y1 - x1*y0) / hypot(x1-x0, y1-y0)
//    }
//}

//extension Collection {
//    func destructured1() -> (Element)? {
//        let array = Array(self)
//        return array.count == 1 ? (array[0]) : nil
//    }
//
//    func destructured2() -> (Element, Element)? {
//        let array = Array(self)
//        return array.count == 2 ? (array[0], array[1]) : nil
//    }
//
//    func destructured3() -> (Element, Element, Element)? {
//        let array = Array(self)
//        return array.count == 3 ? (array[0], array[1], array[2]) : nil
//    }
//}
