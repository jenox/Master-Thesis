//
//  Segment.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 29.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry

extension Segment {
    func intersects(_ other: Segment) -> Bool {
        return check_inter(a: self.start, b: self.end, c: other.start, d: other.end)
    }

    func closestPoint(to other: CGPoint) -> CGPoint {
        // Return minimum distance between line segment vw and point p
        let l2 = pow(self.start.distance(to: self.end), 2)  // i.e. |w-v|^2 -  avoid a sqrt
        guard (l2 != 0.0) else { return self.start } // v == w case
        // Consider the line extending the segment, parameterized as v + t (w - v).
        // We find projection of point p onto the line.
        // It falls where t = [(p-v) . (w-v)] / |w-v|^2
        // We clamp t from [0,1] to handle points outside the segment vw.
        let t = dot((other - self.start), (self.end - self.start)) / l2
        return self.point(at: max(0, min(1, t)))
    }

    func orthogonalProjection(of other: CGPoint) -> CGPoint? {
        // Return minimum distance between line segment vw and point p
        let l2 = pow(self.start.distance(to: self.end), 2)  // i.e. |w-v|^2 -  avoid a sqrt
        guard (l2 != 0.0) else { return self.start } // v == w case
        // Consider the line extending the segment, parameterized as v + t (w - v).
        // We find projection of point p onto the line.
        // It falls where t = [(p-v) . (w-v)] / |w-v|^2
        // We clamp t from [0,1] to handle points outside the segment vw.
        let t = dot((other - self.start), (self.end - self.start)) / l2
        guard t >= 0 && t <= 1 else { return nil }
        return self.point(at: t)
    }

    var midpoint: CGPoint {
        return CGPoint.centroid(of: self.start, self.end)
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
    func cross(_ a: CGPoint, _ b: CGPoint) -> CGFloat { return Geometry.cross(a - self, b - self) }
}
private func sgn(_ x: CGFloat) -> Int { return x >= 0 ? x != 0 ? 1 : 0 : -1 }
