//
//  ForceApplicator.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 23.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics

public protocol ForceApplicator {
    func forces(in graph: VertexWeightedGraph) throws -> [VertexWeightedGraph.Vertex: CGVector]
    func applyForces(to graph: inout VertexWeightedGraph) throws

    func forces(in graph: PolygonalDual) throws -> [PolygonalDual.Vertex: CGVector]
    func applyForces(to graph: inout PolygonalDual) throws
}
