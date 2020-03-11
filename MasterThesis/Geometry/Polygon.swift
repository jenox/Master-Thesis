//
//  Polygon.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 11.02.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics


struct Polygon: Equatable {
    init(points: [CGPoint]) {
        precondition(points.count >= 3)

        self.points = points
    }

    let points: [CGPoint]

    // https://www.mathopenref.com/coordpolygonarea.html
    var area: CGFloat {
        return self.points.makeAdjacentPairIterator().reduce(0, { $0 + $1.0.x * $1.1.y - $1.0.y * $1.1.x }) / 2
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
}

extension Polygon {
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

extension CGVector {
    func applying(_ transform: CGAffineTransform) -> CGVector {
        return CGVector(dx: self.dx * transform.a + self.dy * transform.c, dy: self.dx * transform.b + self.dy * transform.d)
    }

    func rotated(by angle: Angle) -> CGVector {
        return self.applying(CGAffineTransform(a: cos(angle), b: sin(angle), c: -sin(angle), d: cos(angle), tx: 0, ty: 0))
    }
}

func sin(_ angle: Angle) -> CGFloat {
    return CGFloat(__sinpi(Double(angle.degrees) / 180))
}

func cos(_ angle: Angle) -> CGFloat {
    return CGFloat(__cospi(Double(angle.degrees) / 180))
}

func tan(_ angle: Angle) -> CGFloat {
    return CGFloat(__tanpi(Double(angle.degrees) / 180))
}
