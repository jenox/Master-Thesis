//
//  ForceApplicator.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 22.02.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics

class ForceApplicator {
    func apply(_ forces: [FaceWeightedGraph.Vertex: CGVector], to graph: inout FaceWeightedGraph) {
        let edges = graph.edges.map({ Segment(a: graph.position(of: $0.0), b: graph.position(of: $0.1)) })
        let positions = graph.vertices.map(graph.position(of:))

        for (vertex, var force) in forces {
            let position = graph.position(of: vertex)
            var mindist = edges.filter({ $0.a != position && $0.b != position }).map(position.distance(to:)).min()!
            mindist = min(mindist, positions.filter({ $0 != position }).map(position.distance(to:)).min()!)

            // FIXME: this still crashes?!
            if force.length > 0.45 * mindist {
//                print("clamping")
                force = 0.45 * mindist * force.normalized
            }

            graph.setPosition(graph.position(of: vertex) + force, of: vertex)
        }
    }
}
