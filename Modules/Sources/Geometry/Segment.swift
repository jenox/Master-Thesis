//
//  File.swift
//  
//
//  Created by Christian Schnorr on 28.03.20.
//

import CoreGraphics

public struct Segment {
    public init(from start: CGPoint, to end: CGPoint) {
        self.start = start
        self.end = end
    }

    public var start: CGPoint
    public var end: CGPoint

    public func equidistantPoints() -> Line? {
        let midpoint = self.start + 0.5 * (self.end - self.start)
        let direction = (self.end - self.start).rotated90Deg()

        return Line(through: midpoint, and: midpoint + direction)
    }
}
