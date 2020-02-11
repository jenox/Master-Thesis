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

    var area: CGFloat {
        return self.points.makeAdjacentPairIterator().reduce(0, { $0 + $1.0.x * $1.1.y - $1.0.y * $1.1.x })
    }
}

extension Polygon {
    func normal(at index: Int) -> CGVector {
        let a = self.points[(index + self.points.count - 1) % self.points.count]
        let b = self.points[index]
        let c = self.points[(index + 1) % self.points.count]

        let vp = CGVector(from: b, to: a)
        let vq = CGVector(from: b, to: c)

        let outside = (Angle.atan2(vq.dy, vq.dx) - Angle.atan2(vp.dy, vp.dx)).counterclockwise
        return vp.rotated(by: outside / 2).normalized
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

extension Angle {
    /// [0°, 180°]
    init(between a: CGVector, and b: CGVector) {
        self = Angle.acos(a.normalized * b.normalized)
    }

    /// [-180°, 180°)
    init(from a: CGVector, to b: CGVector) {
        self = (Angle.atan2(b.dy, b.dx) - Angle.atan2(a.dy, a.dx)).normalized
    }

    /// [-180°, 180°)
    init(from start: CGPoint, by vertex: CGPoint, to end: CGPoint) {
        let vp = CGVector(from: vertex, to: start)
        let vq = CGVector(from: vertex, to: end)
        let angle = Angle(from: vp, to: vq).normalized

        self = angle
    }
}
