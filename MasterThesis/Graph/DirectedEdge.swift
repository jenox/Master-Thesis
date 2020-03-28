//
//  DirectedEdge.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 12.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

struct DirectedEdge: Hashable, CustomStringConvertible {
    init(from source: String, to target: String) {
        self.source = source
        self.target = target
    }

    var source: String
    var target: String

    func inverted() -> DirectedEdge {
        return DirectedEdge(from: self.target, to: self.source)
    }

    var description: String {
        return "\(self.source) -> \(self.target)"
    }
}
