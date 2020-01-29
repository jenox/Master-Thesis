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
        // TODO: Try with larger voronoi triangulations or low triangle nestings (K4s)

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
        context.scaleBy(x: 1.5, y: 1.5)
        context.setLineWidth(0.5)

        let vertices = graph.vertices
        let edges = graph.edges
        let (faces, outerFace) = graph.faces

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
                context.fill(graph.position(of: vertex), diameter: 5, color: .blue)
                context.translateBy(x: graph.position(of: vertex).x, y: graph.position(of: vertex).y)
                context.scaleBy(x: 1, y: -1)
                NSString(string: String(vertex)).draw(at: .zero, withAttributes: [:])
                context.scaleBy(x: 1, y: -1)
                context.translateBy(x: -graph.position(of: vertex).x, y: -graph.position(of: vertex).y)
            }
        }

        context.translateBy(x: 200, y: 0)
        do {
            for (endpoint1, endpoint2) in edges {
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

        context.translateBy(x: 200, y: 0)
        do {
            var dual = FaceWeightedGraph()

            for face in faces {
                let centroid = face.vertices.map(graph.position(of:)).centroid

                // internal face vertex
                dual.insert(.internalFace(face), at: centroid)
            }

            for (endpoint1, endpoint2) in edges {
                let adjacentFaces = faces.filter({ $0.containsEdge(between: endpoint1, and: endpoint2) })
                if adjacentFaces.count == 2 {
                    // add edge between adjacent face vertices
                    dual.insertEdge(between: .internalFace(adjacentFaces[0]), and: .internalFace(adjacentFaces[1]))
                } else {
                    let position1 = graph.position(of: endpoint1)
                    let position2 = graph.position(of: endpoint2)
                    let centroid = [position1, position2].centroid

                    // outer edge vertex
                    dual.insert(.outerEdge(UndirectedEdge(first: endpoint1, second: endpoint2)), at: centroid)

                    // add edge to face vertex
                    dual.insertEdge(between: .outerEdge(UndirectedEdge(first: endpoint1, second: endpoint2)), and: .internalFace(adjacentFaces[0]))
                }
            }

            let outerEdges = Array(outerFace.vertices.makeAdjacentPairIterator())
            for (edge1, edge2) in outerEdges.makeAdjacentPairIterator() {
                dual.insertEdge(between: .outerEdge(UndirectedEdge(first: edge1.0, second: edge1.1)), and: .outerEdge(UndirectedEdge(first: edge2.0, second: edge2.1)))
            }

            for vertex in vertices {
                var edges = graph.vertices(adjacentTo: vertex).map({ DirectedEdge(from: vertex, to: $0) })
                edges.sort(by: { graph.angle(of: $0) < graph.angle(of: $1) })
                let endpoints = edges.map({ $0.target })

                var things: [FaceWeightedGraph.Vertex] = []
                for (x, y) in endpoints.makeAdjacentPairIterator() {
                    // area check required for triangles with 2 edges on outer face
                    let face = Face(vertices: [vertex, x, y])
                    if graph.vertices(adjacentTo: x).contains(y), graph.area(of: face) > 0 {
                        things.append(.internalFace(face))
                    } else {
                        things.append(.outerEdge(UndirectedEdge(first: vertex, second: x)))
                        things.append(.outerEdge(UndirectedEdge(first: vertex, second: y)))
                    }
                }

                dual.register(face: Face(vertices: things))
            }

            for (endpoint1, endpoint2) in dual.edges {
                context.stroke(from: dual.position(of: endpoint1), to: dual.position(of: endpoint2), color: .black)
            }

            for vertex in dual.vertices {
                context.fill(dual.position(of: vertex), diameter: 5, color: .blue)
            }

            for face in dual.faces {
                print("Face:", face)
            }

            // TODO: do we guarantee planarity when connecting barycenter to midpoint of edges?
            // https://en.wikipedia.org/wiki/Centroid#/media/File:Triangle.Centroid.svg
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
