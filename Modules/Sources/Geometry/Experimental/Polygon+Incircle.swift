//
//  File.swift
//  
//
//  Created by Christian Schnorr on 29.03.20.
//

/*
import CoreGraphics
import Collections
import class UIKit.UIBezierPath

extension Polygon {
    private func distance(to point: CGPoint) -> CGFloat {
        return self.points.adjacentPairs(wraparound: true).map(Segment.init).map({ $0.distance(to: point) }).min()!
    }

    public var incircleRandomizedRadius: CGFloat {
        let path = UIBezierPath()
        path.move(to: self.points.first!)
        self.points.dropFirst().forEach(path.addLine(to:))
        path.close()

        let minX = self.points.map({ $0.x }).min()!
        let maxX = self.points.map({ $0.x }).max()!
        let minY = self.points.map({ $0.y }).min()!
        let maxY = self.points.map({ $0.y }).max()!
        let bounds = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)

        var generator = SystemRandomNumberGenerator()

        var distances: [CGFloat] = []
        for _ in 0..<10000 {
            let point = CGPoint.random(in: bounds, using: &generator)
            guard path.contains(point) else { continue }
            let distance = self.distance(to: point)
            distances.append(distance)
        }

        return distances.max()!
    }

    public var incircle: Circle? {
        let path = UIBezierPath()
        path.move(to: self.points.first!)
        self.points.dropFirst().forEach(path.addLine(to:))
        path.close()

        let segments = self.points.adjacentPairs(wraparound: true).map(Segment.init)
        let points = self.points
        var circles: [Circle] = []

        // point-point
        for (p,q) in points.strictlyTriangularPairs() {
            circles.append(Circle.circumcircle(of: p, q))
        }

        // point-point-point
        for (p,q,r) in points.strictlyTriangularTriplets() {
            if let circle = Circle.circumcircle(of: p, q, r) {
                circles.append(circle)
            }
        }

        // point-point-edge
        for ((p,q),g) in points.strictlyTriangularPairs().cartesianProduct(with: segments) where allDistinct(p,q,g.start,g.end) {
            let g = Line(through: g.start, and: g.end)
            for center in equidistantPoints(p1: p, p2: q, l1: g) {
                let radius = [p.distance(to: center), q.distance(to: center), g.distance(to: center)].max()!
                if radius.isFinite {
                    circles.append(.init(center: center, radius: radius))
                }
            }
        }

        // point-edge-edge
        for (p,(g,h)) in points.cartesianProduct(with: segments.strictlyTriangularPairs()) where allDistinct(p,g.start,g.end,h.start,h.end) {
            let g = Line(through: g.start, and: g.end)
            let h = Line(through: h.start, and: h.end)
            for center in equidistantPoints(a: p, g: g, h: h) {
                let radius = [p.distance(to: center), g.distance(to: center), h.distance(to: center)].max()!
                if radius.isFinite {
                    circles.append(.init(center: center, radius: radius))
                }
            }
        }

        let filtered = circles.filter({ circle in path.contains(circle.center) && segments.allSatisfy({ $0.isOutside(of: circle) }) })
//        print(circles.count, filtered.count)
//        for circle in circles {
//            print(" -", circle.center, circle.radius, segments.allSatisfy({ $0.isOutside(of: circle) }))
//        }
        let max = filtered.max(by: \.radius)

        return max
    }
}

private func allDistinct(_ points: CGPoint...) -> Bool {
    return points.strictlyTriangularPairs().allSatisfy(!=)
}

private extension Circle {
    func intersects(_ segment: Segment) -> Bool {
        return self.contains(segment.start) == self.contains(segment.end) && self.contains(segment.start) == self.contains(segment.closestPoint(to: self.center))
    }

    static func circumcircle(of a: CGPoint, _ b: CGPoint) -> Circle {
        let center = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        let radius = max(center.distance(to: a), center.distance(to: b))

        return Circle(center: center, radius: radius)
    }

    static func circumcircle(of a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Circle? {
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

private extension Segment {
    func isOutside(of circle: Circle) -> Bool {
        guard self.start.distance(to: circle.center) >= circle.radius * 0.99 else { return false }
        guard self.end.distance(to: circle.center) >= circle.radius * 0.99 else { return false }

        let closest = self.closestPoint(to: circle.center)
        return closest.distance(to: circle.center) >= circle.radius * 0.99
    }

    func distance(to point: CGPoint) -> CGFloat {
        return point.distance(to: self)
    }
}

private extension CGPoint {
    static func random<T>(in bounds: CGRect, using generator: inout T) -> CGPoint where T: RandomNumberGenerator {
        let x = CGFloat.random(in: bounds.minX...bounds.maxX, using: &generator)
        let y = CGFloat.random(in: bounds.minY...bounds.maxY, using: &generator)

        return CGPoint(x: x, y: y)
    }
}

private extension Collection {
    func max<T>(by closure: (Element) throws -> T) rethrows -> Element? where T: Comparable {
        return try self.map({ ($0, try closure($0)) }).max(by: { $0.1 < $1.1 })?.0
    }
}
*/
