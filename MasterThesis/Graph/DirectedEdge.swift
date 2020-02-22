//
//  DirectedEdge.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 12.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

struct DirectedEdge: Hashable, CustomStringConvertible {
    init(from source: Character, to target: Character) {
        self.source = source
        self.target = target
    }

    var source: Character
    var target: Character

    func inverted() -> DirectedEdge {
        return DirectedEdge(from: self.target, to: self.source)
    }

    var description: String {
        return "\(self.source) -> \(self.target)"
    }
}
