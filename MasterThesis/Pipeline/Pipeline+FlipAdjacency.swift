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
    struct FlipAdjacencyOperation: Equatable, Hashable {
        init(between u: ClusterName, and v: ClusterName) {
            self.incidentFaces = [u, v]

            precondition(Set(self.incidentFaces).count == 2)
        }

        let incidentFaces: ClusterNameSet
    }

    func possibleFlipAdjacencyOperations() -> Set<FlipAdjacencyOperation> {
        return Set(self.embeddedClusterGraph.flippableInternalEdges.map(FlipAdjacencyOperation.init))
    }

    mutating func flipAdjacency(_ operation: FlipAdjacencyOperation) throws {
        // u = left, v = right
        // x = above, y = below
        let (u, v) = operation.incidentFaces.destructured2()!

        guard self.faces.contains(u) else { throw UnsupportedOperationError() }
        guard self.faces.contains(v) else { throw UnsupportedOperationError() }

        let bu = self.boundary(of: u)
        let bv = self.boundary(of: v)
        let fu = Face(vertices: bu)
        let fv = Face(vertices: bv)

        guard let boundary = self.computeBoundary(between: bu, and: bv)?.shared else { throw UnsupportedOperationError() }
        let fx = self.faces(incidentTo: boundary.last!).subtracting([fu, fv]).destructured1()!
        let fy = self.faces(incidentTo: boundary.first!).subtracting([fu, fv]).destructured1()!
        guard let x = self.faceID(of: fx) else { throw UnsupportedOperationError() }
        guard let y = self.faceID(of: fy) else { throw UnsupportedOperationError() }
        assert(x != y)
        guard self.computeBoundary(between: fx.vertices, and: fy.vertices) == nil else { throw UnsupportedOperationError() }

        let vertex = self.contractBoundary(boundary)
        self.ensureIntegrity(strict: false)
        self.expandDegenerateBoundary(at: vertex, into: u)
        self.expandDegenerateBoundary(at: vertex, into: v)
        self.ensureIntegrity(strict: true)
    }
}

extension PolygonalDual {
    struct CreateAdjacencyOperation: Equatable, Hashable {
        init(over sharedNeighbor: ClusterName) {
            self.sharedNeighbor = sharedNeighbor
        }

        let sharedNeighbor: ClusterName
    }

    func possibleCreateAdjacencyOperations() -> Set<CreateAdjacencyOperation> {
        return Set(self.embeddedClusterGraph.insertableEdges.map(CreateAdjacencyOperation.init))
    }

    mutating func createAdjacency(_ operation: CreateAdjacencyOperation) throws {
        let fv = Face(vertices: self.boundary(of: operation.sharedNeighbor))
        let fo = self.internalFacesAndOuterFace().outer
        let boundary = self.computeBoundary(between: fv.vertices, and: fo.vertices)!.shared
        let vertex = self.contractBoundary(boundary)
        self.ensureIntegrity(strict: false)
        self.expandDegenerateBoundary(at: vertex, into: nil)
        self.expandDegenerateBoundary(at: vertex, into: operation.sharedNeighbor)
        self.ensureIntegrity(strict: true)
    }
}

extension PolygonalDual {
    struct RemoveAdjacencyOperation: Equatable, Hashable {
        init(between u: ClusterName, and v: ClusterName) {
            self.incidentFaces = [u, v]

            precondition(Set(self.incidentFaces).count == 2)
        }

        let incidentFaces: ClusterNameSet
    }

    func possibleRemoveAdjacencyOperations() -> Set<RemoveAdjacencyOperation> {
        return Set(self.embeddedClusterGraph.removableEdges.map(RemoveAdjacencyOperation.init))
    }

    mutating func removeAdjacency(_ operation: RemoveAdjacencyOperation) throws {
        let (u, w) = operation.incidentFaces.destructured2()!

        guard self.faces.contains(u) else { throw UnsupportedOperationError() }
        guard self.faces.contains(w) else { throw UnsupportedOperationError() }

        let bu = self.boundary(of: u)
        let bw = self.boundary(of: w)
        let fu = Face(vertices: bu)
        let fw = Face(vertices: bw)

        // Must have a boundary
        guard let boundary = self.computeBoundary(between: bu, and: bw)?.shared else { throw UnsupportedOperationError() }

        // boundary must have one vertex on outer face and go inward;
        let fx = self.faces(incidentTo: boundary.last!).subtracting([fu, fw]).destructured1()!
        let fy = self.faces(incidentTo: boundary.first!).subtracting([fu, fw]).destructured1()!
        guard let v = [fx, fy].compactMap(self.faceID(of:)).destructured1() else { throw UnsupportedOperationError() }
        guard self.faces(incidentTo: fu).count >= 3 else { throw UnsupportedOperationError() }
        guard self.faces(incidentTo: fw).count >= 3 else { throw UnsupportedOperationError() }

        let vertex = self.contractBoundary(boundary)
        self.ensureIntegrity(strict: false)
        self.expandDegenerateBoundary(at: vertex, into: u)
        self.expandDegenerateBoundary(at: vertex, into: v)
        self.ensureIntegrity(strict: true)
    }
}

extension PolygonalDual {
    private mutating func contractBoundary(_ boundary: [Vertex]) -> Vertex {
        precondition(boundary.count >= 2)

        var boundary = boundary

        while boundary.count >= 2 {
            self.contract(boundary[0], into: boundary[1])
            boundary.reverse()
            boundary.removeLast()
        }

        return boundary.destructured1()!
    }

    private mutating func contract(_ u: Vertex, into v: Vertex) {
        precondition(self.vertices(adjacentTo: u).contains(v))
        precondition(self.degree(of: u) == 3)
        precondition(self.degree(of: v) >= 2)

        var faces = Array(self.faces(incidentTo: u))
        assert(faces.allSatisfy({ $0.vertices.first == u }))
        assert(faces.count == 3)
        faces = Array(faces.rotated(shiftingToStart: faces.first(where: { $0.containsEdge(from: u, to: v) })!))
        let left = self.faceID(of: faces[0])
        let below = self.faceID(of: faces[1])
        let right = self.faceID(of: faces[2])
        assert([left, below, right].compactMap({ $0 }).count >= 2) // only one can be outer face

        // Ensure the closest vertices are subdivision vertices
        for (index, neighbor) in faces.map({ $0.vertices[1] }).enumerated().dropFirst() where self.degree(of: neighbor) == 3 {
            let bend = self.subdivideEdge(between: u, and: neighbor)
            faces[index] = faces[index].inserting(bend, at: 1)
        }

        let leftBend: Vertex?
        do {
            let polygon = self.polygon(on: faces[0].vertices)
            let vertex = faces[1].vertices[1]

            if polygon.internalAngle(at: 0).turns > 0.5 {
                leftBend = self.insertVertex(at: self.position(of: u))
            } else if polygon.removingPoint(at: 0).isSimpleAndSameOrientation(as: polygon) {
                leftBend = nil
            } else {
                let midpoint = self.segment(from: vertex, to: v).midpoint
                let progresses = sequence(first: 0.5 as CGFloat, next: { $0 / 2 })
                let progress = progresses.first(where: { polygon.movingPoint(at: 0, to: midpoint, progress: $0).isSimpleAndSameOrientation(as: polygon) })!
                let position = polygon.movingPoint(at: 0, to: midpoint, progress: progress).points[0]

                leftBend = self.insertVertex(at: position)
            }
        }

        // right
        let rightBend: Vertex?
        do {
            let polygon = self.polygon(on: faces[2].vertices)
            let vertex = faces[2].vertices[1]

            if polygon.internalAngle(at: 0).turns > 0.5 {
                rightBend = self.insertVertex(at: self.position(of: u))
            } else if polygon.removingPoint(at: 0).isSimpleAndSameOrientation(as: polygon) {
                rightBend = nil
            } else {
                let midpoint = self.segment(from: vertex, to: v).midpoint
                let progresses = sequence(first: 0.5 as CGFloat, next: { $0 / 2 })
                let progress = progresses.first(where: { polygon.movingPoint(at: 0, to: midpoint, progress: $0).isSimpleAndSameOrientation(as: polygon) })!
                let position = polygon.movingPoint(at: 0, to: midpoint, progress: progress).points[0]

                rightBend = self.insertVertex(at: position)
            }
        }

        if let below = below { self.facePayloads[below]!.boundary.replace(u, with: [rightBend, v, leftBend].compactMap({ $0 })) }
        if let left = left { self.facePayloads[left]!.boundary.replace(u, with: [leftBend].compactMap({ $0 })) }
        if let right = right { self.facePayloads[right]!.boundary.replace(u, with: [rightBend].compactMap({ $0 })) }
        [faces[1].vertices[1], leftBend, v].compactMap({ $0 }).adjacentPairs(wraparound: false).forEach({ self.insertEdge(between: $0, and: $1) })
        [faces[2].vertices[1], rightBend, v].compactMap({ $0 }).adjacentPairs(wraparound: false).forEach({ self.insertEdge(between: $0, and: $1) })
        self.vertices.remove(u)
        self.vertexPayloads[u] = nil
        faces.forEach({ self.vertexPayloads[$0.vertices[1]]!.neighbors.remove(u) })
    }

    private mutating func expandDegenerateBoundary(at vertex: Vertex, into faceID: FaceID?) {
        let face = faceID.map({ Face(vertices: self.boundary(of: $0)) }) ?? self.internalFacesAndOuterFace().outer

        var faces = Array(self.faces(incidentTo: vertex))
        faces = Array(faces.rotated(shiftingToStart: face))
        assert(faces.count == 3 || faces.count == 4)
        let below = self.faceID(of: faces[1])
        let above = self.faceID(of: faces.last!)
        assert([below, above].compactMap({ $0 }).count >= 1) // only one can be the outer face

        // subdivide such that neighbors are bends
        var predecessor = face.predecessor(of: vertex)!
        var successor = face.successor(of: vertex)!
        assert(predecessor != successor)
        if !self.isBend(predecessor) { predecessor = self.subdivideEdge(between: vertex, and: predecessor) }
        if !self.isBend(successor) { successor = self.subdivideEdge(between: vertex, and: successor) }

        let boundary = faceID.map({ self.boundary(of: $0) }) ?? self.internalFacesAndOuterFace().outer.vertices
        let polygon = self.polygon(on: boundary)
        let index = boundary.firstIndex(of: vertex)!

        if polygon.internalAngle(at: index).turns >= 0.5 {
            // no-op
        } else {
            let midpoint = self.segment(from: predecessor, to: successor).midpoint
            let progresses = sequence(first: 1 as CGFloat, next: { $0 / 2 })
            let progress = progresses.first(where: { polygon.movingPoint(at: index, to: midpoint, progress: $0).isSimpleAndSameOrientation(as: polygon) })!
            let position = polygon.movingPoint(at: index, to: midpoint, progress: progress).points[index]

            guard position - polygon.points[index] != .zero else { return }

            let q = self.insertVertex(at: position)
            if let faceID = faceID { self.facePayloads[faceID]!.boundary.replace(vertex, with: [q]) }
            if let below = below { self.facePayloads[below]!.boundary.insert(q, after: vertex) }
            if let above = above { self.facePayloads[above]!.boundary.insert(q, before: vertex) }
            self.insertEdge(between: q, and: predecessor)
            self.insertEdge(between: q, and: successor)
            self.insertEdge(between: q, and: vertex)
            self.removeEdge(between: vertex, and: predecessor)
            self.removeEdge(between: vertex, and: successor)
        }
    }
}

private extension EmbeddedClusterGraph {
    /// We can only flip an internal edge if the graph remains simple. This is
    /// the case if the "tips" of the (triangular) faces incident to the edge
    /// aren't already adjacent.
    var flippableInternalEdges: [(Vertex, Vertex)] {
        var flippableEdges: [(Vertex, Vertex)] = []

        for (u, v) in self.internalEdges {
            let (f, g) = self.faces(incidentTo: (u, v))
            assert(f != g)
            assert(f.vertices.count == 3 && f.vertices.contains(u) && f.vertices.contains(v))
            assert(g.vertices.count == 3 && g.vertices.contains(u) && g.vertices.contains(v))
            let x = Set(f.vertices).subtracting([u,v]).first!
            let y = Set(g.vertices).subtracting([u,v]).first!

            guard !self.vertices(adjacentTo: x).contains(y) else { continue }

            flippableEdges.append((u, v))
            flippableEdges.append((v, u))
        }

        return flippableEdges
    }

    /// We can only remove an edge on the outer face if the graph remains
    /// 2-connected. This is the case if the edge's endpoints both have degree
    /// ≥ 3 and the third vertex in the internal face they are incident to
    /// doesn't already lie on the outer face.
    var removableEdges: [(Vertex, Vertex)] {
        var removableEdges: [(Vertex, Vertex)] = []

        for (u, v) in self.externalEdges {
            guard self.degree(of: u) >= 3 else { continue }
            guard self.degree(of: v) >= 3 else { continue }

            let tip = self.face(startingWith: (v, u)).vertices.destructured3()!.2
            guard !self.outerFace.vertices.contains(tip) else { continue }

            removableEdges.append((u, v))
            removableEdges.append((v, u))
        }

        for edge in removableEdges {
            let (f, g) = self.faces(incidentTo: (edge.0, edge.1))
            let `internal` = [f, g].filter({ $0 != self.outerFace }).destructured1()!
            let vertex = `internal`.vertices.filter({ $0 != edge.0 && $0 != edge.1 }).destructured1()!

            var copy = self
            copy.neighbors[edge.0]!.remove(edge.1)
            copy.neighbors[edge.1]!.remove(edge.0)
            copy.outerFaceBoundary.insert(vertex, at: self.outerFace.indexOfEdge(between: edge.0, and: edge.1)! + 1)

            try! copy.ensureIntegrity()
        }

        return removableEdges
    }

    /// We can only insert an edge into the outer face if the graph remains
    /// internally triangulated. This is the case if the edge's endpoints
    /// already have at least one neighbor on the outer face in common.
    ///
    /// If the edge's endpoints have two neighbors on the outer face in common,
    /// we must explicitly specify which of them becomes an internal vertex.
    var insertableEdges: [Vertex] {
        var insertableEdges: [Vertex] = []

        for (u, v, w) in self.externalVertices.adjacentTriplets(wraparound: true) {
            guard !self.vertices(adjacentTo: u).contains(w) else { continue }

            insertableEdges.append(v)
            insertableEdges.append(v)
        }

        return insertableEdges
    }
}

private extension Array where Element: Equatable {
    mutating func insert(_ element: Element, before other: Element) {
        self.insert(element, at: self.firstIndex(of: other)!)
    }

    mutating func insert(_ element: Element, after other: Element) {
        self.insert(element, at: self.firstIndex(of: other)! + 1)
    }

    mutating func replace<T>(_ element: Element, with elements: T) where T: Collection, T.Element == Element {
        let index = self.firstIndex(of: element)!
        self.replaceSubrange(index...index, with: elements)
    }
}
