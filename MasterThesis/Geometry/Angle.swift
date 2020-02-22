//
//  Angle.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 12.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics

struct Angle: Equatable, Hashable {
    var turns: CGFloat
}

extension Angle {
    fileprivate static let tau: CGFloat = 2 * .pi

    public init(radians: CGFloat) {
        self = Angle(turns: radians / Angle.tau)
    }

    public static func radians(_ radians: CGFloat) -> Angle {
        return Angle(radians: radians)
    }

    public var radians: CGFloat {
        return self.turns * Angle.tau
    }
}

extension Angle {
    public init(degrees: CGFloat) {
        self = Angle(turns: degrees / 360)
    }

    public static func degrees(_ degrees: CGFloat) -> Angle {
        return Angle(degrees: degrees)
    }

    public var degrees: CGFloat {
        return self.turns * 360
    }
}

extension Angle: CustomStringConvertible {
    public var description: String {
        return "\(self.degrees)°"
    }
}

extension Angle: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.turns < rhs.turns
    }
}

extension Angle {

    /// [-180°, 180°)
    public var normalized: Angle {
        let turns = fmod(self.turns, 1.0)

        if turns < -0.5 {
            return Angle(turns: turns + 1.0)
        }
        else if turns >= 0.5 {
            return Angle(turns: turns - 1.0)
        }
        else {
            return Angle(turns: turns)
        }
    }

    /// [-180°, 180°)
    public mutating func normalize() {
        self = self.normalized
    }

    /// [0°, 360°)
    public var counterclockwise: Angle {
        let normalized = self.normalized

        if normalized.turns < 0 {
            return Angle(turns: normalized.turns + 1)
        }
        else {
            return normalized
        }
    }

    /// (-360°, 0°]
    public var clockwise: Angle {
        let normalized = self.normalized

        if normalized.turns > 0 {
            return Angle(turns: normalized.turns - 1)
        }
        else {
            return normalized
        }
    }
}

extension Angle {
    /// [0°, 180°]
    init(between a: CGVector, and b: CGVector) {
        self = Angle.acos(a.normalized * b.normalized)
    }

    /// [-180°, 180°)
    init(from a: CGVector, to b: CGVector) {
        self = (Angle.atan2(b.dy, b.dx) - Angle.atan2(a.dy, a.dx)).normalized
    }

    /// [-180°, 180°)
    init(from start: CGPoint, by vertex: CGPoint, to end: CGPoint) {
        let vp = CGVector(from: vertex, to: start)
        let vq = CGVector(from: vertex, to: end)
        let angle = Angle(from: vp, to: vq).normalized

        self = angle
    }

    static func direction(of vector: CGVector) -> Angle {
        return Angle.atan2(vector.dy, vector.dx)
    }
}

extension Angle {
    public static func asin(_ value: CGFloat) -> Angle {
        return Angle(radians: CoreGraphics.asin(value))
    }

    public static func acos(_ value: CGFloat) -> Angle {
        return Angle(radians: CoreGraphics.acos(value))
    }

    public static func atan(_ value: CGFloat) -> Angle {
        return Angle(radians: CoreGraphics.atan(value))
    }

    public static func atan2(_ dy: CGFloat, _ dx: CGFloat) -> Angle {
        guard dx != 0 || dy != 0 else {
            preconditionFailure()
        }

        return Angle(radians: CoreGraphics.atan2(dy, dx))
    }

    public static func asinh(_ value: CGFloat) -> Angle {
        return Angle(radians: CoreGraphics.asinh(value))
    }

    public static func acosh(_ value: CGFloat) -> Angle {
        return Angle(radians: CoreGraphics.acosh(value))
    }

    public static func atanh(_ value: CGFloat) -> Angle {
        return Angle(radians: CoreGraphics.atanh(value))
    }
}

extension Angle {
    static prefix func +(angle: Angle) -> Angle {
        return angle
    }

    static prefix func -(angle: Angle) -> Angle {
        return Angle(turns: -angle.turns)
    }

    static func +(lhs: Angle, rhs: Angle) -> Angle {
        return Angle(turns: lhs.turns + rhs.turns)
    }

    static func -(lhs: Angle, rhs: Angle) -> Angle {
        return Angle(turns: lhs.turns - rhs.turns)
    }

    static func +=(lhs: inout Angle, rhs: Angle) {
        lhs = lhs + rhs
    }

    static func -=(lhs: inout Angle, rhs: Angle) {
        lhs = lhs - rhs
    }

    static func *(scalar: CGFloat, angle: Angle) -> Angle {
        return Angle(turns: angle.turns * scalar)
    }

    static func *(angle: Angle, scalar: CGFloat) -> Angle {
        return Angle(turns: angle.turns * scalar)
    }

    static func /(angle: Angle, scalar: CGFloat) -> Angle {
        return Angle(turns: angle.turns / scalar)
    }

    static func *=(angle: inout Angle, scalar: CGFloat) {
        angle = angle * scalar
    }

    static func /=(angle: inout Angle, scalar: CGFloat) {
        angle = angle / scalar
    }

    static func *(scalar: Int, angle: Angle) -> Angle {
        return angle * CGFloat(scalar)
    }

    static func *(angle: Angle, scalar: Int) -> Angle {
        return angle * CGFloat(scalar)
    }

    static func /(angle: Angle, scalar: Int) -> Angle {
        return angle / CGFloat(scalar)
    }

    static func *=(angle: inout Angle, scalar: Int) {
        angle = angle * scalar
    }

    static func /=(angle: inout Angle, scalar: Int) {
        angle = angle / scalar
    }

    static func /(lhs: Angle, rhs: Angle) -> CGFloat {
        return lhs.turns / rhs.turns
    }
}
