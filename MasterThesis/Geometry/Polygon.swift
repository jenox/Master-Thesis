//
//  Polygon.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 11.02.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry

extension Polygon {

    // https://www.mathopenref.com/coordpolygonarea.html
    var area: CGFloat {
        return self.points.adjacentPairs(wraparound: true).reduce(0, { $0 + $1.0.x * $1.1.y - $1.0.y * $1.1.x }) / 2
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

    func normal(at index: Int) -> CGVector {
        return normalAndAngle(at: index).normal
    }
}
