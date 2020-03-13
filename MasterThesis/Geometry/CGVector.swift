//
//  CGMath.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 12.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics

extension CGVector {
    init(from source: CGPoint, to target: CGPoint) {
        self = CGVector(dx: target.x - source.x, dy: target.y - source.y)
    }

    static prefix func - (value: CGVector) -> CGVector {
        return CGVector(dx: -value.dx, dy: -value.dy)
    }

    static func + (lhs: CGPoint, rhs: CGVector) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
    }

    static func - (lhs: CGPoint, rhs: CGVector) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.dx, y: lhs.y - rhs.dy)
    }

    static func + (lhs: CGVector, rhs: CGVector) -> CGVector {
        return CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }

    static func - (lhs: CGVector, rhs: CGVector) -> CGVector {
        return CGVector(dx: lhs.dx - rhs.dx, dy: lhs.dy - rhs.dy)
    }

    static func += (lhs: inout CGVector, rhs: CGVector) {
        lhs = lhs + rhs
    }

    static func / (lhs: CGVector, rhs: CGFloat) -> CGVector {
        return CGVector(dx: lhs.dx / rhs, dy: lhs.dy / rhs)
    }

    static func * (lhs: CGFloat, rhs: CGVector) -> CGVector {
        return CGVector(dx: lhs * rhs.dx, dy: lhs * rhs.dy)
    }

    var length: CGFloat {
        return hypot(self.dx, self.dy)
    }

    var normalized: CGVector {
        let length = self.length
        guard length > 0 else { return .zero }

        return CGVector(dx: self.dx / self.length, dy: self.dy / self.length)
    }

    static func * (lhs: CGVector, rhs: CGVector) -> CGFloat {
        return lhs.dx * rhs.dx + lhs.dy * rhs.dy
    }

    func cross(_ p: CGVector) -> CGFloat { return self.dx * p.dy - self.dy * p.dx }
}

extension CGVector {
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
}
