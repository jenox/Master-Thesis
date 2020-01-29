//
//  Transformation.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 29.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Foundation

extension VertexWeightedGraph {
    // TODO: do we guarantee planarity when connecting barycenter to midpoint of edges?
    // https://en.wikipedia.org/wiki/Centroid#/media/File:Triangle.Centroid.svg
    // Also, what about A-E edge in example? how would it work when AEC triangle is very long? do we get intersections / wrong topology?
    func subdividedDual() -> FaceWeightedGraph {
        let vertices = self.vertices
        let edges = self.edges
        let (faces, outerFace) = self.faces

        var dual = FaceWeightedGraph()

        for face in faces {
            let centroid = face.vertices.map(self.position(of:)).centroid

            // internal face vertex
            dual.insert(.internalFace(face), at: centroid)
        }

        for (endpoint1, endpoint2) in edges {
            let adjacentFaces = faces.filter({ $0.containsEdge(between: endpoint1, and: endpoint2) })
            if adjacentFaces.count == 2 {
                let helper = FaceWeightedGraph.Vertex.subdivision1(UUID())
                dual.insert(helper, at: [self.position(of: endpoint1), self.position(of: endpoint2)].centroid)

                // add edge between adjacent face vertices
                dual.insertEdge(between: .internalFace(adjacentFaces[0]), and: helper)
                dual.insertEdge(between: helper, and: .internalFace(adjacentFaces[1]))
            } else {
                let position1 = self.position(of: endpoint1)
                let position2 = self.position(of: endpoint2)
                let centroid = [position1, position2].centroid

                // outer edge vertex
                dual.insert(.outerEdge(UndirectedEdge(first: endpoint1, second: endpoint2)), at: centroid)

                let helper = FaceWeightedGraph.Vertex.subdivision2(UUID())
                dual.insert(helper, at: [centroid, adjacentFaces[0].vertices.map(self.position(of:)).centroid].centroid)

                // add edge to face vertex
                dual.insertEdge(between: .outerEdge(UndirectedEdge(first: endpoint1, second: endpoint2)), and: helper)
                dual.insertEdge(between: helper, and: .internalFace(adjacentFaces[0]))
            }
        }

        let outerEdges = Array(outerFace.vertices.makeAdjacentPairIterator())
        for (edge1, edge2) in outerEdges.makeAdjacentPairIterator() {
            precondition(edge1.1 == edge2.0)
            let helper = FaceWeightedGraph.Vertex.subdivision3(UUID())
            let position = self.position(of: edge1.1)

            dual.insert(helper, at: position)
            dual.insertEdge(between: .outerEdge(UndirectedEdge(first: edge1.0, second: edge1.1)), and: helper)
            dual.insertEdge(between: helper, and: .outerEdge(UndirectedEdge(first: edge2.0, second: edge2.1)))
        }

        for vertex in vertices {
            var edges = self.vertices(adjacentTo: vertex).map({ DirectedEdge(from: vertex, to: $0) })
            edges.sort(by: { self.angle(of: $0) < self.angle(of: $1) })
            let endpoints = edges.map({ $0.target })

            var things: [FaceWeightedGraph.Vertex] = []
            for (x, y) in endpoints.makeAdjacentPairIterator() {
                // area check required for triangles with 2 edges on outer face
                let face = Face(vertices: [vertex, x, y])
                if self.vertices(adjacentTo: x).contains(y), self.area(of: face) > 0 {
                    things.append(.internalFace(face))
                } else {
                    things.append(.outerEdge(UndirectedEdge(first: vertex, second: x)))
                    things.append(.outerEdge(UndirectedEdge(first: vertex, second: y)))
                }
            }

            for index in things.indices.reversed() {
                let a = things[index]
                let b = things[(index + 1) % things.count]
                let x = Set(dual.adjacencies[a]!).intersection(dual.adjacencies[b]!)
                assert(x.count == 1)
                things.insert(x.first!, at: index + 1)
            }

            dual.registerFace(Face(vertices: things), named: vertex, weight: self.weight(of: vertex))
        }

        return dual
    }
}
