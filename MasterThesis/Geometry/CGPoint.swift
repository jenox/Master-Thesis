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
}
