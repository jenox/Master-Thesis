//
//  Misc.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 22.02.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics

extension Collection where Element == CGPoint {
    var centroid: CGPoint {
        let count = self.isEmpty ? 1 : CGFloat(self.count)
        let x = self.reduce(0, { $0 + $1.x }) / count
        let y = self.reduce(0, { $0 + $1.y }) / count

        return CGPoint(x: x, y: y)
    }
}

extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        return hypot(other.x - self.x, other.y - self.y)
    }

    /// https://stackoverflow.com/a/1501725/796103
    func distance(to segment: Segment) -> CGFloat {
        // Return minimum distance between line segment vw and point p
        let l2 = pow(segment.a.distance(to: segment.b), 2)  // i.e. |w-v|^2 -  avoid a sqrt
        if (l2 == 0.0) { return self.distance(to: segment.a) } // v == w case
        // Consider the line extending the segment, parameterized as v + t (w - v).
        // We find projection of point p onto the line.
        // It falls where t = [(p-v) . (w-v)] / |w-v|^2
        // We clamp t from [0,1] to handle points outside the segment vw.
        let t = max(0, min(1, ((self - segment.a) * (segment.b - segment.a)) / l2))
        let projection = segment.a + t * (segment.b - segment.a) // Projection falls on the segment
        return self.distance(to: projection)
    }
}

struct Segment {
    var a: CGPoint
    var b: CGPoint

    func intersects(_ other: Segment) -> Bool {
        if self.a == other.a || self.a == other.b { return false }
        if self.b == other.a || self.b == other.b { return false }

        return check_inter(a: self.a, b: self.b, c: other.a, d: other.b)
    }

    func point(at progress: CGFloat) -> CGPoint {
        return CGPoint(
            x: self.a.x + progress * (self.b.x - self.a.x),
            y: self.a.y + progress * (self.b.y - self.a.y)
        )
    }
}
// https://cp-algorithms.com/geometry/check-segments-intersection.html
private func inter1(a: CGFloat, b: CGFloat, c: CGFloat, d: CGFloat) -> Bool {
    var a = a; var b = b; var c = c; var d = d;
    if a > b { swap(&a, &b) }
    if c > d { swap(&c, &d) }
    return max(a, c) <= min(b, d)
}
private func check_inter(a: CGPoint, b: CGPoint, c: CGPoint, d: CGPoint) -> Bool {
    if (c.cross(a,d) == 0 && c.cross(b,d) == 0) {
        return inter1(a: a.x, b: b.x, c: c.x, d: d.x) && inter1(a: a.y, b: b.y, c: c.y, d: d.y)
    } else {
        return sgn(a.cross(b,c)) != sgn(a.cross(b,d)) && sgn(c.cross(d,a)) != sgn(c.cross(d,b))
    }
}
private extension CGPoint {
    func cross(_ a: CGPoint, _ b: CGPoint) -> CGFloat { return (a - self).cross(b - self) }
}
private func sgn(_ x: CGFloat) -> Int { return x >= 0 ? x != 0 ? 1 : 0 : -1 }
