//
//  QualityEvaluator.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 23.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

protocol QualityEvaluator {
    func quality(of face: FaceWeightedGraph.Face, in graph: FaceWeightedGraph) throws -> QualityValue
}

enum QualityValue {
    case integer(Int)
    case double(Double)
    case percentage(Double)
}