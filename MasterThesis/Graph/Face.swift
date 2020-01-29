//
//  Face.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 29.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

struct Face<T>: Hashable where T: Hashable {
    init(vertices: [T]) {
        precondition(vertices.count >= 3)
        precondition(vertices.count == Set(vertices).count)

        self.vertices = vertices
    }

    let vertices: [T]

    func containsEdge(between first: T, and second: T) -> Bool {
        guard let index = self.vertices.firstIndex(of: first) else { return false }

        let predecessor = index == 0 ? self.vertices.count - 1 : index - 1
        let successor = index + 1 == self.vertices.count ? 0 : index + 1

        return self.vertices[predecessor] == second || self.vertices[successor] == second
    }

    static func == (lhs: Face, rhs: Face) -> Bool {
        guard lhs.vertices.count == rhs.vertices.count else { return false }
        guard let index = lhs.vertices.firstIndex(of: rhs.vertices[0]) else { return false }

        return lhs.vertices.rotated(shiftingToStart: index) == rhs.vertices
    }

    func hash(into hasher: inout Hasher) {
        // Suboptimal implementation
        Set(self.vertices).hash(into: &hasher)
    }
}

private extension Array {
    func rotated(shiftingToStart index: Index) -> [Element] {
        guard index != 0 else { return self }

        return Array(self.dropFirst(index) + self.prefix(index))
    }
}
