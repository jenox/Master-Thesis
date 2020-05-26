//
//  Pipeline+Weight.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 30.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics

extension VertexWeightedGraph {
    public mutating func adjustWeight(of vertex: ClusterName, to value: ClusterWeight) throws {
        guard self.vertices.contains(vertex) else { throw UnsupportedOperationError() }

        self.setWeight(of: vertex, to: value)
    }
}

extension PolygonalDual {
    public mutating func adjustWeight(of face: ClusterName, to value: ClusterWeight) throws {
        guard self.faces.contains(face) else { throw UnsupportedOperationError() }

        self.setWeight(of: face, to: value)
    }
}
