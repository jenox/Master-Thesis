//
//  ViewController.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 12.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    override func loadView() {
        self.view = Canvas(frame: UIScreen.main.bounds)
    }
}

class Canvas: UIView {
    private var graph = Canvas.makeInputGraph().subdividedDual() {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.addGestureRecognizer(recognizer)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private class func makeInputGraph() -> VertexWeightedGraph {
        // TODO: Try with larger voronoi triangulations or low triangle nestings (K4s)

        let weights: [Double] = [34, 5, 21, 8, 13]

        var graph = VertexWeightedGraph()
        graph.insert("A", at: CGPoint(x: 0, y: 130), weight: weights[0])
        graph.insert("B", at: CGPoint(x: -75, y: 0), weight: weights[1])
        graph.insert("C", at: CGPoint(x: 75, y: 0), weight: weights[2])
        graph.insert("D", at: CGPoint(x: 0, y: -130), weight: weights[3])
        graph.insertEdge(between: "A", and: "B")
        graph.insertEdge(between: "A", and: "C")
        graph.insertEdge(between: "B", and: "C")
        graph.insertEdge(between: "B", and: "D")
        graph.insertEdge(between: "C", and: "D")

        graph.insert("E", at: CGPoint(x: 0, y: 50), weight: weights[4])
        graph.insertEdge(between: "E", and: "A")
        graph.insertEdge(between: "E", and: "B")
        graph.insertEdge(between: "E", and: "C")

//        graph.insertEdge(between: "E", and: "D")

//        graph.insert("F", at: CGPoint(x: -100, y: 130), weight: 4.5)
//        graph.insertEdge(between: "F", and: "A")
//        graph.insertEdge(between: "F", and: "B")

//        var graph = VertexWeightedGraph()
//        graph.insert("A", at: CGPoint(x: 0, y: 130), weight: 1)
//        graph.insert("B", at: CGPoint(x: -75, y: -150), weight: 2)
//        graph.insert("C", at: CGPoint(x: 75, y: -150), weight: 3)
//        graph.insertEdge(between: "A", and: "B")
//        graph.insertEdge(between: "A", and: "C")
//        graph.insertEdge(between: "B", and: "C")
//
//        graph.insert("E", at: CGPoint(x: 0, y: 50), weight: 5)
//        graph.insertEdge(between: "E", and: "A")
//        graph.insertEdge(between: "E", and: "B")
//        graph.insertEdge(between: "E", and: "C")

        return graph
    }

    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.white.cgColor)
        context.fill(rect)

        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: bounds.width / 2, y: bounds.height / 2)
        context.scaleBy(x: 2, y: 2)
        context.setLineWidth(0.5)

        self.draw(self.graph)
    }

    private func draw(_ graph: VertexWeightedGraph, labeled: Bool = true) {
        let context = UIGraphicsGetCurrentContext()!

        for (endpoint1, endpoint2) in graph.edges {
            context.stroke(
                from: graph.position(of: endpoint1),
                to: graph.position(of: endpoint2),
                color: .black
            )
        }

        for vertex in graph.vertices where labeled {
            context.fill(graph.position(of: vertex), diameter: 5, color: .black)
            self.drawLabel(at: graph.position(of: vertex), name: vertex, weight: graph.weight(of: vertex), tintColor: .white)
        }
    }

    private func draw(_ graph: FaceWeightedGraph, labeled: Bool = true) {
        let context = UIGraphicsGetCurrentContext()!
        let totalweight = self.graph.faces.map(self.graph.weight(of:)).reduce(0, +)
        let totalarea = self.graph.faces.map(self.graph.area(of:)).reduce(0, +)

        for face in graph.faces {
            let color = UIColor.color(for: graph.name(of: face)).interpolate(to: .white, fraction: 0.75)

            context.beginPath()
            context.move(to: graph.position(of: face.vertices[0]))
            for vertex in face.vertices.dropFirst() {
                context.addLine(to: graph.position(of: vertex))
            }
            context.closePath()
            context.setFillColor(color.cgColor)
            context.fillPath()
        }

        for (endpoint1, endpoint2) in graph.edges {
            context.stroke(from: graph.position(of: endpoint1), to: graph.position(of: endpoint2), color: .black)
        }

        for vertex in graph.vertices {
            switch vertex {
            case .internalFace, .outerEdge:
                context.fill(graph.position(of: vertex), diameter: 5, color: .black)
            case .subdivision1, .subdivision2, .subdivision3:
                context.fill(graph.position(of: vertex), diameter: 3, color: .black)
            }
        }

        for face in graph.faces where labeled {
            let color = UIColor.color(for: graph.name(of: face))
            var position = face.vertices.map(graph.position(of:)).centroid

            for vertex in face.vertices {
                if case .subdivision3 = vertex {
                    position = graph.position(of: vertex)
                }
            }

            let weight = self.graph.weight(of: face)
            let area = self.graph.area(of: face)
            let pressure = (weight / totalweight) / (area / totalarea)

            self.drawLabel(at: position, name: graph.name(of: face), weight: graph.weight(of: face), percent: 100 / pressure, tintColor: color)
        }

        let edges = self.graph.edges.map({ (self.graph.position(of: $0.0), self.graph.position(of: $0.1), $0.0, $0.1) })
        for (a,b,u,v) in edges {
            for (c,d,x,y) in edges where a != c || b != d {
                if Segment(a: a, b: b).intersects(Segment(a: c, b: d)) {
                    fatalError("intersection: \(u)-\(v) and \(x)-\(y) at \(a)-\(b) and \(c)-\(d)")
                }
            }
        }

        for (vertex, force) in self.computeForces() {
            context.beginPath()
            context.move(to: self.graph.position(of: vertex))
            context.addLine(to: context.currentPointOfPath + 10 * force)
            context.setStrokeColor(UIColor.red.cgColor)
            context.strokePath()
        }
    }

    private func drawLabel(at position: CGPoint, name: Character, weight: Double, percent: Double? = nil, tintColor: UIColor) {
        let context = UIGraphicsGetCurrentContext()!
        let foregroundColor = tintColor == .white ? .black : tintColor.interpolate(to: .black, fraction: 0.75)

        var text = "\(name) | \(weight == weight.rounded() ? Int(weight).description : weight.description)"
        if let percent = percent {
            text += " | \(Int(percent.rounded()))%"
        }
        let font = UIFont.systemFont(ofSize: 10, weight: .regular)
        let attr = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: foregroundColor])
        let line = CTLineCreateWithAttributedString(attr)

        let size = CTLineGetBoundsWithOptions(line, .useOpticalBounds).size
        let bounds = CGRect(origin: position, size: size).offsetBy(dx: -size.width / 2, dy: -size.height / 2)

        context.addPath(UIBezierPath(roundedRect: bounds.insetBy(dx: -5, dy: -2), cornerRadius: size.height / 2 + 2).cgPath)
        context.setFillColor(tintColor.interpolate(to: .white, fraction: 0.5).cgColor)
        context.setStrokeColor(foregroundColor.cgColor)
        context.drawPath(using: .fillStroke)

        context.textPosition = position
        context.textPosition.x -= size.width / 2
        context.textPosition.y -= font.capHeight / 2
        CTLineDraw(line, context)
    }

    @objc private func tapped() {
        let forces = self.computeForces()
        let edges = self.graph.edges.map({ Segment(a: self.graph.position(of: $0.0), b: self.graph.position(of: $0.1)) })

        for (vertex, var force) in forces {
            let position = self.graph.position(of: vertex)
            let mindist = edges.filter({ $0.a != position && $0.b != position }).map(position.distance(to:)).min()!
//            let mindist = positions.filter({ $0 != position }).map(position.distance(to:)).min()!

            // FIXME: this still crashes?!
            if force.length > 0.25 * mindist {
                force = 0.25 * mindist * force.normalized
            }

            self.graph.setPosition(self.graph.position(of: vertex) + force, of: vertex)
        }
    }

    private func computeForces() -> [FaceWeightedGraph.Vertex: CGVector] {
        var forces: [FaceWeightedGraph.Vertex: CGVector] = [:]
        for vertex in self.graph.vertices {
            forces[vertex] = .zero
        }

        let totalweight = self.graph.faces.map(self.graph.weight(of:)).reduce(0, +)
        let totalarea = self.graph.faces.map(self.graph.area(of:)).reduce(0, +)

        for face in self.graph.faces {
            let weight = self.graph.weight(of: face)
            let area = self.graph.area(of: face)
            let pressure = (weight / totalweight) / (area / totalarea)

            let polygon = Polygon(points: face.vertices.map(self.graph.position(of:)))

            for (index, vertex) in face.vertices.enumerated() {
                let (normal, angle) = polygon.normalAndAngle(at: index)

                if pressure >= 1 {
                    forces[vertex]! += CGFloat(log(pressure)) * pow((360 - angle.degrees) / 180, 1) * normal
                } else {
                    forces[vertex]! += CGFloat(log(pressure)) * pow(angle.degrees / 180, 1) * normal
                }
            }
        }

        return forces
    }
}

extension Collection where Element == CGPoint {
    var centroid: CGPoint {
        let count = self.isEmpty ? 1 : CGFloat(self.count)
        let x = self.reduce(0, { $0 + $1.x }) / count
        let y = self.reduce(0, { $0 + $1.y }) / count

        return CGPoint(x: x, y: y)
    }
}

extension CGContext {
    func fill(_ point: CGPoint, diameter: CGFloat, color: UIColor) {
        self.setFillColor(color.cgColor)
        self.fillEllipse(in: CGRect(x: point.x - diameter / 2, y: point.y - diameter / 2, width: diameter, height: diameter))
    }

    func stroke(from source: CGPoint, to target: CGPoint, color: UIColor) {
        self.setStrokeColor(color.cgColor)
        self.beginPath()
        self.move(to: source)
        self.addLine(to: target)
        self.strokePath()
    }
}

extension UIColor {
    private static let colors = [UIColor.red, .green, .blue, .cyan, .yellow, .magenta, .orange, .purple, .brown]

    static func color(for vertex: Character) -> UIColor {
        return self.colors[Int(vertex.unicodeScalars.first!.value + 7) % colors.count]
    }

    func interpolate(to other: UIColor, fraction: CGFloat) -> UIColor {
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0

        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        let r3 = (1 - fraction) * r1 + fraction * r2
        let g3 = (1 - fraction) * g1 + fraction * g2
        let b3 = (1 - fraction) * b1 + fraction * b2
        let a3 = (1 - fraction) * a1 + fraction * a2

        return UIColor(red: r3, green: g3, blue: b3, alpha: a3)
    }
}

extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        return hypot(other.x - self.x, other.y - self.y)
    }

    /// https://stackoverflow.com/a/1501725/796103
    func distance(to segment: Segment) -> CGFloat {
        // Return minimum distance between line segment vw and point p
        let l2 = pow(segment.a.distance(to: segment.b), 2)  // i.e. |w-v|^2 -  avoid a sqrt
        if (l2 == 0.0) { return self.distance(to: segment.a) } // v == w case
        // Consider the line extending the segment, parameterized as v + t (w - v).
        // We find projection of point p onto the line.
        // It falls where t = [(p-v) . (w-v)] / |w-v|^2
        // We clamp t from [0,1] to handle points outside the segment vw.
        let t = max(0, min(1, ((self - segment.a) * (segment.b - segment.a)) / l2))
        let projection = segment.a + t * (segment.b - segment.a) // Projection falls on the segment
        return self.distance(to: projection)
    }
}

struct Segment {
    var a: CGPoint
    var b: CGPoint

    func intersects(_ other: Segment) -> Bool {
        if self.a == other.a || self.a == other.b { return false }
        if self.b == other.a || self.b == other.b { return false }

        return check_inter(a: self.a, b: self.b, c: other.a, d: other.b)
    }
}
// https://cp-algorithms.com/geometry/check-segments-intersection.html
private func inter1(a: CGFloat, b: CGFloat, c: CGFloat, d: CGFloat) -> Bool {
    var a = a; var b = b; var c = c; var d = d;
    if a > b { swap(&a, &b) }
    if c > d { swap(&c, &d) }
    return max(a, c) <= min(b, d)
}
private func check_inter(a: CGPoint, b: CGPoint, c: CGPoint, d: CGPoint) -> Bool {
    if (c.cross(a,d) == 0 && c.cross(b,d) == 0) {
        return inter1(a: a.x, b: b.x, c: c.x, d: d.x) && inter1(a: a.y, b: b.y, c: c.y, d: d.y)
    } else {
        return sgn(a.cross(b,c)) != sgn(a.cross(b,d)) && sgn(c.cross(d,a)) != sgn(c.cross(d,b))
    }
}
private extension CGPoint {
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint { return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y) }
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint { return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y) }
    static func * (lhs: CGPoint, rhs: CGPoint) -> CGFloat { return lhs.x*rhs.x + lhs.y*rhs.y }
    static func * (lhs: CGFloat, rhs: CGPoint) -> CGPoint { return CGPoint(x: lhs * rhs.x, y: lhs * rhs.y) }
    static func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint { return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs) }
    func cross(_ p: CGPoint) -> CGFloat { return self.x * p.y - self.y * p.x}
    func cross(_ a: CGPoint, _ b: CGPoint) -> CGFloat { return (a - self).cross(b - self) }
}
private func sgn(_ x: CGFloat) -> Int { return x >= 0 ? x != 0 ? 1 : 0 : -1 }
