//
//  Face.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 29.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

public struct Face<T>: Hashable where T: Hashable {
    init(vertices: [T]) {
        precondition(vertices.count >= 3)
        precondition(vertices.count == Set(vertices).count)

        self.vertices = vertices
    }

    public let vertices: [T]

    func neighbors(of vertex: T) -> (before: T, after: T) {
        let index = self.vertices.firstIndex(of: vertex)!

        return (
            self.vertices[(index + self.vertices.count - 1) % self.vertices.count],
            self.vertices[(index + 1) % self.vertices.count]
        )
    }

    func indexOfEdge(between first: T, and second: T) -> Int? {
        guard let index = self.vertices.firstIndex(of: first) else { return nil }

        let predecessor = index == 0 ? self.vertices.count - 1 : index - 1
        let successor = index + 1 == self.vertices.count ? 0 : index + 1

        if self.vertices[successor] == second {
            return index
        }
        else if self.vertices[predecessor] == second {
            return predecessor
        } else {
            return nil
        }
    }

    func predecessor(of vertex: T) -> T? {
        guard let index = self.vertices.firstIndex(of: vertex) else { return nil }
        return self.vertices[index == 0 ? self.vertices.count - 1 : index - 1]
    }

    func successor(of vertex: T) -> T? {
        guard let index = self.vertices.firstIndex(of: vertex) else { return nil }
        return self.vertices[index + 1 == self.vertices.count ? 0 : index + 1]
    }

    func containsEdge(from u: T, to v: T) -> Bool {
        guard let index = self.vertices.firstIndex(of: u) else { return false }

        let successor = index + 1 == self.vertices.count ? 0 : index + 1

        return self.vertices[successor] == v
    }

    func containsEdge(between first: T, and second: T) -> Bool {
        guard let index = self.vertices.firstIndex(of: first) else { return false }

        let predecessor = index == 0 ? self.vertices.count - 1 : index - 1
        let successor = index + 1 == self.vertices.count ? 0 : index + 1

        return self.vertices[predecessor] == second || self.vertices[successor] == second
    }

    public static func == (lhs: Face, rhs: Face) -> Bool {
        guard lhs.vertices.count == rhs.vertices.count else { return false }
        guard let index = lhs.vertices.firstIndex(of: rhs.vertices[0]) else { return false }

        return lhs.vertices.rotated(shiftingToStart: index) == rhs.vertices
    }

    public func hash(into hasher: inout Hasher) {
        // Suboptimal implementation
        Set(self.vertices).hash(into: &hasher)
    }

    func smoothing(vertex: T) -> Face<T> {
        guard let index = self.vertices.firstIndex(of: vertex) else { preconditionFailure() }

        var vertices = self.vertices
        vertices.remove(at: index)

        return Face(vertices: vertices)
    }

    func inserting(_ vertex: T, at index: Int) -> Face<T> {
        var vertices = self.vertices
        vertices.insert(vertex, at: index)

        return Face(vertices: vertices)
    }

    func filter(_ predicate: (T) -> Bool) -> Face {
        return .init(vertices: self.vertices.filter(predicate))
    }
}

extension Face: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "Face(\(Array(self.vertices)))"
    }

    public var debugDescription: String {
        return "Face(\(Array(self.vertices)))"
    }
}

private extension Array {
    func rotated(shiftingToStart index: Index) -> [Element] {
        guard index != 0 else { return self }

        return Array(self.dropFirst(index) + self.prefix(index))
    }
}
