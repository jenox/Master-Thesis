//
//  QualityMetricComputer.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 11.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics

class QualityMetricComputer {
    func qualityMetrics(in graph: FaceWeightedGraph) -> [(String, Metrics)] {
        var qualityMetrics: [(String, Metrics)] = []

        let totalweight = graph.faces.map(graph.weight(of:)).reduce(0, +)
        let totalarea = graph.faces.map(graph.area(of:)).reduce(0, +)

        for face in graph.faces {
            let name = graph.name(of: face)
            let weight = graph.weight(of: face)
            let area = graph.area(of: face)
            let normalizedArea = (area / totalarea) * totalweight
            let polygon = Polygon(points: face.vertices.map(graph.position(of:)))

            let statisticalAccuracy = Self.statisticalAccuracy(normalizedArea: normalizedArea, weight: weight)
            let localFatness = Self.localFatness(of: polygon)

            qualityMetrics.append(("\(name)", Metrics(
                weight: weight,
                normalizedArea: normalizedArea,
                statisticalAccuracy: statisticalAccuracy,
                localFatness: localFatness
            )))
        }

        return qualityMetrics
    }

    private class func statisticalAccuracy(normalizedArea: Double, weight: Double) -> Double {
        let pressure = weight / normalizedArea

        return min(pressure, 1 / pressure)
    }

    // https://mathematica.stackexchange.com/questions/121987/
    private class func localFatness(of polygon: Polygon) -> Double {
        let circle = Circle.smallestEnclosingCircle(of: polygon.points)

        // Area of regular n-gon in circle
        let angle = Angle(turns: 0.5 / CGFloat(polygon.points.count))
        let maxarea = CGFloat(polygon.points.count) * circle.radius * cos(angle) * circle.radius * sin(angle)

        let fatness = polygon.area / maxarea

        return Double(fatness)
    }
}

private struct Circle {
    var center: CGPoint
    var radius: CGFloat

    func contains(_ point: CGPoint) -> Bool {
        return self.center.distance(to: point) <= self.radius * 1.00001
    }

    // MARK: - Smallest Enclosing Circle

    // https://www.nayuki.io/page/smallest-enclosing-circle
    static func smallestEnclosingCircle(of points: [CGPoint]) -> Circle {
        // Progressively add points to circle or recompute circle
        var c: Circle? = nil

        for (offset, p) in points.enumerated() {
            if c == nil || !c!.contains(p) {
                c = .smallestEnclosingCircle(of: points.dropFirst(offset + 1), p)
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
                circle = .smallestEnclosingCircle(of: points.dropFirst(offset + 1), p, q)
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
            let cross: CGFloat = pq.cross(r - p)

            if let circle = Circle.circumcircle(of: p, q, r) {
                if cross > 0 && (left == nil || pq.cross(circle.center - p) > pq.cross(left!.center - p)) {
                    left = circle
                } else if cross < 0 && (right == nil || pq.cross(circle.center - p) < pq.cross(right!.center - p)) {
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
        let ab = CGVector(from: a, to: b)

        return Circle(center: a + 0.5 * ab, radius: 0.5 * ab.length)
    }

    private static func circumcircle(of a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Circle? {
        let ox = min(a.x, b.x, c.x) + max(min(a.x, b.x), c.x) / 2
        let oy = min(a.y, b.y, c.y) + max(min(a.y, b.y), c.y) / 2
        let ax = a.x - ox
        let ay = a.y - oy
        let bx = b.x - ox
        let by = b.y - oy
        let cx = c.x - ox
        let cy = c.y - oy
        let d = (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by)) * 2

        guard d != 0 else { return nil }

        let x = ((ax*ax + ay*ay) * (by - cy) + (bx*bx + by*by) * (cy - ay) + (cx*cx + cy*cy) * (ay - by)) / d
        let y = ((ax*ax + ay*ay) * (cx - bx) + (bx*bx + by*by) * (ax - cx) + (cx*cx + cy*cy) * (bx - ax)) / d

        let center = CGPoint(x: ox + x, y: oy + y)
        let radius = max(center.distance(to: a), center.distance(to: b), center.distance(to: c))
        let circle = Circle(center: center, radius: radius)

        let distances = [a,b,c].map(center.distance(to:))
        precondition(distances.max()! / distances.min()! <= 1.0001)

        return circle
    }
}

struct Metrics {
    var weight: Double
    var normalizedArea: Double
    var statisticalAccuracy: Double
    var localFatness: Double
}
