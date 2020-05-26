//
//  OrderedSet.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 12.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Foundation

//public typealias OrderedSet = _NSOrderedSet
public typealias OrderedSet = _NaiveOrderedSet

public protocol _OrderedSetProtocol: RandomAccessCollection, ExpressibleByArrayLiteral, CustomStringConvertible, CustomDebugStringConvertible where Element: Hashable {
    init()
    init<Sequence>(_ sequence: Sequence) where Sequence: Swift.Sequence, Sequence.Element == Element
    mutating func insert(_ element: Element)
    mutating func insert(_ element: Element, at index: Index)
    func contains(_ element: Element) -> Bool
    mutating func popLast() -> Element?
    @discardableResult mutating func remove(_ element: Element) -> Bool
    mutating func replace(_ oldElement: Element, with newElement: Element)
    func subtracting<T>(_ sequence: T) -> Self where T: Sequence, T.Element == Element
}

public struct _NaiveOrderedSet<Element>: _OrderedSetProtocol where Element: Hashable {
    private var elements: [Element] = []

    public init() { self.elements = [] }
    public init<Sequence>(_ sequence: Sequence) where Sequence: Swift.Sequence, Self.Element == Sequence.Element {
        for element in sequence { self.insert(element) }
    }
    public mutating func insert(_ element: Element) { if !self.contains(element) { self.elements.append(element) } }
    public mutating func insert(_ element: Element, at index: Index) { if !self.contains(element) { self.elements.insert(element, at: index) } }
    public func contains(_ element: Element) -> Bool { return self.elements.contains(element) }
    public mutating func popLast() -> Element? { return self.elements.popLast() }
    @discardableResult public mutating func remove(_ element: Element) -> Bool {
        if let index = self.elements.firstIndex(of: element) {
            self.elements.remove(at: index)
            return true
        } else {
            return false
        }
    }
    public mutating func replace(_ oldElement: Element, with newElement: Element) {
        precondition(!self.contains(newElement))
        let index = self.elements.firstIndex(of: oldElement)!
        self.elements[index] = newElement
    }
    public func subtracting<T>(_ sequence: T) -> Self where T: Sequence, T.Element == Element {
        var elements = self.elements
        elements.removeAll(where: sequence.contains(_:))

        return .init(elements)
    }

    public var startIndex: Int { return 0 }
    public var endIndex: Int { return self.elements.count }
    public func index(after index: Int) -> Int { return index + 1 }
    public func index(before index: Int) -> Int { return index - 1 }
    public func index(_ index: Int, offsetBy distance: Int) -> Int { return index + distance }
    public func distance(from start: Int, to end: Int) -> Int { return end - start }
    public subscript(position: Int) -> Element { return self.elements[position] }

    public init(arrayLiteral elements: Element...) { for element in elements { self.insert(element) } }
    public var description: String { return "\(Array(self))" }
    public var debugDescription: String { return "OrderedSet(\(Array(self)))" }
}


// MARK: - NSOrderedSet

public struct _NSOrderedSet<Element> where Element: Hashable {
    private var storage: NSMutableOrderedSet

    public init() {
        self.storage = .init()
    }

    public init<Sequence>(_ sequence: Sequence) where Sequence: Swift.Sequence, Sequence.Element == Element {
        self.storage = .init()
        self.storage.addObjects(from: Array(sequence))
    }

    public mutating func insert(_ element: Element) {
        self.ensureValueSemantics()
        self.storage.add(element)
    }

    public mutating func insert(_ element: Element, at index: Index) {
        self.ensureValueSemantics()
        self.storage.insert(element, at: index)
    }

    public func contains(_ element: Element) -> Bool {
        return self.storage.contains(element)
    }

    public mutating func popLast() -> Element? {
        guard let index = self.indices.last else { return nil }

        self.ensureValueSemantics()

        let element = self.storage[index] as! Element
        self.storage.removeObject(at: index)
        return element
    }

    @discardableResult
    public mutating func remove(_ element: Element) -> Bool {
        guard self.storage.contains(element) else { return false }

        self.ensureValueSemantics()
        self.storage.remove(element)
        return true
    }

    public mutating func replace(_ oldElement: Element, with newElement: Element) {
        guard let index = self.firstIndex(of: oldElement) else { preconditionFailure() }

        self.ensureValueSemantics()
        self.storage.replaceObject(at: index, with: newElement)
    }

    public func subtracting<T>(_ sequence: T) -> Self where T: Sequence, T.Element == Element {
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

extension _NSOrderedSet: RandomAccessCollection {
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

extension _NSOrderedSet: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        self.storage = NSMutableOrderedSet()
        self.storage.addObjects(from: elements)
    }
}

extension _NSOrderedSet: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "\(Array(self))"
    }

    public var debugDescription: String {
        return "OrderedSet(\(Array(self)))"
    }
}

extension _NSOrderedSet: _OrderedSetProtocol {}


// MARK: - Codable

extension OrderedSet: Codable where Element: Codable {
    public init(from decoder: Decoder) throws {
        self.init()

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
