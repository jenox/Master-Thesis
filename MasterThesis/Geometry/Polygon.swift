//
//  Polygon.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 29.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry

extension Polygon {
    // https://www.mathopenref.com/coordpolygonarea.html
    var area: CGFloat {
        return self.points.adjacentPairs(wraparound: true).reduce(0, { $0 + $1.0.x * $1.1.y - $1.0.y * $1.1.x }) / 2
    }

    var circumference: CGFloat {
        return self.points.adjacentPairs(wraparound: true).map({ $0.distance(to: $1) }).reduce(0, +)
    }

    func contains(_ point: CGPoint) -> Bool {
        let path = CGMutablePath()
        path.move(to: self.points[0])
        for point in self.points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()

        return path.contains(point)
    }

    func normalAndAngle(at index: Int) -> (normal: CGVector, angle: Angle) {
        let a = self.points[(index + self.points.count - 1) % self.points.count]
        let b = self.points[index]
        let c = self.points[(index + 1) % self.points.count]

        let vp = CGVector(from: b, to: a)
        let vq = CGVector(from: b, to: c)

        let outside = (Angle.atan2(vq.dy, vq.dx) - Angle.atan2(vp.dy, vp.dx)).counterclockwise
        return (vp.rotated(by: outside / 2).normalized, outside)
    }

    func internalAngle(at index: Int) -> Angle {
        return .init(degrees: 360) - self.normalAndAngle(at: index).angle
    }

    func removingPoint(at index: Int) -> Polygon {
        var points = self.points
        points.remove(at: index)

        return Polygon(points: points)
    }

    func movingPoint(at index: Int, to position: CGPoint, progress: CGFloat) -> Polygon {
        var points = self.points
        points[index] += progress * CGVector(from: points[index], to: position)

        return Polygon(points: points)
    }

    /// https://stackoverflow.com/questions/4001745/testing-whether-a-polygon-is-simple-or-complex
    /// http://geomalgorithms.com/a09-_intersect-3.html#simple_Polygon()
    var isSimple: Bool {
        guard self.points.count >= 3 else { return true }

        let segments = self.points.adjacentPairs(wraparound: true).map(Segment.init)

        for (i, j) in segments.indices.cartesianPairs() where (2..<segments.indices.last!).contains(abs(i - j)) {
            if segments[i].intersects(segments[j]) {
                return false
            }
        }

        return true
    }

    func isSimpleAndSameOrientation(as other: Polygon) -> Bool {
        return (self.isCounterclockwise == other.isCounterclockwise) && self.isSimple
    }

    var isCounterclockwise: Bool {
        return self.area >= 0
    }
}
