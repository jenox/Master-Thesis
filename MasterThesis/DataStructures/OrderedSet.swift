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
        self.storage = .init()
    }

    public init<Sequence>(_ sequence: Sequence) where Sequence: Swift.Sequence, Sequence.Element == Element {
        self.storage = .init()
        self.storage.addObjects(from: Array(sequence))
    }

    mutating func insert(_ element: Element) {
        self.ensureValueSemantics()
        self.storage.add(element)
    }

    mutating func insert(_ element: Element, at index: Index) {
        self.ensureValueSemantics()
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

    @discardableResult
    mutating func remove(_ element: Element) -> Bool {
        guard self.storage.contains(element) else { return false }

        self.ensureValueSemantics()
        self.storage.remove(element)
        return true
    }

    mutating func replace(_ oldElement: Element, with newElement: Element) {
        guard let index = self.firstIndex(of: oldElement) else { preconditionFailure() }

        self.ensureValueSemantics()
        self.storage.replaceObject(at: index, with: newElement)
    }

    func subtracting<T>(_ sequence: T) -> Self where T: Sequence, T.Element == Element {
        var copy = self
        for element in sequence {
            copy.remove(element)
        }
        return copy
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

extension OrderedSet: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "\(Array(self))"
    }

    public var debugDescription: String {
        return "OrderedSet(\(Array(self)))"
    }
}

extension OrderedSet: Codable where Element: Codable {
    public init(from decoder: Decoder) throws {
        self.storage = .init()

        var container = try decoder.unkeyedContainer()

        while !container.isAtEnd {
            self.insert(try container.decode(Element.self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()

        for element in self {
            try container.encode(element)
        }
    }
}
