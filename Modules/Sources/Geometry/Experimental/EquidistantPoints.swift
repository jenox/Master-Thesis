//
//  File.swift
//  
//
//  Created by Christian Schnorr on 28.03.20.
//

import CoreGraphics

public func equidistantPoints(p1: CGPoint, p2: CGPoint, p3: CGPoint) -> [CGPoint] {
    fatalError()
}

public func equidistantPoints(p1: CGPoint, p2: CGPoint, l1: Line) -> [CGPoint] {
    // p_x(t) := (A.x + B.x) / 2 + t * (B.y - A.y)
    // p_y(t) := (A.y + B.y) / 2 + t * (A.x - B.x)
    func point(at t: CGFloat) -> CGPoint {
        return CGPoint(
            x: (p1.x + p2.x) / 2 + t * (p2.y - p1.y),
            y: (p1.y + p2.y) / 2 + t * (p1.x - p2.x)
        )
    }

    let a = p1
    let b = p2
    let c = l1.a
    let d = l1.b

    let mx = (a.x + b.x) / 2
    let my = (a.y + b.y) / 2
    let abx = b.x - a.x
    let aby = b.y - a.y
    let cdx = d.x - c.x
    let cdy = d.y - c.y
    let cxdy = d.y * c.x
    let cydx = d.x * c.y

    // d_AB(t) = hypot(p(t).x - a.x, p(t).y - a.y)
    // let p = pow(b.y-a.y,2)
    // let q = pow(a.x-b.x,2)
    // d_AB(t) = sqrt(t*t*(p+q) + 0.25*(p+q))
    // let z1 = hypot(b.y-a.y,b.x-a.x)
    // d_AB(t) = z1 * sqrt(t*t + 0.25)

    // https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line
    // d_G(t) = abs((d.y - c.y) * p(t).x - (d.x - c.x) * p(t).y + d.x*c.y - d.y*c.x) / hypot(d.y - c.y, d.x - c.x)
//     let z1 = (cdy*aby + cdx*abx)
//     let z2 = cdy*mx - cdx*my + cydx - cxdy
//     let z3 = hypot(cdy, cdx)
    // d_G(t) = abs(t*z1 + z2) / z3

    // Solve d_AB(t) = d_G(t)
    // https://www.wolframalpha.com/input/?i=solve+abs%28t+*+c_1+%2B+c_2%29+%2F+c_3+%3D+c_4+*+sqrt%28t%5E2+%2B+0.25%29+for+t
    let z1 = cdy*aby + cdx*abx
    let z2 = cdy*mx - cdx*my + cydx - cxdy
    let z34 = (cdy*cdy + cdx*cdx) * (aby*aby + abx*abx)
    let base = -2 * z1 * z2
    let root = sqrt(-z34*z34 + z1*z1*z34 + 4*z2*z2*z34)
    let denominator = 2 * (z1*z1 - z34)
    let t1 = (base - root) / denominator
    let t2 = (base + root) / denominator

    return [point(at: t1), point(at: t2)]
}

public func equidistantPoints(a: CGPoint, g: Line, h: Line) -> [CGPoint] {
    let c = g.a
    let d = g.b
    let e = h.a
    let f = h.b

    let cdx = d.x - c.x
    let cdy = d.y - c.y
    let efx = f.x - e.x
    let efy = f.y - e.y
    let cex = e.x - c.x
    let ecy = c.y - e.y

    // intersection
    let t = (efx*ecy + efy*cex) / (cdx*efy - cdy*efx)
    let (mx, my) = (c.x + t * cdx, c.y + t * cdy)
    let amx = mx - a.x
    let amy = my - a.y
    let cydx = d.x*c.y
    let cxdy = d.y*c.x

    // bisector directions
    let cd = (d - c).normalized
    let ef = (f - e).normalized

//


//    func p2(_ t: CGFloat) -> CGPoint {
//        return CGPoint(x: mx, y: my) + t * w1
//    }
//
//    func d_gh1(_ t: CGFloat) -> CGFloat {
//        return g.distance(to: p1(t))
//    }
//    func d_a1(_ t: CGFloat) -> CGFloat {
//        return a.distance(to: p1(t))
//    }
//
//    func d_gh2(_ t: CGFloat) -> CGFloat {
//        return g.distance(to: p2(t))
//    }
//    func d_a2(_ t: CGFloat) -> CGFloat {
//        return a.distance(to: p2(t))
//    }

    var points: [CGPoint] = []

    do {
        let w = (cd + ef).normalized

        let z3 = w.dx*w.dx + w.dy*w.dy
        let z4 = 2*amx*w.dx + 2*amy*w.dy
        let z5 = amx*amx + amy*amy
        let z6 = (w.dx*cdy - w.dy*cdx)
        let z7 = mx*cdy - my*cdx + cydx - cxdy
        let z8 = hypot(cdy, cdx)

        func p(_ t: CGFloat) -> CGPoint {
            return CGPoint(x: mx, y: my) + t * w
        }

        // point-point
        func fastda1(_ t: CGFloat) -> CGFloat {
            return sqrt(t*t*z3 + t*z4 + z5)
        }

        // point-line
        func fastdg1(_ t: CGFloat) -> CGFloat {
            return abs(z6 * t + z7) / z8
        }

        let base = -z4*z8*z8 + 2*z6*z7
        let root = sqrt(pow(z4*z8*z8 - 2*z6*z7, 2) - 4*(z3*z8*z8 - z6*z6)*(z5*z8*z8 - z7*z7))
        let denominator = 2 * (z3*z8*z8 - z6*z6)

        if !root.isNaN {
//            print("!", base, root, denominator)
            let t1 = (base - root) / denominator
            let t2 = (base + root) / denominator

            points += [p(t1), p(t2)]
        }
    }

    do {
        let w = (cd - ef).normalized

        let z3 = w.dx*w.dx + w.dy*w.dy
        let z4 = 2*amx*w.dx + 2*amy*w.dy
        let z5 = amx*amx + amy*amy
        let z6 = (w.dx*cdy - w.dy*cdx)
        let z7 = mx*cdy - my*cdx + cydx - cxdy
        let z8 = hypot(cdy, cdx)

        func p(_ t: CGFloat) -> CGPoint {
            return CGPoint(x: mx, y: my) + t * w
        }

        // point-point
        func fastda1(_ t: CGFloat) -> CGFloat {
            return sqrt(t*t*z3 + t*z4 + z5)
        }

        // point-line
        func fastdg1(_ t: CGFloat) -> CGFloat {
            return abs(z6 * t + z7) / z8
        }

        let base = -z4*z8*z8 + 2*z6*z7
        let root = sqrt(pow(z4*z8*z8 - 2*z6*z7, 2) - 4*(z3*z8*z8 - z6*z6)*(z5*z8*z8 - z7*z7))
        let denominator = 2 * (z3*z8*z8 - z6*z6)

        if !root.isNaN {
//            print("?", base, root, denominator)
            let t1 = (base - root) / denominator
            let t2 = (base + root) / denominator

            points += [p(t1), p(t2)]
        }
    }

    return points
}
