//
//  CGMath.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 12.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry

extension CGVector {
    init(from source: CGPoint, to target: CGPoint) {
        self = CGVector(dx: target.x - source.x, dy: target.y - source.y)
    }

    var length: CGFloat {
        return hypot(self.dx, self.dy)
    }

    var normalized: CGVector {
        let length = self.length
        guard length > 0 else { return .zero }

        return CGVector(dx: self.dx / self.length, dy: self.dy / self.length)
    }

    func cross(_ p: CGVector) -> CGFloat { return self.dx * p.dy - self.dy * p.dx }

    func scalarProjection(onto other: CGVector) -> CGFloat {
        return self * other / other.length
    }

    // https://en.wikipedia.org/wiki/Vector_projection
    func projected(onto other: CGVector) -> CGVector {
        return (self * other) / (other * other) * other
    }

    func rejected(from other: CGVector) -> CGVector {
        return other - self.projected(onto: other)
    }

    func rotated(by angle: Angle) -> CGVector {
        return self.applying(CGAffineTransform(a: cos(angle), b: sin(angle), c: -sin(angle), d: cos(angle), tx: 0, ty: 0))
    }
}
