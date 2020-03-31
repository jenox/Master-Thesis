//
//  ForceApplicator.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 23.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics

protocol ForceApplicator {
    func apply<Graph>(_ forces: [Graph.Vertex: CGVector], to graph: inout Graph) throws where Graph: StraightLineGraph
}
