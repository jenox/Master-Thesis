//
//  Circle.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 29.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry

extension Circle {
    func contains(_ point: CGPoint) -> Bool {
        return self.center.distance(to: point) <= self.radius * 1.00001
    }

    var boundingBox: CGRect {
        return CGRect(x: self.center.x - self.radius, y: self.center.y - self.radius, width: 2 * self.radius, height: 2 * self.radius)
    }

    // MARK: - Smallest Enclosing Circle

    // https://www.nayuki.io/page/smallest-enclosing-circle
    static func smallestEnclosingCircle(of points: [CGPoint]) -> Circle {
        // Progressively add points to circle or recompute circle
        var c: Circle? = nil

        for (offset, p) in points.enumerated() {
            if c == nil || !c!.contains(p) {
                c = .smallestEnclosingCircle(of: points.prefix(offset), p)
            }
        }

        return c!
    }

    private static func smallestEnclosingCircle(of points: ArraySlice<CGPoint>, _ p: CGPoint) -> Circle {
        var circle = Circle(center: p, radius: 0)

        for (offset, q) in points.enumerated() where !circle.contains(q) {
            if circle.radius == 0 {
                circle = .circumcircle(of: p, q)
            } else {
                circle = .smallestEnclosingCircle(of: points.prefix(offset), p, q)
            }
        }

        return circle
    }

    private static func smallestEnclosingCircle(of points: ArraySlice<CGPoint>, _ p: CGPoint, _ q: CGPoint) -> Circle {
        let circle = Circle.circumcircle(of: p, q)
        var left: Circle? = nil
        var right: Circle? = nil

        // For each point not in the two-point circle
        for r in points where !circle.contains(r) {
            let pq = q - p
            let prod: CGFloat = cross(pq, r - p)

            if let circle = Circle.circumcircle(of: p, q, r) {
                if prod > 0 && (left == nil || cross(pq, circle.center - p) > cross(pq, left!.center - p)) {
                    left = circle
                } else if prod < 0 && (right == nil || cross(pq, circle.center - p) < cross(pq, right!.center - p)) {
                    right = circle
                }
            }
        }

        // Select which circle to return
        switch (left, right) {
        case (.none, .none): return circle
        case (.none, .some(let right)): return right
        case (.some(let left), .none): return left
        case (.some(let left), .some(let right)): return left.radius <= right.radius ? left : right
        }
    }

    private static func circumcircle(of a: CGPoint, _ b: CGPoint) -> Circle {
        let center = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        let radius = max(center.distance(to: a), center.distance(to: b))

        return Circle(center: center, radius: radius)
    }

    private static func circumcircle(of a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Circle? {
        let ox = (min(a.x, b.x, c.x) + max(a.x, b.x, c.x)) / 2
        let oy = (min(a.y, b.y, c.y) + max(a.y, b.y, c.y)) / 2
        let ax = a.x - ox
        let ay = a.y - oy
        let bx = b.x - ox
        let by = b.y - oy
        let cx = c.x - ox
        let cy = c.y - oy
        let d = (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by)) * 2

        guard d != 0 else { return nil }

        let x = ox + ((ax*ax + ay*ay) * (by - cy) + (bx*bx + by*by) * (cy - ay) + (cx*cx + cy*cy) * (ay - by)) / d
        let y = oy + ((ax*ax + ay*ay) * (cx - bx) + (bx*bx + by*by) * (ax - cx) + (cx*cx + cy*cy) * (bx - ax)) / d

        let center = CGPoint(x: x, y: y)
        let radius = [a,b,c].map(center.distance(to:)).max()!

        return Circle(center: center, radius: radius)
    }
}
