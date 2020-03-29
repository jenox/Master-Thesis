/*
 MIT License

 Copyright (c) 2020 Christian Schnorr

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import CoreGraphics

public struct Angle {
    public let turns: CGFloat

    public init(turns: CGFloat) {
        self.turns = turns
    }

    static func turns(_ turns: CGFloat) -> Angle {
        return .init(turns: turns)
    }
}

public extension Angle {
    private static let tau: CGFloat = 2 * .pi

    init(radians: CGFloat) {
        self = Angle(turns: radians / Angle.tau)
    }

    var radians: CGFloat {
        return self.turns * Angle.tau
    }

    static func radians(_ radians: CGFloat) -> Angle {
        return .init(radians: radians)
    }
}

public extension Angle {
    init(degrees: CGFloat) {
        self = Angle(turns: degrees / 360)
    }

    var degrees: CGFloat {
        return 360 * self.turns
    }

    static func degrees(_ degrees: CGFloat) -> Angle {
        return .init(degrees: degrees)
    }
}

extension Angle: CustomStringConvertible {
    public var description: String {
        return "\(self.degrees)°"
    }
}

extension Angle: Equatable, Comparable, Hashable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.turns < rhs.turns
    }
}

public extension Angle {
    static prefix func + (value: Angle) -> Angle {
        return value
    }

    static prefix func - (value: Angle) -> Angle {
        return Angle(turns: -value.turns)
    }

    static func + (lhs: Angle, rhs: Angle) -> Angle {
        return Angle(turns: lhs.turns + rhs.turns)
    }

    static func - (lhs: Angle, rhs: Angle) -> Angle {
        return Angle(turns: lhs.turns - rhs.turns)
    }

    static func += (lhs: inout Angle, rhs: Angle) {
        lhs = lhs + rhs
    }

    static func -= (lhs: inout Angle, rhs: Angle) {
        lhs = lhs - rhs
    }

    static func * (lhs: CGFloat, rhs: Angle) -> Angle {
        return Angle(turns: lhs * rhs.turns)
    }

    static func * (lhs: Angle, rhs: CGFloat) -> Angle {
        return Angle(turns: lhs.turns * rhs)
    }

    static func / (lhs: Angle, rhs: CGFloat) -> Angle {
        return Angle(turns: lhs.turns / rhs)
    }

    static func *= (lhs: inout Angle, rhs: CGFloat) {
        lhs = lhs * rhs
    }

    static func /= (lhs: inout Angle, rhs: CGFloat) {
        lhs = lhs / rhs
    }

    static func * (lhs: Int, rhs: Angle) -> Angle {
        return Angle(turns: CGFloat(lhs) * rhs.turns)
    }

    static func * (lhs: Angle, rhs: Int) -> Angle {
        return Angle(turns: lhs.turns * CGFloat(rhs))
    }

    static func / (lhs: Angle, rhs: Int) -> Angle {
        return Angle(turns: lhs.turns / CGFloat(rhs))
    }

    static func *= (lhs: inout Angle, rhs: Int) {
        lhs = lhs * rhs
    }

    static func /= (lhs: inout Angle, rhs: Int) {
        lhs = lhs / rhs
    }

    static func / (lhs: Angle, rhs: Angle) -> CGFloat {
        return lhs.turns / rhs.turns
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

public func sin(_ angle: Angle) -> CGFloat {
    return CGFloat(__sinpi(Double(angle.degrees) / 180))
}

public func cos(_ angle: Angle) -> CGFloat {
    return CGFloat(__cospi(Double(angle.degrees) / 180))
}

public func tan(_ angle: Angle) -> CGFloat {
    return CGFloat(__tanpi(Double(angle.degrees) / 180))
}

public extension Angle {

    /// [-180°, 180°)
    var normalized: Angle {
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

    /// [0°, 360°)
    var counterclockwise: Angle {
        let normalized = self.normalized

        if normalized.turns < 0 {
            return Angle(turns: normalized.turns + 1)
        }
        else {
            return normalized
        }
    }

    /// (-360°, 0°]
    var clockwise: Angle {
        let normalized = self.normalized

        if normalized.turns > 0 {
            return Angle(turns: normalized.turns - 1)
        }
        else {
            return normalized
        }
    }
}

public extension Angle {
    /// [0°, 180°]
    @available(*, deprecated)
    init(between a: CGVector, and b: CGVector) {
        self = Angle.acos(dot(a.normalized, b.normalized))
    }

    /// [-180°, 180°)
    @available(*, deprecated)
    init(from a: CGVector, to b: CGVector) {
        self = (Angle.atan2(b.dy, b.dx) - Angle.atan2(a.dy, a.dx)).normalized
    }

    /// [-180°, 180°)
    @available(*, deprecated)
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
