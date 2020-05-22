//
//  Pipeline+Step.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 31.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics

extension PolygonalDual {
    mutating func willStepOnce() throws {
        let lengths = self.edges.map(self.distance(from:to:))
        let average = lengths.reduce(0, +) / CGFloat(lengths.count)

        for v in self.vertices.filter(self.isBend(_:)).sorted(by: self.distanceToClosestNeighbor(of:)) {
            guard self.distanceToClosestNeighbor(of: v) <= 0.1 * average else { break }

//            print("try to smooth \(v)")
            try? self.smooth(v)
        }

        for (u, v) in self.edges.sorted(by: self.distance(from:to:)) {
            guard self.distance(from: u, to: v) >= 2 * average else { continue }
            guard self.containsEdge(between: u, and: v) else { continue }

//            print("subdivide \(u)-\(v)")
            self.subdivideEdge(between: u, and: v)
        }
    }

    mutating func didStepOnce() throws {
    }

    private func distanceToClosestNeighbor(of v: Vertex) -> CGFloat {
        return self.vertices(adjacentTo: v).map({ self.distance(from: v, to: $0) }).min()!
    }
}

extension PolygonalDual {
    private func verify<T>(_ name: String, _ operations: Set<T>, using closure: (inout PolygonalDual, T) throws -> Void) -> Error? where T: Hashable {
        var firstError: Error?
        let before = CFAbsoluteTimeGetCurrent()
        var n = 0

        for operation in operations {
            do {
                var graph = self
                try closure(&graph, operation)
                n += 1
            } catch let error {
                firstError = firstError ?? error
            }
        }

        let duration = "\(String(format: "%.3f", 1e3 * (CFAbsoluteTimeGetCurrent() - before)))ms"
        print("- \(name):", (n == operations.count ? "✔︎" : "✖"), "(\(n)/\(operations.count)) (\(duration))")
        return firstError
    }

    func ensureAllValidOperationsPass() throws {
        print("Ensuring all possible operations pass...")

        let errors: [Error?] = [
            self.verify("Insert inside", self.possibleInsertFaceInsideOperations(name: "_", weight: 1), using: { try $0.insertFaceInside($1) }),
            self.verify("Insert outside", self.possibleInsertFaceOutsideOperations(name: "_", weight: 1), using: { try $0.insertFaceOutside($1) }),
            self.verify("Remove internal", self.possibleRemoveFaceWithoutBoundaryToExternalFaceOperations(), using: { try $0.removeFaceWithoutBoundaryToExternalFace($1) }),
            self.verify("Remove external", self.possibleRemoveFaceWithBoundaryToExternalFaceOperations(), using: { try $0.removeFaceWithBoundaryToExternalFace($1) }),
            self.verify("Flip edge", self.possibleFlipAdjacencyOperations(), using: { try $0.flipAdjacency($1) }),
            self.verify("Insert edge", self.possibleCreateAdjacencyOperations(), using: { try $0.createAdjacency($1) }),
            self.verify("Remove edge", self.possibleRemoveAdjacencyOperations(), using: { try $0.removeAdjacency($1) }),
        ]

        if let error = errors.compactMap({ $0 }).first {
            throw error
        }
    }
}

private extension Collection {
    func sorted<T>(by transform: (Element) throws -> T) rethrows -> [Element] where T: Comparable {
        return try self.map({ ($0, try transform($0)) }).sorted(by: { $0.1 < $1.1 }).map({ $0.0 })
    }
}
