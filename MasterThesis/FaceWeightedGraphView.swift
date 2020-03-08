//
//  FaceWeightedGraphView.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 08.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import UIKit

class FaceWeightedGraphView: UIView, CanvasRenderer {
    var graph: FaceWeightedGraph {
        didSet { self.canvasView.setNeedsDisplay() }
    }

    private let canvasView: CanvasView = .init()

    init(frame: CGRect, graph: FaceWeightedGraph) {
        self.graph = graph

        super.init(frame: frame)

        self.addSubview(self.canvasView)
        self.canvasView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.greaterThanOrEqualToSuperview()
            make.width.equalTo(self.canvasView.snp.height)
            make.width.equalTo(0).priority(.low)
        }

        self.canvasView.renderer = self // Yes, this is a retain cycle...
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func draw(in context: CGContext, scale: CGFloat) {
        context.setLineWidth(1 / scale)
        draw(self.graph, scale: scale)
    }

    private func draw(_ graph: FaceWeightedGraph, scale: CGFloat, labeled: Bool = true) {
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
                context.fill(graph.position(of: vertex), diameter: 5 / scale, color: .black)
            case .subdivision1, .subdivision2, .subdivision3:
                context.fill(graph.position(of: vertex), diameter: 3 / scale, color: .black)
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

            self.drawLabel(at: position, name: graph.name(of: face), weight: graph.weight(of: face), percent: 100 / pressure, tintColor: color, scale: scale)
        }

        let edges = self.graph.edges.map({ (self.graph.position(of: $0.0), self.graph.position(of: $0.1), $0.0, $0.1) })
        for (a,b,u,v) in edges {
            for (c,d,x,y) in edges where a != c || b != d {
                if Segment(a: a, b: b).intersects(Segment(a: c, b: d)) {
                    fatalError("intersection: \(u)-\(v) and \(x)-\(y) at \(a)-\(b) and \(c)-\(d)")
                }
            }
        }

        for (vertex, force) in ForceComputer().forces(in: self.graph) {
            context.beginPath()
            context.move(to: self.graph.position(of: vertex))
            context.addLine(to: context.currentPointOfPath + 10 * force)
            context.setStrokeColor(UIColor.red.cgColor)
            context.strokePath()
        }
    }

    private func drawLabel(at position: CGPoint, name: Character, weight: Double, percent: Double? = nil, tintColor: UIColor, scale: CGFloat) {
        let context = UIGraphicsGetCurrentContext()!
        let foregroundColor = tintColor == .white ? .black : tintColor.interpolate(to: .black, fraction: 0.75)

        var text = "\(name) | \(weight == weight.rounded() ? Int(weight).description : weight.description)"
        if let percent = percent {
            text += " | \(Int(percent.rounded()))%"
        }
        let font = UIFont.systemFont(ofSize: 14 / scale, weight: .regular)
        let attr = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: foregroundColor])
        let line = CTLineCreateWithAttributedString(attr)

        let size = CTLineGetBoundsWithOptions(line, .useOpticalBounds).size
        let bounds = CGRect(origin: position, size: size).offsetBy(dx: -size.width / 2, dy: -size.height / 2)

        context.addPath(UIBezierPath(roundedRect: bounds.insetBy(dx: -5 / scale, dy: -2 / scale), cornerRadius: (size.height / 2 + 2) / scale).cgPath)
        context.setFillColor(tintColor.interpolate(to: .white, fraction: 0.5).cgColor)
        context.setStrokeColor(foregroundColor.cgColor)
        context.drawPath(using: .fillStroke)

        context.textPosition = position
        context.textPosition.x -= size.width / 2
        context.textPosition.y -= font.capHeight / 2
        CTLineDraw(line, context)
    }
}

extension FaceWeightedGraph {
    func vertex(at location: CGPoint) -> Vertex? {
        if let vertex = self.vertices.min(by: { self.position(of: $0).distance(to: location) }) {
            return self.position(of: vertex).distance(to: location) <= 10 ? vertex : nil
        } else {
            return nil
        }
    }

    func face(at location: CGPoint) -> Face<Vertex>? {
        for face in self.faces {
            let vertices = face.vertices.map(self.position(of:))
            let polygon = Polygon(points: vertices)

            if polygon.contains(location) {
                return face
            }
        }

        return nil
    }
}

private extension CGContext {
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
