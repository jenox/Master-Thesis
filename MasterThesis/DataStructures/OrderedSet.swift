//
//  OrderedSet.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 12.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Foundation

struct OrderedSet<Element>: Collection, ExpressibleByArrayLiteral {
    private var storage = NSMutableOrderedSet()

    init() {}

    init(arrayLiteral elements: Element...) {
        self.storage.addObjects(from: elements)
    }

    init<Sequence>(_ sequence: Sequence) where Sequence: Swift.Sequence, Sequence.Element == Element {
        self.storage.addObjects(from: Array(sequence))
    }

    var startIndex: Int { return 0 }
    var endIndex: Int { return self.storage.count }
    func index(after index: Int) -> Int { return index + 1 }
    subscript(position: Int) -> Element { return self.storage[position] as! Element }

    mutating func insert(_ element: Element) {
        self.ensureValueSemantics()

        self.storage.add(element)
    }

    mutating func popFirst() -> Element? {
        self.ensureValueSemantics()

        guard !self.isEmpty else { return nil }

        let element = self.storage[0] as! Element
        self.storage.removeObject(at: 0)
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
