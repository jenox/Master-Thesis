//
//  GraphGenerator.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 22.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

public protocol GraphGenerator {
    func generateRandomWeight<T>(using generator: inout T) -> ClusterWeight where T: RandomNumberGenerator
    func generateRandomGraph<T>(using generator: inout T) throws -> VertexWeightedGraph where T: RandomNumberGenerator
}
