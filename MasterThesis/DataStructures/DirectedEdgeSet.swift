//
//  DirectedEdgeSet.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 03.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

public struct DirectedEdgeSet<T>: ExpressibleByArrayLiteral where T: Hashable {
    private var set: Set<Pair<T, T>> = []

    public init() {
    }

    public init(arrayLiteral elements: Element...) {
        for (u, v) in elements {
            self.insert((u, v))
        }
    }

    public func contains(_ tuple: Element) -> Bool {
        return self.set.contains(Pair(first: tuple.0, second: tuple.1))
    }

    public mutating func insert(_ tuple: Element) {
        if !self.set.insert(Pair(first: tuple.0, second: tuple.1)).inserted {
            fatalError()
        }
    }
}

extension DirectedEdgeSet: Collection {
    public typealias Element = (T, T)
    public typealias Iterator = IndexingIterator<DirectedEdgeSet>
    public typealias SubSequence = Slice<DirectedEdgeSet>
    public typealias Indices = DefaultIndices<DirectedEdgeSet>

    public struct Index: Comparable {
        fileprivate let index: Set<Pair<T, T>>.Index

        public static func < (lhs: Index, rhs: Index) -> Bool {
            return lhs.index < rhs.index
        }
    }

    public var startIndex: Index {
        return Index(index: self.set.startIndex)
    }

    public var endIndex: Index {
        return Index(index: self.set.endIndex)
    }

    public func index(after index: Index) -> Index {
        return Index(index: self.set.index(after: index.index))
    }

    public subscript(position: Index) -> Element {
        let pair = self.set[position.index]

        return (pair.first, pair.second)
    }
}

private struct Pair<T, U> {
    var first: T
    var second: U
}
extension Pair: Equatable where T: Equatable, U: Equatable {}
extension Pair: Hashable where T: Hashable, U: Hashable {}
