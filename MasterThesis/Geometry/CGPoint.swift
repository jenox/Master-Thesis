//
//  CGPoint.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 29.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry

extension CGPoint {
    static func centroid<T>(of collection: T) -> CGPoint where T: Collection, T.Element == CGPoint {
        let count = collection.isEmpty ? 1 : CGFloat(collection.count)
        let x = collection.reduce(0, { $0 + $1.x }) / count
        let y = collection.reduce(0, { $0 + $1.y }) / count

        return CGPoint(x: x, y: y)
    }

    static func centroid(of points: CGPoint...) -> CGPoint {
        return self.centroid(of: points)
    }

    /// Returns the orthogonal projection of the point onto the given segment if
    /// said point would lie on that segment or `nil` if it would not.
    func projected(onto segment: Segment) -> CGPoint? {
        let ab = CGVector(from: segment.start, to: segment.end)
        let av = CGVector(from: segment.start, to: self)
        let fraction = av.scalarProjection(onto: ab) / ab.length

        guard (0...1).contains(fraction) else { return nil }

        return segment.start + fraction * ab
    }

    /// https://stackoverflow.com/a/1501725/796103
    @available(*, deprecated)
    func distance(to segment: Segment) -> CGFloat {
        // Return minimum distance between line segment vw and point p
        let l2 = pow(segment.start.distance(to: segment.end), 2)  // i.e. |w-v|^2 -  avoid a sqrt
        if (l2 == 0.0) { return self.distance(to: segment.start) } // v == w case
        // Consider the line extending the segment, parameterized as v + t (w - v).
        // We find projection of point p onto the line.
        // It falls where t = [(p-v) . (w-v)] / |w-v|^2
        // We clamp t from [0,1] to handle points outside the segment vw.
        let t = max(0, min(1, dot((self - segment.start), (segment.end - segment.start)) / l2))
        let projection = segment.start + t * (segment.end - segment.start) // Projection falls on the segment
        return self.distance(to: projection)
    }
}
