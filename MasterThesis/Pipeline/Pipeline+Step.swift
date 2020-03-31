//
//  Pipeline+Step.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 31.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics

extension FaceWeightedGraph {
    mutating func willStepOnce() throws {
        for (u, v) in self.edges {
            guard self.contains(u) && self.contains(v) else { continue } // may have been removed in previous contract operation
            guard self.distance(from: u, to: v) < 2 else { continue } // must be close enough

            self.contractEdgeIfPossible(between: u, and: v)
        }
    }

    mutating func didStepOnce() throws {
    }
}
