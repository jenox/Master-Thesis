//
//  File.swift
//  
//
//  Created by Christian Schnorr on 28.03.20.
//

import CoreGraphics

public extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGVector) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
    }

    static func - (lhs: CGPoint, rhs: CGVector) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.dx, y: lhs.y - rhs.dy)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGVector {
        return CGVector(dx: lhs.x - rhs.x, dy: lhs.y - rhs.y)
    }
}

public extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return hypot(point.x - self.x, point.y - self.y)
    }
}
