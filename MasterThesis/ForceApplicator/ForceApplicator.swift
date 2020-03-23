//
//  ForceApplicator.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 23.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics

protocol ForceApplicator {
    func apply(_ forces: [FaceWeightedGraph.Vertex: CGVector], to graph: inout FaceWeightedGraph) throws
}
