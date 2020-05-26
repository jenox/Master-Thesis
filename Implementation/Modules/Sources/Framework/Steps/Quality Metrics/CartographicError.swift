//
//  CartographicError.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 22.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

public struct CartographicError {
    public init() {
    }

    public func evaluate(in graph: PolygonalDual) throws -> [Double] {
        let totalweight = graph.faces.map(graph.weight(of:)).reduce(0, +).rawValue
        let totalarea = graph.faces.map(graph.area(of:)).reduce(0, +)

        var errors: [Double] = []

        for face in graph.faces {
            let weight = graph.weight(of: face).rawValue
            let area = graph.area(of: face)
            let normalizedArea = (area / totalarea) * totalweight

            let error = abs(normalizedArea - weight) / max(normalizedArea, weight)
            errors.append(error)
        }

        return errors
    }
}
