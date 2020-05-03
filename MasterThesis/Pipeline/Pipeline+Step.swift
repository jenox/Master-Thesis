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
        for v in self.vertices.filter(self.isSubdivisionVertex(_:)).sorted(by: self.distanceToClosestNeighbor(of:)) {
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

private extension Collection {
    func sorted<T>(by transform: (Element) throws -> T) rethrows -> [Element] where T: Comparable {
        return try self.map({ ($0, try transform($0)) }).sorted(by: { $0.1 < $1.1 }).map({ $0.0 })
    }
}
