//
//  Pipeline+Weight.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 30.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics

extension VertexWeightedGraph {
    mutating func adjustWeight(of vertex: Vertex, to value: Weight) throws {
        guard self.vertices.contains(vertex) else { throw UnsupportedOperationError() }

        self.setWeight(of: vertex, to: value)
    }
}

// FIXME:
extension PolygonalDual {
    mutating func adjustWeight(of face: Face, to value: Weight) throws {
//        guard self.faces.contains(face) else { throw UnsupportedOperationError() }
//
//        self.setWeight(of: face, to: value)
    }
}
