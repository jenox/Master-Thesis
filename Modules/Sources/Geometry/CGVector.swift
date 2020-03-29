//
//  File.swift
//  
//
//  Created by Christian Schnorr on 28.03.20.
//

import CoreGraphics

public extension CGVector {
    static func + (lhs: CGVector, rhs: CGVector) -> CGVector {
        return CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }

    static func - (lhs: CGVector, rhs: CGVector) -> CGVector {
        return CGVector(dx: lhs.dx - rhs.dx, dy: lhs.dy - rhs.dy)
    }

    static func * (lhs: CGFloat, rhs: CGVector) -> CGVector {
        return CGVector(dx: lhs * rhs.dx, dy: lhs * rhs.dy)
    }

    static func * (lhs: CGVector, rhs: CGFloat) -> CGVector {
        return CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
    }

    static func / (lhs: CGVector, rhs: CGFloat) -> CGVector {
        return CGVector(dx: lhs.dx / rhs, dy: lhs.dy / rhs)
    }

    static func * (lhs: CGVector, rhs: CGVector) -> CGFloat {
        return lhs.dx * rhs.dx + lhs.dy * rhs.dy
    }
}

public extension CGVector {
    var length: CGFloat {
        return hypot(self.dx, self.dy)
    }

    var normalized: CGVector {
        return self / self.length
    }

    func rotated90Deg() -> CGVector {
        return CGVector(dx: -self.dy, dy: self.dx)
    }
}
