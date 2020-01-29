//
//  FaceTests.swift
//  MasterThesisTests
//
//  Created by Christian Schnorr on 29.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import XCTest

class FaceTests: XCTestCase {
    func testVertices() {
        let faces = [
            Face(vertices: [1,2,3,4]),
            Face(vertices: [2,3,4,1]),
            Face(vertices: [3,4,1,2]),
            Face(vertices: [4,1,2,3])
        ]

        for lhs in faces {
            for rhs in faces {
                XCTAssertEqual(lhs, rhs)

                for i in rhs.vertices.indices {
                    for j in rhs.vertices.indices where j != i {
                        var vertices = rhs.vertices
                        vertices.swapAt(i, j)

                        XCTAssertNotEqual(lhs, Face(vertices: vertices))
                    }
                }
            }
        }

        XCTAssertEqual(Set(faces).count, 1)
    }
}
