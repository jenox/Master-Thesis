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

public extension CGVector {
    static prefix func + (value: CGVector) -> CGVector {
        return value
    }

    static prefix func - (value: CGVector) -> CGVector {
        return CGVector(dx: -value.dx, dy: -value.dy)
    }

    static func + (lhs: CGVector, rhs: CGVector) -> CGVector {
        return CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }

    static func - (lhs: CGVector, rhs: CGVector) -> CGVector {
        return CGVector(dx: lhs.dx - rhs.dx, dy: lhs.dy - rhs.dy)
    }

    static func += (lhs: inout CGVector, rhs: CGVector) {
        lhs = lhs + rhs
    }

    static func -= (lhs: inout CGVector, rhs: CGVector) {
        lhs = lhs - rhs
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

    static func *= (lhs: inout CGVector, rhs: CGFloat) {
        lhs = lhs * rhs
    }

    static func /= (lhs: inout CGVector, rhs: CGFloat) {
        lhs = lhs / rhs
    }

    static func * (lhs: Int, rhs: CGVector) -> CGVector {
        return CGVector(dx: CGFloat(lhs) * rhs.dx, dy: CGFloat(lhs) * rhs.dy)
    }

    static func * (lhs: CGVector, rhs: Int) -> CGVector {
        return CGVector(dx: lhs.dx * CGFloat(rhs), dy: lhs.dy * CGFloat(rhs))
    }

    static func / (lhs: CGVector, rhs: Int) -> CGVector {
        return CGVector(dx: lhs.dx / CGFloat(rhs), dy: lhs.dy / CGFloat(rhs))
    }

    static func *= (lhs: inout CGVector, rhs: Int) {
        lhs = lhs * rhs
    }

    static func /= (lhs: inout CGVector, rhs: Int) {
        lhs = lhs / rhs
    }
}

public extension CGVector {
    init(from source: CGPoint, to target: CGPoint) {
        self = CGVector(dx: target.x - source.x, dy: target.y - source.y)
    }

    var length: CGFloat {
        return hypot(self.dx, self.dy)
    }

    var normalized: CGVector {
        let length = self.length
        guard length > 0 else { return .zero }

        return CGVector(dx: self.dx / self.length, dy: self.dy / self.length)
    }

    func scalarProjection(onto other: CGVector) -> CGFloat {
        return dot(self, other) / other.length
    }

    // https://en.wikipedia.org/wiki/Vector_projection
    func projected(onto other: CGVector) -> CGVector {
        return dot(self, other) / dot(other, other) * other
    }

    func rejected(from other: CGVector) -> CGVector {
        return other - self.projected(onto: other)
    }
}

public func abs(_ vector: CGVector) -> CGFloat {
    return hypot(vector.dx, vector.dy)
}

public func dot(_ lhs: CGVector, _ rhs: CGVector) -> CGFloat {
    return lhs.dx * rhs.dx + lhs.dy * rhs.dy
}

public func cross(_ lhs: CGVector, _ rhs: CGVector) -> CGFloat {
    return lhs.dx * rhs.dy - lhs.dy * rhs.dx
}
