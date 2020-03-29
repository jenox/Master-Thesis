//
//  File.swift
//  
//
//  Created by Christian Schnorr on 28.03.20.
//

import CoreGraphics

// Line: ax + by + c = 0
public struct Line {
    public init(through a: CGPoint, and b: CGPoint) {
        self.a = a
        self.b = b
    }

    public var a: CGPoint
    public var b: CGPoint

    public func point(at t: CGFloat) -> CGPoint {
        let x = a.x + t * (b.x - a.x)
        let y = a.y + t * (b.y - a.y)

        return CGPoint(x: x, y: y)
    }
}

public extension Line {
    func distance(to point: CGPoint) -> CGFloat {
        // Return minimum distance between line segment vw and point p
        let l2 = pow(self.a.distance(to: self.b), 2)  // i.e. |w-v|^2 -  avoid a sqrt
        if (l2 == 0.0) { return self.a.distance(to: point) } // v == w case
        // Consider the line extending the segment, parameterized as v + t (w - v).
        // We find projection of point p onto the line.
        // It falls where t = [(p-v) . (w-v)] / |w-v|^2
        // We clamp t from [0,1] to handle points outside the segment vw.
        let t = ((point - self.a) * (self.b - self.a)) / l2
        let projection = self.a + t * (self.b - self.a) // Projection falls on the segment
        return point.distance(to: projection)
    }

    /// https://en.wikipedia.org/wiki/Line-line_intersection#Given_two_points_on_each_line
    func intersection(with other: Line) -> CGPoint? {
        let (x1, y1) = (self.a.x, self.a.y)
        let (x2, y2) = (self.b.x, self.b.y)
        let (x3, y3) = (other.a.x, other.a.y)
        let (x4, y4) = (other.b.x, other.b.y)

        let x = ((x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)) / ((x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4))
        let y = ((x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)) / ((x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4))

        return CGPoint(x: x, y: y)
    }
}
