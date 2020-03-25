//
//  DistanceFromConvexHull.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 24.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics

struct DistanceFromConvexHull: QualityEvaluator {
    func quality(of face: FaceWeightedGraph.Face, in graph: FaceWeightedGraph) throws -> QualityValue {
        let polygon = graph.polygon(for: face)
        let hull = Polygon(points: calculateConvexHull(fromPoints: polygon.points))

        return .percentage(Double(polygon.area / hull.area))
    }
}

// https://rosettacode.org/wiki/Convex_hull#Swift
private func calculateConvexHull(fromPoints points: [CGPoint]) -> [CGPoint] {
    guard points.count >= 3 else {
        return points
    }

    var hull = [CGPoint]()
    let (leftPointIdx, _) = points.enumerated().min(by: { $0.element.x < $1.element.x })!

    var p = leftPointIdx
    var q = 0

    repeat {
        hull.append(points[p])

        q = (p + 1) % points.count

        for i in 0..<points.count where calculateOrientation(points[p], points[i], points[q]) == .counterClockwise {
            q = i
        }

        p = q
    } while p != leftPointIdx

    return hull
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
