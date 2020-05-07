//
//  Pipeline+InsertVertex.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 03.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry

extension PolygonalDual {
    struct InsertFaceInsideOperation: Equatable, Hashable {
        init(name: ClusterName, weight: ClusterWeight, incidentTo u: ClusterName, _ v: ClusterName, _ w: ClusterName) {
            self.name = name
            self.weight = weight
            self.incidentFaces = [u, v, w]

            precondition(self.incidentFaces.count == 3)
        }

        let name: ClusterName
        let weight: ClusterWeight
        let incidentFaces: Set<ClusterName>
    }

    func possibleInsertFaceInsideOperations(name: ClusterName, weight: ClusterWeight) -> Set<InsertFaceInsideOperation> {
        var operations: Set<InsertFaceInsideOperation> = []

        for (u, v, w) in self.embeddedClusterGraph.insertionPositionsInside {
            operations.insert(.init(name: name, weight: weight, incidentTo: u, v, w))
        }

        return operations
    }

    mutating func insertFaceInside(_ operation: InsertFaceInsideOperation) throws {
        let (u, v, w) = operation.incidentFaces.destructured3()!

        var vertices = Set(self.boundary(of: u))
        vertices.formIntersection(self.boundary(of: v))
        vertices.formIntersection(self.boundary(of: w))

        guard vertices.count == 1 else { throw UnsupportedOperationError() }

        try self.insertFace(named: operation.name, weight: operation.weight, at: vertices.first!)
    }
}

extension PolygonalDual {
    struct InsertFaceOutsideOperation: Equatable, Hashable {
        init(name: ClusterName, weight: ClusterWeight, incidentTo u: ClusterName, _ v: ClusterName) {
            self.name = name
            self.weight = weight
            self.incidentFaces = [u, v]

            precondition(self.incidentFaces.count == 2)
        }

        let name: ClusterName
        let weight: ClusterWeight
        let incidentFaces: Set<ClusterName>
    }

    func possibleInsertFaceOutsideOperations(name: ClusterName, weight: ClusterWeight) -> Set<InsertFaceOutsideOperation> {
        var operations: Set<InsertFaceOutsideOperation> = []

        for (u, v) in self.embeddedClusterGraph.insertionPositionsOutside {
            operations.insert(.init(name: name, weight: weight, incidentTo: u, v))
        }

        return operations
    }

    mutating func insertFaceOutside(_ operation: InsertFaceOutsideOperation) throws {
        let (u, v) = operation.incidentFaces.destructured2()!

        var vertices = Set(self.boundary(of: u))
        vertices.formIntersection(self.boundary(of: v))
        vertices.formIntersection(self.internalFacesAndOuterFace().outer.vertices)

        guard vertices.count == 1 else { throw UnsupportedOperationError() }

        try self.insertFace(named: operation.name,  weight: operation.weight, at: vertices.first!)
    }
}

private extension PolygonalDual {
    mutating func insertFace(named name: ClusterName, weight: ClusterWeight, at vertex: Vertex) throws {
        var faces = Array(self.faces(incidentTo: vertex))
        assert(faces.allSatisfy({ $0.vertices.first == vertex }))

        guard faces.count == 3 else { throw UnsupportedOperationError() }

        var neighbors = faces.map({ $0.vertices[1] })

        // Ensure the closest vertices are subdivision vertices
        for (index, neighbor) in neighbors.enumerated() where self.degree(of: neighbor) == 3 {
            neighbors[index] = self.subdivideEdge(between: vertex, and: neighbor)
            faces[index] = faces[index].inserting(neighbors[index], at: 1)
        }

        // Compute boundary of new face
        var boundary: [Vertex] = []
        for (face, (x, y)) in zip(faces, neighbors.adjacentPairs(wraparound: true)) {
            boundary.append(x)

            let polygon = self.polygon(on: face.vertices)

            if polygon.internalAngle(at: 0).turns > 0.5 {
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

        // Update data structure
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
}

private extension EmbeddedClusterGraph {
    /// We can insert into all (triangular) internal faces.
    var insertionPositionsInside: [(Vertex, Vertex, Vertex)] {
        var insertionPositionsInside: [(Vertex, Vertex, Vertex)] = []

        for face in self.internalFaces {
            let (u, v, w) = face.vertices.destructured3()!

            insertionPositionsInside.append((u, v, w))
            insertionPositionsInside.append((u, w, v))
            insertionPositionsInside.append((v, u, w))
            insertionPositionsInside.append((v, w, u))
            insertionPositionsInside.append((w, u, v))
            insertionPositionsInside.append((w, v, u))
        }

        return insertionPositionsInside
    }

    /// We can insert at all edges on the outer face.
    var insertionPositionsOutside: [(Vertex, Vertex)] {
        var insertionPositionsOutside: [(Vertex, Vertex)] = []

        for (u, v) in self.externalEdges {
            insertionPositionsOutside.append((u, v))
            insertionPositionsOutside.append((v, u))
        }

        return insertionPositionsOutside
    }
}
