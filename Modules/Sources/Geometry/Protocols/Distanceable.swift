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

public protocol Distanceable {
    func distance(to point: CGPoint) -> CGFloat
}

extension CGPoint: Distanceable {
    public func distance(to point: CGPoint) -> CGFloat {
        return hypot(point.x - self.x, point.y - self.y)
    }
}

extension Line: Distanceable {
    public func distance(to point: CGPoint) -> CGFloat {
        // Return minimum distance between line segment vw and point p
        let l2 = pow(self.a.distance(to: self.b), 2)  // i.e. |w-v|^2 -  avoid a sqrt
        if (l2 == 0.0) { return self.a.distance(to: point) } // v == w case
        // Consider the line extending the segment, parameterized as v + t (w - v).
        // We find projection of point p onto the line.
        // It falls where t = [(p-v) . (w-v)] / |w-v|^2
        // We clamp t from [0,1] to handle points outside the segment vw.
        let t = dot((point - self.a), (self.b - self.a)) / l2
        let projection = self.a + t * (self.b - self.a) // Projection falls on the segment
        return point.distance(to: projection)
    }
}

extension Segment: Distanceable {
    /// https://stackoverflow.com/a/1501725/796103
    public func distance(to point: CGPoint) -> CGFloat {
        // Return minimum distance between line segment vw and point p
        let l2 = pow(self.start.distance(to: self.end), 2)  // i.e. |w-v|^2 -  avoid a sqrt
        if (l2 == 0.0) { return point.distance(to: self.start) } // v == w case
        // Consider the line extending the segment, parameterized as v + t (w - v).
        // We find projection of point p onto the line.
        // It falls where t = [(p-v) . (w-v)] / |w-v|^2
        // We clamp t from [0,1] to handle points outside the segment vw.
        let t = (dot((point - self.start), (self.end - self.start)) / l2).clamped(to: 0...1)
        let projection = self.start + t * (self.end - self.start) // Projection falls on the segment
        return point.distance(to: projection)
    }
}

private extension Comparable {
    func clamped(to interval: ClosedRange<Self>) -> Self {
        return min(max(self, interval.lowerBound), interval.upperBound)
    }
}
