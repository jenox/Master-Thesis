//
//  Pipeline+InsertVertex.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 03.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift
import CoreGraphics
import Geometry

extension PolygonalDual {
    mutating func insertFaceInsideRandomly<T>(
        named name: ClusterName,
        weight: ClusterWeight,
        using generator: inout T
    ) throws where T: RandomNumberGenerator {
        guard let vertex = self.possibleInsertionPoints().inside.randomElement(using: &generator) else { throw UnsupportedOperationError() }

        try! self.insertFace(named: name, at: vertex, weight: weight)
    }

    mutating func insertFaceOutsideRandomly<T>(
        named name: ClusterName,
        weight: ClusterWeight,
        using generator: inout T
    ) throws where T: RandomNumberGenerator {
        guard let vertex = self.possibleInsertionPoints().outside.randomElement(using: &generator) else { throw UnsupportedOperationError() }

        try! self.insertFace(named: name, at: vertex, weight: weight)
    }

    mutating func insertFace(named name: ClusterName, at vertex: Vertex, weight: ClusterWeight) throws {
        var faces = Array(self.faces(incidentTo: vertex))
        guard faces.count == 3 else { throw UnsupportedOperationError() }
        guard faces.allSatisfy({ $0.vertices.first == vertex }) else { throw UnsupportedOperationError() }
        var neighbors = faces.map({ $0.vertices[1] })

        // Ensure the closest vertices are subdivision vertices
        for (index, neighbor) in neighbors.enumerated() where self.degree(of: neighbor) == 3 {
            neighbors[index] = self.subdivideEdge(between: vertex, and: neighbor)
            faces[index] = faces[index].inserting(neighbors[index], at: 1)
        }

        var boundary: [Vertex] = []

        for (face, (x, y)) in zip(faces, neighbors.adjacentPairs(wraparound: true)) {
            boundary.append(x)

            let polygon = self.polygon(on: face.vertices)
            let angle = .degrees(360) - polygon.normalAndAngle(at: 0).angle

            if angle > .degrees(180) {
                boundary.append(self.insertVertex(at: self.position(of: vertex)))
            } else if polygon.removingPoint(at: 0).isSimple {
                // no-op
            } else {
                let midpoint = self.segment(from: x, to: y).midpoint
                let progresses = sequence(first: 0.5 as CGFloat, next: { $0 / 2 })
                let progress = progresses.first(where: { polygon.movingPoint(at: 0, to: midpoint, progress: $0).isSimple })!
                let position = polygon.movingPoint(at: 0, to: midpoint, progress: progress).points[0]

                boundary.append(self.insertVertex(at: position))
            }
        }

        self.vertices.remove(vertex)
        self.vertexPayloads[vertex] = nil
        for neighbor in neighbors {
            self.vertexPayloads[neighbor]!.neighbors.remove(vertex)
        }
        for (u,v) in boundary.adjacentPairs(wraparound: true) {
            self.insertEdge(between: u, and: v)
        }
        let newface = Face(vertices: boundary)
        for (face, payload) in self.facePayloads {
            if let index = payload.boundary.firstIndex(of: vertex) {
                let (before, after) = Face(vertices: payload.boundary).neighbors(of: vertex)
                if let subdivision = newface.vertices.first(where: { newface.neighbors(of: $0) == (after, before) }) {
                    self.facePayloads[face]!.boundary[index] = subdivision
                } else {
                    self.facePayloads[face]!.boundary.remove(at: index)
                }
            }
        }

        self.defineFace(named: name, boundedBy: boundary, weight: weight)
        self.ensureIntegrity()
    }

    private func possibleInsertionPoints() -> (inside: [Vertex], outside: [Vertex]) {
        var inside: [Vertex] = []
        var outside: [Vertex] = []

        for vertex in self.vertices.filter({ self.degree(of: $0) == 3 }) {
            let faces = self.faces(incidentTo: vertex)
            assert(faces.count == 3)

            if faces.contains(where: { self.polygon(on: $0.vertices).area < 0 }) {
                outside.append(vertex)
            } else {
                inside.append(vertex)
            }
        }

        return (inside: inside, outside: outside)
    }
}

extension PolygonalDual {
    var insertionPositionsInside: [(FaceID, FaceID, FaceID)] {
        let vertices = self.possibleInsertionPoints().inside
        let faces = vertices.map({ self.faces(incidentTo: $0).compactMap(self.faceID(of:)).destructured3()! })

        return faces
    }

    var insertionPositionsOutside: [(FaceID, FaceID)] {
        let vertices = self.possibleInsertionPoints().outside
        let faces = vertices.map({ self.faces(incidentTo: $0).compactMap(self.faceID(of:)).destructured2()! })

        return faces
    }
}
