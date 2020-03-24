//
//  Transformation.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 29.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Foundation
import CoreGraphics

struct NaiveTransformer: Transformer {
    func transform(_ graph: VertexWeightedGraph) throws -> FaceWeightedGraph {
        return graph.subdividedDual()
    }
}

private extension VertexWeightedGraph {
    func subdividedDual() -> FaceWeightedGraph {
        let (faces, outerFace) = self.faces

        var graph = FaceWeightedGraph()

        var faceVertices: [Face<VertexWeightedGraph.Vertex>: FaceWeightedGraph.Vertex] = [:]
        var outerEdgeVertices: [UndirectedEdge: FaceWeightedGraph.Vertex] = [:]
        var adjacentFaces: [UndirectedEdge: [Face<VertexWeightedGraph.Vertex>]] = [:]

        // for `f` in G.innerFaces
        for face in faces {
            let barycenter = CGPoint.centroid(of: face.vertices.map(self.position(of:)))

            // add "face" vertex `f` at barycenter of `f`
            let x = graph.insertVertex(at: barycenter)

            faceVertices[face] = x
            for (u, v) in face.vertices.makeAdjacentPairIterator() {
                adjacentFaces[UndirectedEdge(first: u, second: v), default: []].append(face)
            }
        }

        // for `{u,v}` in G.edges
        for (u, v) in self.edges {
            let midpoint = CGPoint.centroid(of: [u, v].map(self.position(of:)))
            let adjacentFaces = adjacentFaces[UndirectedEdge(first: u, second: v)]!

            // if `{u,v}` adjacent to 2 faces `f ≠ g`
            if adjacentFaces.count == 2 {
                // add subdivion vertex `x` at midpoint of `{u,v}`
                let x = graph.insertVertex(at: midpoint)

                // add edge between `f` and `x`
                graph.insertEdge(between: faceVertices[adjacentFaces[0]]!, and: x)

                // add edge between `x` and `g`
                graph.insertEdge(between: x, and: faceVertices[adjacentFaces[1]]!)
            }

            // elseif `{u,v}` adjacent to single face `f`
            else if adjacentFaces.count == 1 {
                let barycenter = CGPoint.centroid(of: adjacentFaces[0].vertices.map(self.position(of:)))

                // add "outer edge" vertex `{u,v}` at midpoint of `{u,v}`
                let uv = graph.insertVertex(at: midpoint)

                // add subdivion vertex `x` at midpoint of midpoint of `{u,v}` and barycenter of `f`
                let x = graph.insertVertex(at: .centroid(of: midpoint, barycenter))

                // add edge between `{u,v}` and `x`
                graph.insertEdge(between: uv, and: x)

                // add edge between `x` and `f`
                graph.insertEdge(between: x, and: faceVertices[adjacentFaces[0]]!)

                outerEdgeVertices[UndirectedEdge(first: u, second: v)] = uv
            } else {
                fatalError()
            }
        }

        // for `({u,v}, {v,w})` in incident edges of G.outerFace
        for ((u, v), (_, w)) in Array(outerFace.vertices.makeAdjacentPairIterator()).makeAdjacentPairIterator() {

            // add subdivion vertex `x` at position of `v`
            let x = graph.insertVertex(at: self.position(of: v))

            // add edge between `{u,v}` and `x`
            graph.insertEdge(between: outerEdgeVertices[UndirectedEdge(first: u, second: v)]!, and: x)

            // add edge between `x` and `{v,w}`
            graph.insertEdge(between: x, and: outerEdgeVertices[UndirectedEdge(first: v, second: w)]!)
        }

        // Determine and register faces on computed dual graph
        for vertex in self.vertices {
            let endpoints = self.vertices(adjacentTo: vertex).sorted(by: { self.angle(of: DirectedEdge(from: vertex, to: $0)) })
            var vertices: [FaceWeightedGraph.Vertex] = []

            for (x, y) in endpoints.makeAdjacentPairIterator() {
                let face = Face(vertices: [vertex, x, y])

                // For triangles with two edges on outer face we must check orientation!
                if self.vertices(adjacentTo: x).contains(y), Polygon(points: face.vertices.map(self.position(of:))).area > 0 {
                    vertices.append(faceVertices[face]!)
                } else {
                    // add both outer edge vertices
                    vertices.append(outerEdgeVertices[UndirectedEdge(first: vertex, second: x)]!)
                    vertices.append(outerEdgeVertices[UndirectedEdge(first: vertex, second: y)]!)
                }
            }

            for (index, (u, v)) in vertices.makeAdjacentPairIterator().enumerated().reversed() {
                let x = graph.vertex(adjacentTo: u, and: v)!
                vertices.insert(x, at: index + 1)
            }

            graph.defineFace(named: "\(vertex)", boundedBy: vertices, weight: self.weight(of: vertex))
        }

        return graph
    }
}

private extension Collection {
    func sorted<T>(by transform: (Element) throws -> T) rethrows -> [Element] where T: Comparable {
        return try self.map({ ($0, try transform($0)) }).sorted(by: { $0.1 < $1.1 }).map({ $0.0 })
    }
}
