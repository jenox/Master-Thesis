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
        return Angle(radians: radians)
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
        return Angle(degrees: degrees)
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
