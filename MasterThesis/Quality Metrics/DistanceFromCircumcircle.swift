//
//  DistanceFromCircumcircle.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 24.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry

struct DistanceFromCircumcircle: QualityEvaluator {
    func quality(of face: FaceWeightedGraph.Face, in graph: FaceWeightedGraph) throws -> QualityValue {
        let polygon = graph.polygon(for: face)
        let circle = Circle.smallestEnclosingCircle(of: polygon.points)

        // Area of regular n-gon in circle
        let angle = Angle(turns: 0.5 / CGFloat(polygon.points.count))
        let maxarea = CGFloat(polygon.points.count) * circle.radius * cos(angle) * circle.radius * sin(angle)

        let fatness = polygon.area / maxarea

        return .percentage(Double(fatness))
    }
}
