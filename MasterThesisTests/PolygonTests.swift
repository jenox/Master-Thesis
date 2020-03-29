//
//  PolygonTests.swift
//  MasterThesisTests
//
//  Created by Christian Schnorr on 11.02.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import XCTest
import CoreGraphics
import Geometry

class PolygonTests: XCTestCase {
    func testNormals() {
        let polygon = Polygon(points: [CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 0), CGPoint(x: 20, y: 0), CGPoint(x: 15, y: 20), CGPoint(x: 10, y: 10), CGPoint(x: 5, y: 15)])

        XCTAssertNormal(polygon.normalAndAngle(at: 0).normal, inDirection: CGVector(dx: -5.5, dy: -4))
        XCTAssertNormal(polygon.normalAndAngle(at: 1).normal, inDirection: CGVector(dx: 0, dy: -1))
        XCTAssertNormal(polygon.normalAndAngle(at: 2).normal, inDirection: CGVector(dx: 4.5, dy: -3.5))
        XCTAssertNormal(polygon.normalAndAngle(at: 3).normal, inDirection: CGVector(dx: 0.5, dy: 5))
        XCTAssertNormal(polygon.normalAndAngle(at: 4).normal, inDirection: CGVector(dx: -1, dy: 6.25))
        XCTAssertNormal(polygon.normalAndAngle(at: 5).normal, inDirection: CGVector(dx: -1.5, dy: 6))
    }
}

func XCTAssertNormal(_ vector: CGVector, inDirection direction: CGVector, file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(hypot(vector.dx, vector.dy), 1.0, accuracy: 1e-6, "length", file: file, line: line)
    XCTAssertEqual(dot(vector.normalized, direction.normalized), 1.0, accuracy: 1e-3, "direction", file: file, line: line)
}
