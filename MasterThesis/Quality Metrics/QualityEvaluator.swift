//
//  QualityEvaluator.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 23.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

protocol QualityEvaluator {
    func qualityMetrics(of graph: FaceWeightedGraph) -> [String: QualityValue]
}

enum QualityValue {
    case integer(Int)
    case percentage(Double)
}
