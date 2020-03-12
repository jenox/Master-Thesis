//
//  CGPoint.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 22.02.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics

extension CGPoint {
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGVector { return CGVector(dx: lhs.x - rhs.x, dy: lhs.y - rhs.y) }

    static func += (lhs: inout CGPoint, rhs: CGVector) {
        lhs.x += rhs.dx
        lhs.y += rhs.dy
    }

    static func centroid(of points: CGPoint...) -> CGPoint {
        return self.centroid(of: points)
    }

    static func centroid<T>(of collection: T) -> CGPoint where T: Collection, T.Element == CGPoint {
        let count = collection.isEmpty ? 1 : CGFloat(collection.count)
        let x = collection.reduce(0, { $0 + $1.x }) / count
        let y = collection.reduce(0, { $0 + $1.y }) / count

        return CGPoint(x: x, y: y)
    }

    /// Returns the orthogonal projection of the point onto the given segment if
    /// said point would lie on that segment or `nil` if it would not.
    func projected(onto segment: Segment) -> CGPoint? {
        let ab = CGVector(from: segment.a, to: segment.b)
        let av = CGVector(from: segment.a, to: self)
        let fraction = av.scalarProjection(onto: ab) / ab.length

        guard (0...1).contains(fraction) else { return nil }

        return segment.a + fraction * ab
    }
}
