//
//  TestGraphs.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 23.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Framework

enum TestGraphs {
    static func makeVoronoiInputGraph() -> VertexWeightedGraph {
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

    static func makeSmallInputGraph() -> VertexWeightedGraph {
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
}
