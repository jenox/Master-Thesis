//
//  StatisticalAccuracy.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 24.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

struct StatisticalAccuracy: QualityEvaluator {
    func quality(of face: FaceWeightedGraph.Face, in graph: FaceWeightedGraph) -> QualityValue {
        let totalweight = graph.faces.map(graph.weight(of:)).reduce(0, +).rawValue
        let totalarea = graph.faces.map(graph.area(of:)).reduce(0, +)
        let weight = graph.weight(of: face).rawValue
        let area = graph.area(of: face)
        let normalizedArea = (area / totalarea) * totalweight
        let pressure = weight / normalizedArea

        return .percentage(min(pressure, 1 / pressure))
    }
}
