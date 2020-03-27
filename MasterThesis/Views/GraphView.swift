//
//  GraphView.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 08.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import UIKit

class GraphView: UIView {
    var graph: Graph? {
        didSet { self.updateCanvasViewRenderer() }
    }

    var forceComputer: ForceComputer {
        didSet { self.updateCanvasViewRenderer() }
    }

    private let canvasView: CanvasView = .init()

    init(frame: CGRect, graph: Graph?, forceComputer: ForceComputer) {
        self.graph = graph
        self.forceComputer = forceComputer

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
            self.canvasView.renderer = VertexWeightedGraphRenderer(graph: graph)
        case .faceWeighted(let graph):
            self.canvasView.renderer = FaceWeightedGraphRenderer(graph: graph, forceComputer: self.forceComputer)
        case .none:
            self.canvasView.renderer = nil
        }
    }
}

private struct VertexWeightedGraphRenderer: CanvasRenderer {
    var graph: VertexWeightedGraph

    func draw(in context: CGContext, scale: CGFloat, rotation: Angle) {
        let context = UIGraphicsGetCurrentContext()!
        context.setLineWidth(1 / scale)

        // Edges
        for (u, v) in self.graph.edges {
            context.stroke(from: self.graph.position(of: u), to: self.graph.position(of: v), color: .black)
        }

        // Vertices
        for vertex in self.graph.vertices {
            context.fill(self.graph.position(of: vertex), diameter: 5, color: .black)
        }
    }
}

private struct FaceWeightedGraphRenderer: CanvasRenderer {
    var graph: FaceWeightedGraph
    var forceComputer: ForceComputer

    func draw(in context: CGContext, scale: CGFloat, rotation: Angle) {
        let context = UIGraphicsGetCurrentContext()!
        context.setLineWidth(1 / scale)

        // Face backgrounds
        for face in self.graph.faces {
            let color = UIColor.color(for: face).interpolate(to: .white, fraction: 0.75)
            let polygon = self.graph.polygon(for: face)

            context.fill(polygon, with: color)
        }

        // Edges
        for (endpoint1, endpoint2) in self.graph.edges {
            context.stroke(from: self.graph.position(of: endpoint1), to: self.graph.position(of: endpoint2), color: .black)
        }

        // Vertices
        for vertex in self.graph.vertices {
            let position = self.graph.position(of: vertex)

            if self.graph.isSubdivisionVertex(vertex) {
                context.fill(position, diameter: 3 / scale, color: .black)
            } else {
                context.fill(position, diameter: 5 / scale, color: .black)
            }

            let font = UIFont.systemFont(ofSize: 14 / sqrt(scale))
            let string = NSAttributedString(string: "\(vertex)", attributes: [.font: font])
            let line = CTLineCreateWithAttributedString(string)
            let size = CTLineGetBoundsWithOptions(line, .useOpticalBounds).size

            context.textPosition = .zero
            context.textPosition.x -= size.width / 2
            context.textPosition.y -= font.capHeight / 2
            context.saveGState()
            context.translateBy(x: position.x, y: position.y)
            context.rotate(by: -rotation.radians)
            CTLineDraw(line, context)
            context.restoreGState()
        }

        // Forces
        for (vertex, force) in try! self.forceComputer.forces(in: self.graph) {
            context.beginPath()
            context.move(to: self.graph.position(of: vertex))
            context.addLine(to: context.currentPointOfPath + 10 * force)
            context.setStrokeColor(UIColor.red.cgColor)
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
