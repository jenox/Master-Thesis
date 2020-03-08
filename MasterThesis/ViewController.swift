//
//  ViewController.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 12.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import UIKit
import SnapKit

class ViewController: UIViewController {
    override func loadView() {
        self.view = Canvas(frame: UIScreen.main.bounds)
    }
}

class Canvas: UIView {

    // MARK: - Stored Properties

    // TODO: Try with larger voronoi triangulations or low triangle nestings (K4s)
    var graph = Canvas.makeVoronoiInputGraph().subdividedDual() {
        didSet {
            self.statisticsView.countryStatistics = Self.statistics(from: self.graph)
            setNeedsDisplay()
        }
    }

    private let toggle = UISwitch()
    private let statisticsView: StatisticsView


    // MARK: - Initialization

    private class func statistics(from graph: FaceWeightedGraph) -> [CountryStatistics] {
        var stats: [CountryStatistics] = []
        let totalweight = graph.faces.map(graph.weight(of:)).reduce(0, +)
        let totalarea = graph.faces.map(graph.area(of:)).reduce(0, +)

        for face in graph.faces {
            let name = graph.name(of: face)
            let color = UIColor.color(for: name)
            let weight = graph.weight(of: face)
            let area = graph.area(of: face)
            let pressure = (weight / totalweight) / (area / totalarea)

            stats.append(.init(countryName: "\(name)", countryColor: color, statisticalAccuracy: round(1e3 * min(pressure, 1 / pressure)) / 1e1, localFatness: 1))
        }

        return stats
    }

    override init(frame: CGRect) {
        self.statisticsView = StatisticsView(countryStatistics: Self.statistics(from: self.graph))

        super.init(frame: frame)

        self.addSubview(self.statisticsView)
        self.statisticsView.snp.makeConstraints { make in
            make.left.bottom.equalToSuperview().inset(20)
        }

        toggle.addTarget(self, action: #selector(toggleDidChange), for: .valueChanged)
        addSubview(toggle)
        toggle.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(40)
            make.top.equalToSuperview().inset(40)
        }
    }

    required init?(coder: NSCoder) {
        fatalError()
    }


    // MARK: - Stepping

    @objc private func toggleDidChange() {
        if self.toggle.isOn {
            self.beginSteppingContinuously()
        } else {
            self.endSteppingContinuously()
        }
    }

    private var isSteppingContinuously: Bool = false
    private var hasScheduledNextSteppingBlock: Bool = false

    func beginSteppingContinuously() {
        self.toggle.setOn(true, animated: true)
        guard !isSteppingContinuously else { return }

        self.isSteppingContinuously = true

        if !self.hasScheduledNextSteppingBlock {
            self.hasScheduledNextSteppingBlock = true

            self.queue.async(execute: self.stepOnceAndScheduleNextIfNeeded)
        }
    }

    func endSteppingContinuously() {
        self.toggle.setOn(false, animated: true)
        isSteppingContinuously = false
    }

    private func stepOnceAndScheduleNextIfNeeded() {
        DispatchQueue.main.async(execute: {
            self.hasScheduledNextSteppingBlock = false
        })

        let before = CACurrentMediaTime()
        var graph = self.graph
        let forces = ForceComputer().forces(in: graph)
        ForceApplicator().apply(forces, to: &graph)
        DispatchQueue.main.async(execute: {
            self.graph = graph
        })
        let after = CACurrentMediaTime()
        print("Stepped in \(String(format: "%.3f", 1e3 * (after - before)))ms")

        DispatchQueue.main.async(execute: {
            if self.isSteppingContinuously && !self.hasScheduledNextSteppingBlock {
                self.queue.asyncAfter(deadline: .now() + 0.1, execute: self.stepOnceAndScheduleNextIfNeeded)
            }
        })
    }

    private let queue = DispatchQueue(label: "GraphModificationQueue")

    func performGraphOperation(_ transform: @escaping (inout FaceWeightedGraph) -> Void) {
        self.queue.async(execute: {
            let before = CACurrentMediaTime()
            var graph = self.graph
            transform(&graph)
            DispatchQueue.main.async(execute: {
                self.graph = graph
            })
            let after = CACurrentMediaTime()
            print("Performed graph operation in \(String(format: "%.3f", 1e3 * (after - before)))ms")
        })
    }

//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//       let location = touches.first!.location(in: self).applying(self.effectiveRenderingTransform.inverted())
//
//        guard let face = self.graph.face(at: location) else { return }
//
//        self.toggle.setOn(false, animated: true)
//
//        let name = self.graph.name(of: face)
//        let text = "\(self.graph.weight(of: face))"
//
//        let alert = UIAlertController(title: "Face \(name)", message: nil, preferredStyle: .alert)
//        alert.addTextField(configurationHandler: { tf in tf.text = text; tf.placeholder = text })
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
//            if let weight = alert.textFields![0].text.flatMap(Double.init) {
//                self.graph.setWeight(weight, of: face)
//                self.toggle.setOn(true, animated: true)
//                self.toggle.sendActions(for: .valueChanged)
//            }
//        }))
//
//        (self.next as! UIViewController).present(alert, animated: true, completion: nil)
//    }


    // MARK: - Test Graphs

    private class func makeVoronoiInputGraph() -> VertexWeightedGraph {
        var graph = VertexWeightedGraph()
        graph.insert("A", at: CGPoint(x: -100, y: 150), weight: 34)
        graph.insert("B", at: CGPoint(x: 0, y: 150), weight: 5)
        graph.insert("C", at: CGPoint(x: 100, y: 150), weight: 21)
        graph.insert("D", at: CGPoint(x: -150, y: 50), weight: 8)
        graph.insert("E", at: CGPoint(x: -50, y: 50), weight: 8)
        graph.insert("F", at: CGPoint(x: 50, y: 50), weight: 5)
        graph.insert("G", at: CGPoint(x: 150, y: 50), weight: 8)
        graph.insert("H", at: CGPoint(x: -100, y: -50), weight: 5)
        graph.insert("I", at: CGPoint(x: 0, y: -50), weight: 13)
        graph.insert("J", at: CGPoint(x: 100, y: -50), weight: 21)
        graph.insert("K", at: CGPoint(x: -50, y: -150), weight: 8)
        graph.insert("L", at: CGPoint(x: 50, y: -150), weight: 8)

        graph.insertEdge(between: "A", and: "B")
        graph.insertEdge(between: "B", and: "C")
        graph.insertEdge(between: "D", and: "E")
        graph.insertEdge(between: "E", and: "F")
        graph.insertEdge(between: "F", and: "G")
        graph.insertEdge(between: "H", and: "I")
        graph.insertEdge(between: "I", and: "J")
        graph.insertEdge(between: "K", and: "L")
        graph.insertEdge(between: "A", and: "D")
        graph.insertEdge(between: "A", and: "E")
        graph.insertEdge(between: "B", and: "E")
        graph.insertEdge(between: "B", and: "F")
        graph.insertEdge(between: "C", and: "F")
        graph.insertEdge(between: "C", and: "G")
        graph.insertEdge(between: "D", and: "H")
        graph.insertEdge(between: "E", and: "H")
        graph.insertEdge(between: "E", and: "I")
        graph.insertEdge(between: "F", and: "I")
        graph.insertEdge(between: "F", and: "J")
        graph.insertEdge(between: "G", and: "J")
        graph.insertEdge(between: "H", and: "K")
        graph.insertEdge(between: "I", and: "K")
        graph.insertEdge(between: "I", and: "L")
        graph.insertEdge(between: "J", and: "L")

        return graph
    }

    private class func makeSmallInputGraph() -> VertexWeightedGraph {
        var graph = VertexWeightedGraph()
        graph.insert("A", at: CGPoint(x: 0, y: 130), weight: 34)
        graph.insert("B", at: CGPoint(x: -75, y: 0), weight: 5)
        graph.insert("C", at: CGPoint(x: 75, y: 0), weight: 21)
        graph.insert("D", at: CGPoint(x: 0, y: -130), weight: 8)
        graph.insertEdge(between: "A", and: "B")
        graph.insertEdge(between: "A", and: "C")
        graph.insertEdge(between: "B", and: "C")
        graph.insertEdge(between: "B", and: "D")
        graph.insertEdge(between: "C", and: "D")

        graph.insert("E", at: CGPoint(x: 0, y: 50), weight: 13)
        graph.insertEdge(between: "E", and: "A")
        graph.insertEdge(between: "E", and: "B")
        graph.insertEdge(between: "E", and: "C")

        return graph
    }


    // MARK: - Rendering

    private var effectiveRenderingTransform: CGAffineTransform {
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: 0, y: bounds.height)
        transform = transform.scaledBy(x: 1, y: -1)
        transform = transform.translatedBy(x: bounds.width / 2, y: bounds.height / 2)
        transform = transform.scaledBy(x: 2, y: 2)

        return transform
    }

    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.white.cgColor)
        context.fill(rect)
        context.concatenate(self.effectiveRenderingTransform)
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

        for (vertex, force) in ForceComputer().forces(in: self.graph) {
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
