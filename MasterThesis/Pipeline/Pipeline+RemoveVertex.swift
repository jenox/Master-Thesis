//
//  Pipeline+RemoveVertex.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 04.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

extension PolygonalDual {
    struct RemoveFaceWithoutBoundaryToExternalFaceOperation: Equatable, Hashable {
        init(name: ClusterName) {
            self.name = name
        }

        let name: ClusterName
    }

    func possibleRemoveFaceWithoutBoundaryToExternalFaceOperations() -> Set<RemoveFaceWithoutBoundaryToExternalFaceOperation> {
        return Set(self.embeddedClusterGraph.removableInternalVertices.map(RemoveFaceWithoutBoundaryToExternalFaceOperation.init))
    }

    mutating func removeFaceWithoutBoundaryToExternalFace(_ operation: RemoveFaceWithoutBoundaryToExternalFaceOperation) throws {
        try self.removeFace(operation.name)
    }
}

extension PolygonalDual {
    struct RemoveFaceWithBoundaryToExternalFaceOperation: Equatable, Hashable {
        init(name: ClusterName) {
            self.name = name
        }

        let name: ClusterName
    }

    func possibleRemoveFaceWithBoundaryToExternalFaceOperations() -> Set<RemoveFaceWithBoundaryToExternalFaceOperation> {
        return Set(self.embeddedClusterGraph.removableExternalVertices.map(RemoveFaceWithBoundaryToExternalFaceOperation.init))
    }

    mutating func removeFaceWithBoundaryToExternalFace(_ operation: RemoveFaceWithBoundaryToExternalFaceOperation) throws {
        try self.removeFace(operation.name)
    }
}

private extension PolygonalDual {
    mutating func removeFace(_ faceID: FaceID) throws {
        guard self.faces.contains(faceID) else { throw UnsupportedOperationError() }

        let face = Face(vertices: self.facePayloads[faceID]!.boundary)
        let joints = face.vertices.filter(self.isJoint(_:))

        guard joints.count == 3 else { throw UnsupportedOperationError() }

        var faces: Set<Face<Vertex>> = []
        faces.formUnion(self.faces(incidentTo: joints[0]))
        faces.formUnion(self.faces(incidentTo: joints[1]))
        faces.formUnion(self.faces(incidentTo: joints[2]))
        faces.remove(face)
        assert(faces.count == 3)

        let neighbor = faces.max(by: { abs(self.polygon(on: $0.vertices).area) })!
        let (joined, boundary) = self.computeBoundary(between: face.vertices, and: neighbor.vertices)!

        for (u,v) in boundary.adjacentPairs(wraparound: false) {
            self.removeEdge(between: u, and: v)
        }
        for v in boundary.dropFirst().dropLast() {
            self.vertices.remove(v)
            self.vertexPayloads[v] = nil
        }
        self.faces.remove(faceID)
        self.facePayloads[faceID] = nil
        if let neighborID = self.faces.first(where: { neighbor == .init(vertices: self.boundary(of: $0)) }) {
            self.facePayloads[neighborID]!.boundary = joined
        } else {
            // no-op
        }

        self.ensureIntegrity(strict: true)
    }
}

private extension EmbeddedClusterGraph {
    /// We can only remove an internal vertex if the graph remains internally
    /// triangulated. This is the case if the vertex to be removed has degree 3.
    var removableInternalVertices: [Vertex] {
        return self.internalVertices.filter({ self.degree(of: $0) == 3 })
    }

    /// We can only remove an external vertex if the graph remains 2-connected.
    /// Because we only allow removing vertices with degree 2, this is the case
    /// if the graph would have 3+ vertices remaining.
    var removableExternalVertices: [Vertex] {
        guard self.vertices.count >= 4 else { return [] }

        return self.externalVertices.filter({ self.degree(of: $0) == 2 })
    }
}
