//
//  PolygonComplexity.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 22.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry

public struct PolygonComplexity {
    public init() {
    }

    public func evaluate(in graph: PolygonalDual) throws -> [Double] {
        var complexities: [Double] = []

        for face in graph.faces {
            let polygon = graph.polygon(for: face)
            let hull = polygon.convexHull

            // Area of regular n-gon in circle
            let circle = Circle.smallestEnclosingCircle(of: polygon.points)
            let angle = Angle(turns: 0.5 / CGFloat(polygon.points.count))
            let maxarea = CGFloat(polygon.points.count) * circle.radius * cos(angle) * circle.radius * sin(angle)

            let angles = polygon.points.indices.map(polygon.internalAngle(at:))
            let notches = angles.count > 3 ? Double(angles.count(where: { $0 > .init(degrees: 180) })) / Double(polygon.points.count - 3) : 0
            let frequency = Double(1 + 16 * pow(notches - 0.5, 4) - 8 * pow(notches - 0.5, 2)).clamped(to: 0...1)
            let amplitude = Double((polygon.circumference - hull.circumference) / polygon.circumference).clamped(to: 0...1)
//            let convexity = Double((hull.area - polygon.area) / hull.area).clamped(to: 0...1) // theirs
            let convexity = Double((maxarea - polygon.area) / maxarea).clamped(to: 0...1) // ours

            precondition(0...1 ~= frequency)
            precondition(0...1 ~= amplitude)
            precondition(0...1 ~= convexity)
            let complexity = Double(0.8 * amplitude * frequency + 0.2 * convexity).clamped(to: 0...1)
            precondition(0...1 ~= complexity)
            complexities.append(complexity)
        }

        return complexities
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
