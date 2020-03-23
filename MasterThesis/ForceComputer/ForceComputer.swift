//
//  ForceComputer.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 23.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics

protocol ForceComputer {
    func forces(in graph: FaceWeightedGraph) throws -> [FaceWeightedGraph.Vertex: CGVector]
}
