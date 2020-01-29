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
    private class func makeInputGraph() -> VertexWeightedGraph {
        // TODO: Try with larger voronoi triangulations or low triangle nestings (K4s)

        var graph = VertexWeightedGraph()
        graph.insert("A", at: CGPoint(x: 0, y: 130), weight: 3)
        graph.insert("B", at: CGPoint(x: -75, y: 0), weight: 5)
        graph.insert("C", at: CGPoint(x: 75, y: 0), weight: 7.5)
        graph.insert("D", at: CGPoint(x: 0, y: -130), weight: 2)
        graph.insertEdge(between: "A", and: "B")
        graph.insertEdge(between: "A", and: "C")
        graph.insertEdge(between: "B", and: "C")
        graph.insertEdge(between: "B", and: "D")
        graph.insertEdge(between: "C", and: "D")

        graph.insert("E", at: CGPoint(x: 0, y: 50), weight: 2.5)
        graph.insertEdge(between: "E", and: "A")
        graph.insertEdge(between: "E", and: "B")
        graph.insertEdge(between: "E", and: "C")

        graph.insert("F", at: CGPoint(x: -100, y: 130), weight: 1)
        graph.insertEdge(between: "F", and: "A")
        graph.insertEdge(between: "F", and: "B")

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
        let input = Self.makeInputGraph()
        let dual = input.subdividedDual()

        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.white.cgColor)
        context.fill(rect)

        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: bounds.width / 2, y: bounds.height / 2)
        context.scaleBy(x: 1.5, y: 1.5)
        context.setLineWidth(0.5)

        context.translateBy(x: -120, y: 0)
        self.draw(input)

        context.translateBy(x: 240, y: 0)
        self.draw(dual, original: input)
    }

    private func draw(_ graph: VertexWeightedGraph) {
        let context = UIGraphicsGetCurrentContext()!

        for (endpoint1, endpoint2) in graph.edges {
            context.stroke(
                from: graph.position(of: endpoint1),
                to: graph.position(of: endpoint2),
                color: .black
            )
        }

        for vertex in graph.vertices {
            self.drawLabel(at: graph.position(of: vertex), name: vertex, weight: graph.weight(of: vertex), tintColor: .white)
        }
    }

    private func drawDual(of graph: VertexWeightedGraph) {
        let context = UIGraphicsGetCurrentContext()!

        let faces = graph.faces.inner

        for (endpoint1, endpoint2) in graph.edges {
            let adjacentFaces = faces.filter({ $0.containsEdge(between: endpoint1, and: endpoint2) })

            if adjacentFaces.count == 2 {
                let centroid1 = adjacentFaces[0].vertices.map(graph.position(of:)).centroid
                let centroid2 = adjacentFaces[1].vertices.map(graph.position(of:)).centroid
                let mid = [graph.position(of: endpoint1), graph.position(of: endpoint2)].centroid // must be middle of edge, not middle of centroids!

                context.stroke(from: mid, to: centroid1, color: .black)
                context.stroke(from: mid, to: centroid2, color: .black)
                context.fill(mid, diameter: 5, color: .red)
            } else {
                let position1 = graph.position(of: endpoint1)
                let position2 = graph.position(of: endpoint2)
                let centroid = adjacentFaces[0].vertices.map(graph.position(of:)).centroid
                // results in 'degenerate' drawing but guarantees we don't introduce weird crossings
                let target = [position1, position2].centroid

                context.stroke(from: centroid, to: target, color: .black)
                context.stroke(from: target, to: position1, color: .black)
                context.stroke(from: target, to: position2, color: .black)
                context.fill(target, diameter: 5, color: .blue)
                context.fill([target, centroid].centroid, diameter: 5, color: .red)
                context.fill(position1, diameter: 5, color: .red) // we fill those twice...
                context.fill(position2, diameter: 5, color: .red) // we fill those twice...
            }
        }

        for face in faces {
            let positions = face.vertices.map(graph.position(of:))
            context.fill(positions.centroid, diameter: 5, color: .blue)
        }
    }

    private func draw(_ graph: FaceWeightedGraph, original: VertexWeightedGraph) {
        let context = UIGraphicsGetCurrentContext()!

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

        for face in graph.faces {
            let color = UIColor.color(for: graph.name(of: face))

            var position = face.vertices.map(graph.position(of:)).centroid
            for vertex in face.vertices {
                if case .subdivision3 = vertex {
                    position = graph.position(of: vertex)
                }
            }

            self.drawLabel(at: position, name: graph.name(of: face), weight: graph.weight(of: face), tintColor: color)
        }

        for vertex in graph.vertices {
            switch vertex {
            case .internalFace, .outerEdge:
                context.fill(graph.position(of: vertex), diameter: 3, color: .black)
            case .subdivision1, .subdivision2:
                context.fill(graph.position(of: vertex), diameter: 2, color: .black)
            case .subdivision3:
                break
            }
        }
    }

    private func drawLabel(at position: CGPoint, name: Character, weight: Double, tintColor: UIColor) {
        let context = UIGraphicsGetCurrentContext()!
        let foregroundColor = tintColor == .white ? .black : tintColor.interpolate(to: .black, fraction: 0.75)

        let text = "\(name) | \(weight == weight.rounded() ? Int(weight).description : weight.description)"
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
}

extension Collection where Element == CGPoint {
    var centroid: CGPoint {
        let count = self.isEmpty ? 1 : CGFloat(self.count)
        let x = self.reduce(0, { $0 + $1.x }) / count
        let y = self.reduce(0, { $0 + $1.y  }) / count

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
