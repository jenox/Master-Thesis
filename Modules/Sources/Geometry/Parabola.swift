//
//  File.swift
//  
//
//  Created by Christian Schnorr on 28.03.20.
//

import CoreGraphics

public struct Parabola {
    public var focus: CGPoint
    public var directrix: Line
}

public extension Parabola {
    // https://www.mathed.page/parabolas/geometry/index.html
    func point(at t: CGFloat) -> CGPoint {
        let T = self.directrix.point(at: t)
        let M = CGPoint(x: (self.focus.x + T.x) / 2, y: (self.focus.y + T.y) / 2)

        let l1 = Line(through: M, and: M + (self.focus - M).rotated90Deg())
        let l2 = Line(through: T, and: T + (self.directrix.b - self.directrix.a).rotated90Deg())

        return l1.intersection(with: l2)!
    }
}
