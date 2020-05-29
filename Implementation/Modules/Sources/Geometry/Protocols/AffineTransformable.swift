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

public protocol AffineTransformable {
    associatedtype TransformedSelf = Self

    func applying(_ transform: CGAffineTransform) -> TransformedSelf
}

public extension AffineTransformable {
    func offset(by offset: CGVector) -> TransformedSelf {
        return self.applying(.init(translationX: offset.dx, y: offset.dy))
    }

    func offsetBy(tx: CGFloat, ty: CGFloat) -> TransformedSelf {
        return self.applying(.init(translationX: tx, y: ty))
    }

    func translated(by translation: CGVector) -> TransformedSelf {
        return self.applying(.init(translationX: translation.dx, y: translation.dy))
    }

    func translatedBy(tx: CGFloat, ty: CGFloat) -> TransformedSelf {
        return self.applying(.init(translationX: tx, y: ty))
    }

    func scaled(by scale: CGFloat, around center: CGPoint = .zero) -> TransformedSelf {
        var transform = CGAffineTransform(translationX: center.x, y: center.y)
        transform = transform.scaledBy(x: scale, y: scale)
        transform = transform.translatedBy(x: -center.x, y: -center.y)

        return self.applying(transform)
    }

    func scaledBy(sx: CGFloat, sy: CGFloat) -> TransformedSelf {
        return self.applying(.init(scaleX: sx, y: sy))
    }

    func rotated(by radians: CGFloat) -> TransformedSelf {
        return self.applying(.init(rotationAngle: radians))
    }

    func rotated(by angle: Angle) -> TransformedSelf {
        return self.applying(.init(a: cos(angle), b: sin(angle), c: -sin(angle), d: cos(angle), tx: 0, ty: 0))
    }
}

extension CGPoint: AffineTransformable {
    public typealias TransformedSelf = CGPoint
}

extension CGRect: AffineTransformable {
    public typealias TransformedSelf = CGRect
}

extension CGVector: AffineTransformable {
    public typealias TransformedSelf = CGVector

    public func applying(_ transform: CGAffineTransform) -> CGVector {
        let dx = self.dx * transform.a + self.dy * transform.c
        let dy = self.dx * transform.b + self.dy * transform.d

        return CGVector(dx: dx, dy: dy)
    }
}

extension Segment: AffineTransformable {
    public typealias TransformedSelf = Segment

    public func applying(_ transform: CGAffineTransform) -> Segment {
        return Segment(from: self.start.applying(transform), to: self.end.applying(transform))
    }
}

extension Line: AffineTransformable {
    public typealias TransformedSelf = Line

    public func applying(_ transform: CGAffineTransform) -> Line {
        return Line(through: self.a.applying(transform), and: self.b.applying(transform))
    }
}

extension Polygon: AffineTransformable {
    public typealias TransformedSelf = Polygon

    public func applying(_ transform: CGAffineTransform) -> Polygon {
        return Polygon(points: self.points.map({ $0.applying(transform) }))
    }
}
