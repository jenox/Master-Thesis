//
//  Transformer.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 23.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

public protocol Transformer {
    func transform(_ graph: VertexWeightedGraph) throws -> PolygonalDual
}
