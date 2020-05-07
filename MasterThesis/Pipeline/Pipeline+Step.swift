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
        for v in self.vertices.filter(self.isBend(_:)).sorted(by: self.distanceToClosestNeighbor(of:)) {
            guard self.distanceToClosestNeighbor(of: v) < 5 else { break }

            try? self.smooth(v)
        }
    }

    mutating func didStepOnce() throws {
    }

    private func distanceToClosestNeighbor(of v: Vertex) -> CGFloat {
        return self.vertices(adjacentTo: v).map({ self.distance(from: v, to: $0) }).min()!
    }
}

extension PolygonalDual {
    func ensureAllValidOperationsPass() throws {
        print("Ensuring all possible operations pass...", terminator: " ")
        var firstError: Error?
        let before = CFAbsoluteTimeGetCurrent()

        do {
            for operation in self.possibleInsertFaceInsideOperations(name: "_", weight: 1) {
                var graph = self
                try graph.insertFaceInside(operation)
            }
            print("✔︎", terminator: "")
        } catch let error {
            firstError = error
            print("✖", terminator: "")
        }

        do {
            for operation in self.possibleInsertFaceOutsideOperations(name: "_", weight: 1) {
                var graph = self
                try graph.insertFaceOutside(operation)
            }
            print("✔︎", terminator: "")
        } catch let error {
            firstError = error
            print("✖", terminator: "")
        }

        do {
            for operation in self.possibleRemoveFaceWithoutBoundaryToExternalFaceOperations() {
                var graph = self
                try graph.removeFaceWithoutBoundaryToExternalFace(operation)
            }
            print("✔︎", terminator: "")
        } catch let error {
            firstError = error
            print("✖", terminator: "")
        }

        do {
            for operation in self.possibleRemoveFaceWithBoundaryToExternalFaceOperations() {
                var graph = self
                try graph.removeFaceWithBoundaryToExternalFace(operation)
            }
            print("✔︎", terminator: "")
        } catch let error {
            firstError = error
            print("✖", terminator: "")
        }

        if let error = firstError {
            throw error
        }

        let duration = "\(String(format: "%.3f", 1e3 * (CFAbsoluteTimeGetCurrent() - before)))ms"
        print(" \(duration)")
    }
}

private extension Collection {
    func sorted<T>(by transform: (Element) throws -> T) rethrows -> [Element] where T: Comparable {
        return try self.map({ ($0, try transform($0)) }).sorted(by: { $0.1 < $1.1 }).map({ $0.0 })
    }
}
