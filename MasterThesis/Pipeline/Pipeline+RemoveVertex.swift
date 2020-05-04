//
//  Pipeline+RemoveVertex.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 04.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Foundation

extension PolygonalDual {
    mutating func removeRandomInternalFace<T>(
        using generator: inout T
    ) throws where T: RandomNumberGenerator {
        guard let face = self.categorizeRemovableFaces().internal.randomElement(using: &generator) else { throw UnsupportedOperationError() }

        try! self.removeFace(face)
    }

    mutating func removeRandomExternalFace<T>(
        using generator: inout T
    ) throws where T: RandomNumberGenerator {
        guard let face = self.categorizeRemovableFaces().external.randomElement(using: &generator) else { throw UnsupportedOperationError() }

        try! self.removeFace(face)
    }

    mutating func removeFace(_ faceID: Face) throws {
//        print("Removing face “\(faceID)”...")

        let face = MasterThesis.Face(vertices: self.facePayloads[faceID]!.boundary)
        let joints = face.vertices.filter(self.isJoint(_:))

        guard joints.count == 3 else { throw UnsupportedOperationError() }

        var faces: Set<MasterThesis.Face<Vertex>> = []
        faces.formUnion(self.faces(incidentTo: joints[0]))
        faces.formUnion(self.faces(incidentTo: joints[1]))
        faces.formUnion(self.faces(incidentTo: joints[2]))
        faces.remove(face)
        assert(faces.count == 3)

        let neighbor = faces.max(by: { abs(self.polygon(on: $0.vertices).area) })!
//        print("merge \(faceID) into \(neighbor)")
        let (joined, boundary) = self.computeBoundary(between: face.vertices, and: neighbor.vertices)!
//        print("boundary to be removed is", boundary)

        for (u,v) in boundary.adjacentPairs(wraparound: false) {
            self.vertexPayloads[u]!.neighbors.remove(v)
            self.vertexPayloads[v]!.neighbors.remove(u)
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

        self.ensureIntegrity()
    }

    private func categorizeRemovableFaces() -> (internal: [Face], external: [Face]) {
        guard self.faces.count >= 4 else { return ([], []) }

        var `internal`: [Face] = []
        var external: [Face] = []

        let (internalFaces, outerFace) = self.internalFacesAndOuterFace()

        for (face, payload) in self.facePayloads {
            let set = Set(payload.boundary)

            let n = internalFaces.count(where: { 1..<set.count ~= set.intersection($0.vertices).count })
            let m = outerFace.vertices.contains(where: set.contains(_:))

            switch (n, m) {
            case (2, true):
                external.append(face)
            case (3, false):
                `internal`.append(face)
            default:
                break // face cannot be removed
            }
        }

        return (internal: `internal`, external: external)
    }

    private func isBend(_ vertex: Vertex) -> Bool {
        return self.degree(of: vertex) == 2
    }

    private func isJoint(_ vertex: Vertex) -> Bool {
        return self.degree(of: vertex) == 3
    }

    private func computeBoundary(between left: [Vertex], and right: [Vertex]) -> (joined: [Vertex], shared: [Vertex])? {
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
