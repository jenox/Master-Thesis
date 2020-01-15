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
    override func draw(_ rect: CGRect) {
        var graph = VertexWeightedGraph()
        graph.insert("A", at: CGPoint(x: 0, y: 130), weight: 1)
        graph.insert("B", at: CGPoint(x: -75, y: 0), weight: 2)
        graph.insert("C", at: CGPoint(x: 75, y: 0), weight: 3)
        graph.insert("D", at: CGPoint(x: 0, y: -130), weight: 4)
        graph.insertEdge(between: "A", and: "B")
        graph.insertEdge(between: "A", and: "C")
        graph.insertEdge(between: "B", and: "C")
        graph.insertEdge(between: "B", and: "D")
        graph.insertEdge(between: "C", and: "D")

        graph.insert("E", at: CGPoint(x: 0, y: 50), weight: 5)
        graph.insertEdge(between: "E", and: "A")
        graph.insertEdge(between: "E", and: "B")
        graph.insertEdge(between: "E", and: "C")

        graph.insert("F", at: CGPoint(x: -100, y: 130), weight: 6)
        graph.insertEdge(between: "F", and: "A")
        graph.insertEdge(between: "F", and: "B")

        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.white.cgColor)
        context.fill(rect)

        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: bounds.width / 2, y: bounds.height / 2)

        let vertices = graph.vertices
        let edges = graph.edges
        let faces = graph.innerFaces

        context.translateBy(x: -200, y: 0)
        do {
            for (endpoint1, endpoint2) in edges {
                context.stroke(
                    from: graph.position(of: endpoint1),
                    to: graph.position(of: endpoint2),
                    color: .black
                )
            }

            for vertex in vertices {
                context.fill(graph.position(of: vertex), diameter: 10, color: .blue)
            }
        }

        context.translateBy(x: 400, y: 0)
        do {
            for (endpoint1, endpoint2) in edges {
                let faces = faces.filter({ $0.contains(endpoint1) && $0.contains(endpoint2) }) as Array

                if faces.count == 2 {
                    let centroid1 = faces[0].map(graph.position(of:)).centroid
                    let centroid2 = faces[1].map(graph.position(of:)).centroid
                    let mid = [centroid1, centroid2].centroid

                    context.stroke(from: mid, to: centroid1, color: .red)
                    context.stroke(from: mid, to: centroid2, color: .red)
                    context.fill(mid, diameter: 10, color: .green)
                } else {
                    let position1 = graph.position(of: endpoint1)
                    let position2 = graph.position(of: endpoint2)
                    let centroid = faces[0].map(graph.position(of:)).centroid
                    // results in 'degenerate' drawing but guarantees we don't introduce weird crossings
                    let target = [position1, position2].centroid

                    context.stroke(from: centroid, to: target, color: .red)
                    context.stroke(from: target, to: position1, color: .red)
                    context.stroke(from: target, to: position2, color: .red)
                    context.fill(target, diameter: 10, color: .green)
                    context.fill(position1, diameter: 10, color: .green) // we fill those twice...
                    context.fill(position2, diameter: 10, color: .green) // we fill those twice...
                }
            }

            for face in faces {
                let positions = face.map(graph.position(of:))
                context.fill(positions.centroid, diameter: 10, color: .green)
            }
        }
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
