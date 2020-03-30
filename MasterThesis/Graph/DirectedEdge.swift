//
//  DirectedEdge.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 12.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

struct DirectedEdge: Hashable, CustomStringConvertible {
    init(from source: ClusterName, to target: ClusterName) {
        self.source = source
        self.target = target
    }

    var source: ClusterName
    var target: ClusterName

    func inverted() -> DirectedEdge {
        return DirectedEdge(from: self.target, to: self.source)
    }

    var description: String {
        return "\(self.source.rawValue) -> \(self.target.rawValue)"
    }
}
