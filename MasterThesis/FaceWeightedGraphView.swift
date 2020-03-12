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
        self.draw(self.graph, scale: scale)
    }

    private func draw(_ graph: FaceWeightedGraph, scale: CGFloat, labeled: Bool = true) {
        let context = UIGraphicsGetCurrentContext()!

        // Face backgrounds
        for face in graph.faces {
            let color = UIColor.color(for: face).interpolate(to: .white, fraction: 0.75)
            let polygon = graph.polygon(for: face)

            context.fill(polygon, with: color)
        }

        // Edges
        for (endpoint1, endpoint2) in graph.edges {
            context.stroke(from: graph.position(of: endpoint1), to: graph.position(of: endpoint2), color: .black)
        }

        // Vertices
        for vertex in graph.vertices {
            switch graph.vertices(adjacentTo: vertex).count {
            case 2: context.fill(graph.position(of: vertex), diameter: 3 / scale, color: .black)
            case 3: context.fill(graph.position(of: vertex), diameter: 5 / scale, color: .black)
            default: fatalError()
            }
        }

        // Face circumcircles
        for face in graph.faces {
            let polygon = graph.polygon(for: face)
            let circle = Circle.smallestEnclosingCircle(of: polygon.points)

            context.stroke(circle, with: UIColor.color(for: face).withAlphaComponent(0.4))
        }

        // Forces
        for (vertex, force) in ForceComputer().forces(in: self.graph) {
            context.beginPath()
            context.move(to: self.graph.position(of: vertex))
            context.addLine(to: context.currentPointOfPath + 10 * force)
            context.setStrokeColor(UIColor.red.cgColor)
            context.strokePath()
        }

        let edges = self.graph.edges.map({ (self.graph.position(of: $0.0), self.graph.position(of: $0.1), $0.0, $0.1) })
        for (a,b,u,v) in edges {
            for (c,d,x,y) in edges where a != c || b != d {
                if Segment(a: a, b: b).intersects(Segment(a: c, b: d)) {
                    fatalError("intersection: \(u)-\(v) and \(x)-\(y) at \(a)-\(b) and \(c)-\(d)")
                }
            }
        }
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

    func fill(_ polygon: Polygon, with color: UIColor) {
        self.beginPath()
        self.move(to: polygon.points[0])
        polygon.points.dropFirst().forEach(self.addLine(to:))
        self.closePath()
        self.setFillColor(color.cgColor)
        self.fillPath()
    }

    func stroke(_ circle: Circle, with color: UIColor) {
        self.beginPath()
        self.addEllipse(in: circle.boundingBox)
        self.setStrokeColor(color.cgColor)
        self.strokePath()
    }
}

extension UIColor {
    private static let colors = [UIColor.red, .green, .blue, .cyan, .yellow, .magenta, .orange, .purple, .brown]

    static func color(for vertex: Character) -> UIColor {
        return self.colors[Int(vertex.unicodeScalars.first!.value + 7) % colors.count]
    }

    static func color(for string: String) -> UIColor {
        return self.colors[Int(string.unicodeScalars.reduce(7, { $0 + $1.value })) % colors.count]
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