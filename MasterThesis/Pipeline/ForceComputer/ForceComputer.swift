//
//  ForceComputer.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 23.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics

protocol ForceComputer {
    func forces(in graph: VertexWeightedGraph) throws -> [VertexWeightedGraph.Vertex: CGVector]
    func forces(in graph: PolygonalDual) throws -> [PolygonalDual.Vertex: CGVector]
}
