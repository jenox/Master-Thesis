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
