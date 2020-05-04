//
//  Pipeline+FlipAdjacency.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 30.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry

extension PolygonalDual {
    mutating func flipRandomAdjacency<T>(using generator: inout T) throws where T: RandomNumberGenerator {
//        let things = self.faces.strictlyTriangularPairs().filter({ self.thing(between: $0, and: $1) != nil })
        //
        //        guard let (f, g) = flippableAdjacencies.randomElement(using: &generator) else { throw UnsupportedOperationError() }
        //
        //        try! self.flipAdjanency(between: f, and: g)
        print(self.faces.strictlyTriangularPairs().compactMap(self.operation(between:and:)))
    }

    private func operation(between u: FaceID, and v: FaceID) -> Operation? {
        let bu = self.boundary(of: u)
        let bv = self.boundary(of: v)
        let fu = Face(vertices: bu)
        let fv = Face(vertices: bv)

        // u = left, v = right
        // x = above, y = below

        let boundary = self.computeBoundary(between: bu, and: bv)
        if let boundary = boundary {
            let fx = self.thirdFace(incidentTo: boundary.shared.last!, thatIsNot: fu, fv)
            let fy = self.thirdFace(incidentTo: boundary.shared.first!, thatIsNot: fu, fv)

            switch (self.polygon(on: fx.vertices).area > 0, self.polygon(on: fy.vertices).area > 0) {
            case (false, false):
                fatalError()
            case (false, true), (true, false):
                // outer face is one for both of them!
                if self.numberOfFaces(incidentTo: u) >= 4 && self.numberOfFaces(incidentTo: v) >= 4 {
                    print("can remove \(u)-\(v)")
                } else {
                    print("cannot remove \(u)-\(v), not both deg ≥ 3")
                }
            case (true, true):
                if self.computeBoundary(between: fx.vertices, and: fy.vertices) == nil {
                    print("can flip internal \(u)-\(v)")
                } else {
                    print("cannot flip internal \(u)-\(v), \(self.name(of: fx)!) and \(self.name(of: fy)!) are already incident")
                    return .none
                }
            }
        } else {
            // have function to determine faces incident to some face
            // have function to check if face is outer face
            // have function to check if face is incident to outer face

            // ensure u and v lie on the outer face
            // find faces that are incident to u, v, and the outer face
            // there can be multiple!
            // return both as candidates!

            // we might even return proper edge here if one wants to flip an edge that does not exist but its flipped one does? i.e. if one specifies what one wants to have, not what one wants to remove?

            print("uhm", u, v)
        }

        return .none
    }

    /// includes outer face
    private func numberOfFaces(incidentTo face: FaceID) -> Int {
        let joints = self.boundary(of: face).filter(self.isJoint(_:))
        return joints.count
    }

    private func thirdFace(incidentTo vertex: Vertex, thatIsNot first: Face<Vertex>, _ second: Face<Vertex>) -> Face<Vertex> {
        precondition(self.isJoint(vertex))

        var faces = Set(self.faces(incidentTo: vertex))
        assert(faces.count == 3)
        faces.remove(first)
        faces.remove(second)
        assert(faces.count == 1)
        return faces.first!
    }
}

private enum Operation {
    case flip(u: ClusterName, v: ClusterName, x: ClusterName, y: ClusterName) // x, y are just precomputed helpers
    case remove(u: ClusterName, v: ClusterName, w: ClusterName) // v is just precomputed helper
    case insert(u: ClusterName, v: ClusterName, w: ClusterName) // all 3 required to uniquely determine
}

// FIXME:
extension PolygonalDual {
    private struct Adjacency {
        let left: FaceID
        let right: FaceID
        let above: FaceID
        let below: FaceID
        let boundary: [Vertex]
    }



    mutating func flipAdjanency(between f: FaceID, and g: FaceID) throws {
//        guard self.faces.contains(f) else { throw UnsupportedOperationError() }
//        guard self.faces.contains(g) else { throw UnsupportedOperationError() }
//        guard let adjacency = self.adjacency(between: f, and: g) else { throw UnsupportedOperationError() }
//
//        try! self.flipBorder(between: adjacency.left, and: adjacency.right)
    }

//    private func adjacency(between left: Face, and right: Face) -> Adjacency? {
//        guard left != right else { return nil }
//
//        let boundaryF = self.boundary(of: left)
//        let boundaryG = Set(self.boundary(of: right))
//
//        guard let index = boundaryF.firstIndex(where: boundaryG.contains) else { return nil }
//
//        // Shared boundary
//        let rotated = boundaryF.rotated(shiftingToStart: index)
//        let boundary = rotated.suffix(while: boundaryG.contains) + rotated.prefix(while: boundaryG.contains) as [Vertex]
//
//        assert(boundary.adjacentPairs(wraparound: false).allSatisfy(self.containsEdge(between:and:)))
//        assert(boundary.count(where: { !self.isSubdivisionVertex($0) }) == 2)
//        assert(boundary.dropFirst().dropLast().allSatisfy(self.isSubdivisionVertex(_:)))
//
//        let remainingFaces = Set(self.faces).subtracting([left, right])
//        guard let above = remainingFaces.first(where: { self.boundary(of: $0).contains(boundary.last!) }) else { return nil }
//        guard let below = remainingFaces.first(where: { self.boundary(of: $0).contains(boundary.first!) }) else { return nil }
//
//        // Faces must not already be adjacent!
//        guard Set(self.boundary(of: above)).isDisjoint(with: self.boundary(of: below)) else { return nil }
//
//        return Adjacency(left: left, right: right, above: above, below: below, boundary: boundary)
//    }
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
        let incidentFaces = self.internalFaces(incidentTo: (u, v))
        guard incidentFaces.count == 2 else { return nil }
        guard incidentFaces.allSatisfy({ $0.vertices.count == 3 }) else { return nil }
        let left = incidentFaces[0].vertices[2]
        let right = incidentFaces[1].vertices[2]

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
}
