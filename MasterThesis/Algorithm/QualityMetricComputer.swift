//
//  QualityMetricComputer.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 11.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics

class QualityMetricComputer {
    func qualityMetrics(in graph: FaceWeightedGraph) -> [(String, Metrics)] {
        var qualityMetrics: [(String, Metrics)] = []

        let totalweight = graph.faces.map(graph.weight(of:)).reduce(0, +)
        let totalarea = graph.faces.map(graph.area(of:)).reduce(0, +)

        for face in graph.faces {
            let name = graph.name(of: face)
            let weight = graph.weight(of: face)
            let area = graph.area(of: face)
            let normalizedArea = (area / totalarea) * totalweight
            let polygon = Polygon(points: face.vertices.map(graph.position(of:)))

            let statisticalAccuracy = Self.statisticalAccuracy(normalizedArea: normalizedArea, weight: weight)
            let localFatness = Self.localFatness(of: polygon)

            qualityMetrics.append(("\(name)", Metrics(
                weight: weight,
                normalizedArea: normalizedArea,
                statisticalAccuracy: statisticalAccuracy,
                localFatness: localFatness
            )))
        }

        return qualityMetrics
    }

    private class func statisticalAccuracy(normalizedArea: Double, weight: Double) -> Double {
        let pressure = weight / normalizedArea

        return min(pressure, 1 / pressure)
    }

    // https://mathematica.stackexchange.com/questions/121987/
    private class func localFatness(of polygon: Polygon) -> Double {
        let circle = Circle.smallestEnclosingCircle(of: polygon.points)

        // Area of regular n-gon in circle
        let angle = Angle(turns: 0.5 / CGFloat(polygon.points.count))
        let maxarea = CGFloat(polygon.points.count) * circle.radius * cos(angle) * circle.radius * sin(angle)

        let fatness = polygon.area / maxarea

        return Double(fatness)
    }
}

struct Metrics {
    var weight: Double
    var normalizedArea: Double
    var statisticalAccuracy: Double
    var localFatness: Double
}
