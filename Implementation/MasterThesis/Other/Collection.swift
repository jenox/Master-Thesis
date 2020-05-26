//
//  Collection.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 12.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

extension Collection {
    func min<T>(by closure: (Element) throws -> T) rethrows -> Element? where T: Comparable {
        return try self.map({ ($0, try closure($0)) }).min(by: { $0.1 < $1.1 })?.0
    }

    func max<T>(by closure: (Element) throws -> T) rethrows -> Element? where T: Comparable {
        return try self.map({ ($0, try closure($0)) }).max(by: { $0.1 < $1.1 })?.0
    }

    func firstIndexOfMinimum<T>(by transform: (Element) throws -> T) rethrows -> Index? where T: Comparable {
        return try self.indices.map({ ($0, try transform(self[$0])) }).min(by: { $0.1 < $1.1 })?.0
    }

    func firstIndexOfMaximum<T>(by transform: (Element) throws -> T) rethrows -> Index? where T: Comparable {
        return try self.indices.map({ ($0, try transform(self[$0])) }).max(by: { $0.1 < $1.1 })?.0
    }

    func count(where predicate: (Element) throws -> Bool) rethrows -> Int {
        return try self.reduce(0, { $0 + (try predicate($1) ? 1 : 0) })
    }
}

extension Collection where Element == Double {
    func mean() -> Double? {
        guard !self.isEmpty else { return nil }

        return self.reduce(0, +) / Double(self.count)
    }
}
