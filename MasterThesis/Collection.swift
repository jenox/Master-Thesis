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

    func count(where predicate: (Element) throws -> Bool) rethrows -> Int {
        return try self.reduce(0, { $0 + (try predicate($1) ? 1 : 0) })
    }

    func makeAdjacentPairIterator() -> AnyIterator<(Element, Element)> {
        var index = self.startIndex

        return AnyIterator({
            guard index != self.endIndex else { return nil }

            let nextIndex = self.index(after: index)
            defer { index = nextIndex }

            if nextIndex != self.endIndex {
                return (self[index], self[nextIndex])
            } else if index == self.startIndex {
                return nil
            } else {
                return (self[index], self[self.startIndex])
            }
        })
    }
}
