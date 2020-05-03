//
//  OrderedSet.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 12.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Foundation

public struct OrderedSet<Element> where Element: Hashable {
    private var storage: NSMutableOrderedSet

    public init() {
        self.storage = NSMutableOrderedSet()
    }

    public init<Sequence>(_ sequence: Sequence) where Sequence: Swift.Sequence, Sequence.Element == Element {
        self.storage = NSMutableOrderedSet()
        self.storage.addObjects(from: Array(sequence))
    }

    mutating func insert(_ element: Element) {
        self.ensureValueSemantics()

        self.storage.add(element)
    }

    mutating func insert(_ element: Element, at index: Index) {
        self.storage.insert(element, at: index)
    }

    func contains(_ element: Element) -> Bool {
        return self.storage.contains(element)
    }

    mutating func popLast() -> Element? {
        guard let index = self.indices.last else { return nil }

        self.ensureValueSemantics()

        let element = self.storage[index] as! Element
        self.storage.removeObject(at: index)
        return element
    }

    mutating func remove(_ element: Element) {
        self.ensureValueSemantics()

        self.storage.remove(element)
    }

    private mutating func ensureValueSemantics() {
        if !isKnownUniquelyReferenced(&self.storage) {
            self.storage = NSMutableOrderedSet(orderedSet: self.storage)
        }
    }
}

extension OrderedSet: RandomAccessCollection {
    public var startIndex: Int {
        return 0
    }

    public var endIndex: Int {
        return self.storage.count
    }

    public func index(after index: Int) -> Int {
        return index + 1
    }

    public func index(before index: Int) -> Int {
        return index - 1
    }

    public func index(_ index: Int, offsetBy distance: Int) -> Int {
        return index + distance
    }

    public func distance(from start: Int, to end: Int) -> Int {
        return end - start
    }

    public subscript(position: Int) -> Element {
        return self.storage[position] as! Element
    }

    public func firstIndex(of element: Element) -> Int? {
        let index = self.storage.index(of: element)

        return index != NSNotFound ? index : nil
    }

    public func lastIndex(of element: Element) -> Int? {
        return self.firstIndex(of: element)
    }
}

extension OrderedSet: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        self.storage = NSMutableOrderedSet()
        self.storage.addObjects(from: elements)
    }
}
