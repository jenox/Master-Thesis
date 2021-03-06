//
//  GraphView.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 08.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import UIKit
import SnapKit
import Geometry
import Framework

class GraphView: UIView {
    var graph: EitherGraph? {
        didSet { self.updateCanvasViewRenderer() }
    }

    var forceApplicator: ForceApplicator {
        didSet { self.updateCanvasViewRenderer() }
    }

    private let canvasView: CanvasView = .init()

    init(frame: CGRect, graph: EitherGraph?, forceApplicator: ForceApplicator) {
        self.graph = graph
        self.forceApplicator = forceApplicator

        super.init(frame: frame)

        self.addSubview(self.canvasView)
        self.canvasView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.greaterThanOrEqualToSuperview()
            make.width.equalTo(self.canvasView.snp.height)
            make.width.equalTo(0).priority(.low)
        }

        self.updateCanvasViewRenderer()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func updateCanvasViewRenderer() {
        switch self.graph {
        case .vertexWeighted(let graph):
            self.canvasView.renderer = VertexWeightedGraphRenderer(graph: graph, forceApplicator: self.forceApplicator)
        case .faceWeighted(let graph):
            self.canvasView.renderer = FaceWeightedGraphRenderer(graph: graph, forceApplicator: self.forceApplicator)
        case .none:
            self.canvasView.renderer = nil
        }
    }
}

private struct VertexWeightedGraphRenderer: CanvasRenderer {
    var graph: VertexWeightedGraph
    var forceApplicator: ForceApplicator

    func draw(in context: CGContext, scale: CGFloat, rotation: Angle) {
        let context = UIGraphicsGetCurrentContext()!
        context.setLineWidth(1 / scale)

        // Edges
        for (u, v) in self.graph.edges where u.rawValue < v.rawValue {
            context.stroke(from: self.graph.position(of: u), to: self.graph.position(of: v), color: .black)
        }

        // Vertices
        for vertex in self.graph.vertices {
            let position = self.graph.position(of: vertex)

            context.draw(vertex.rawValue, at: position, scale: scale, rotation: rotation)
        }

        // Forces
        for (vertex, force) in (try? self.forceApplicator.forces(in: self.graph)) ?? [:] {
            context.beginPath()
            context.move(to: self.graph.position(of: vertex))
            context.addLine(to: context.currentPointOfPath + 10 * force)
            context.setStrokeColor(UIColor.red.cgColor)
            context.strokePath()
        }
    }
}

private struct FaceWeightedGraphRenderer: CanvasRenderer {
    var graph: PolygonalDual
    var forceApplicator: ForceApplicator

    func draw(in context: CGContext, scale: CGFloat, rotation: Angle) {
        self.graph.ensureIntegrity(strict: true)

        let context = UIGraphicsGetCurrentContext()!
        context.setLineWidth(1 / scale)

        // Face backgrounds
        for face in self.graph.faces {
            let color = face.color.withAlphaComponent(0.25)
            let polygon = self.graph.polygon(for: face)

            context.fill(polygon, with: color)
        }

        // Edges
        for (u, v) in self.graph.edges where u < v {
            context.stroke(from: self.graph.position(of: u), to: self.graph.position(of: v), color: .black)
        }

        // Vertices
        for vertex in self.graph.vertices {
            let position = self.graph.position(of: vertex)

            if self.graph.isBend(vertex) {
                context.fill(position, diameter: 3 / scale, color: .black)
            } else {
                context.fill(position, diameter: 5 / scale, color: .black)
            }

            context.draw("\(vertex)", at: position, scale: scale, rotation: rotation)
        }

        // Forces
        for (vertex, force) in (try? self.forceApplicator.forces(in: self.graph)) ?? [:] {
            context.beginPath()
            context.move(to: self.graph.position(of: vertex))
            context.addLine(to: context.currentPointOfPath + 10 * force)
            context.setStrokeColor(UIColor.red.cgColor)
            context.strokePath()
        }

        for x in stride(from: -500, through: 500, by: 100) {
            context.move(to: CGPoint(x: x, y: -500))
            context.addLine(to: CGPoint(x: x, y: 500))
            context.setStrokeColor(UIColor.black.cgColor)
            context.strokePath()
        }

        for y in stride(from: -500, through: 500, by: 100) {
            context.move(to: CGPoint(x: -500, y: y))
            context.addLine(to: CGPoint(x: 500, y: y))
            context.setStrokeColor(UIColor.black.cgColor)
            context.strokePath()
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

    func stroke(_ polygon: Polygon, with color: UIColor) {
        self.beginPath()
        self.move(to: polygon.points[0])
        polygon.points.dropFirst().forEach(self.addLine(to:))
        self.closePath()
        self.setStrokeColor(color.cgColor)
        self.strokePath()
    }

    func draw(_ text: String, at position: CGPoint, scale: CGFloat, rotation: Angle) {
        let scale = pow(scale, 0.75)
        let font = UIFont.systemFont(ofSize: 9 / scale)
        let string = NSAttributedString(string: text, attributes: [.font: font])
        let line = CTLineCreateWithAttributedString(string)
        let size = CTLineGetBoundsWithOptions(line, .useOpticalBounds).size

        self.textPosition = .zero
        self.textPosition.x -= size.width / 2
        self.textPosition.y -= font.capHeight / 2
        self.saveGState()
        self.translateBy(x: position.x, y: position.y)
        self.rotate(by: -rotation.radians)
        self.setFillColor(UIColor.white.cgColor)
        self.setStrokeColor(UIColor.black.cgColor)
        self.drawCapsule(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height).insetBy(dx: -3 / scale, dy: -1 / scale), using: .fillStroke)
        CTLineDraw(line, self)
        self.restoreGState()
    }

    func drawCapsule(in rect: CGRect, using mode: CGPathDrawingMode) {
        self.beginPath()
        self.addPath(UIBezierPath(roundedRect: rect, cornerRadius: min(rect.width, rect.height) / 2).cgPath)
        self.drawPath(using: mode)
    }
}

extension ClusterName {
    private static let colors = [UIColor.red, .green, .blue, .cyan, .yellow, .magenta, .orange, .purple, .brown]

    var color: UIColor {
        return Self.colors[Int(rawValue.unicodeScalars.reduce(7, { $0 + $1.value })) % Self.colors.count]
    }
}

extension UIColor {
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
