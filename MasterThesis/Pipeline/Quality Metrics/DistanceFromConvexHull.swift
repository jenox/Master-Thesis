//
//  DistanceFromConvexHull.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 24.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Collections
import Geometry

struct DistanceFromConvexHull: QualityEvaluator {
    func quality(of face: PolygonalDual.FaceID, in graph: PolygonalDual) throws -> QualityValue {
        let polygon = graph.polygon(for: face)
        let hull = Polygon(points: calculateConvexHull(fromPoints: polygon.points))

        return .percentage(Double(polygon.area / hull.area))
    }
}

// Graham's scan
private func calculateConvexHull(fromPoints points: [CGPoint]) -> [CGPoint] {
    guard points.count >= 3 else { return points }

    precondition(Polygon(points: points).area >= 0)

    let index = points.firstIndexOfMinimum(by: \.x)!
    var stack: [CGPoint] = []

    for p in points.rotated(shiftingToStart: index) {
        while stack.count >= 2, calculateOrientation(stack[stack.count - 2], stack[stack.count - 1], p) == .clockwise {
            stack.removeLast()
        }

        stack.append(p)
    }

    return stack
}

private func calculateOrientation(_ p: CGPoint, _ q: CGPoint, _ r: CGPoint) -> Orientation {
    let val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)

    if val == 0 {
        return .straight
    } else if val > 0 {
        return .clockwise
    } else {
        return .counterClockwise
    }
}

private enum Orientation {
    case straight, clockwise, counterClockwise
}
