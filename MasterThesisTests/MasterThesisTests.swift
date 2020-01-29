//
//  MasterThesisTests.swift
//  MasterThesisTests
//
//  Created by Christian Schnorr on 12.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import XCTest

class MasterThesisTests: XCTestCase {
    private let graph = MasterThesisTests.makeVertexWeightedGraph()

    private final class func makeVertexWeightedGraph() -> VertexWeightedGraph {
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

        return graph
    }

    func testVertices() {
        XCTAssertEqual(graph.vertices, ["A", "B", "C", "D"])
    }

    func testPositions() {
        XCTAssertEqual(graph.position(of: "A"), CGPoint(x: 0, y: 130))
        XCTAssertEqual(graph.position(of: "B"), CGPoint(x: -75, y: 0))
        XCTAssertEqual(graph.position(of: "C"), CGPoint(x: 75, y: 0))
        XCTAssertEqual(graph.position(of: "D"), CGPoint(x: 0, y: -130))
    }

    func testWeights() {
        XCTAssertEqual(graph.weight(of: "A"), 1)
        XCTAssertEqual(graph.weight(of: "B"), 2)
        XCTAssertEqual(graph.weight(of: "C"), 3)
        XCTAssertEqual(graph.weight(of: "D"), 4)
    }

    func testAdjacencies() {
        XCTAssertEqual(graph.vertices(adjacentTo: "A"), ["B", "C"])
        XCTAssertEqual(graph.vertices(adjacentTo: "B"), ["A", "C", "D"])
        XCTAssertEqual(graph.vertices(adjacentTo: "C"), ["A", "B", "D"])
        XCTAssertEqual(graph.vertices(adjacentTo: "D"), ["B", "C"])
    }

    func testInnerFaces() {
        XCTAssertEqual(graph.faces.inner, [["A", "B", "C"], ["B", "C", "D"]])
    }
}
