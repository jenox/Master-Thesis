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
