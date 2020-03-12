//
//  ForceComputer.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 22.02.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics

class ForceComputer {
    func forces(in graph: FaceWeightedGraph) -> [FaceWeightedGraph.Vertex: CGVector] {
        var forces: [FaceWeightedGraph.Vertex: CGVector] = [:]
        for vertex in graph.vertices {
            forces[vertex] = .zero
        }

        let totalweight = graph.faces.map(graph.weight(of:)).reduce(0, +)
        let totalarea = graph.faces.map(graph.area(of:)).reduce(0, +)

        for face in graph.faces {
            let weight = graph.weight(of: face)
            let area = graph.area(of: face)
            let pressure = (weight / totalweight) / (area / totalarea)
            let polygon = graph.polygon(for: face)

            for (index, vertex) in graph.boundary(of: face).enumerated() {
                let (normal, angle) = polygon.normalAndAngle(at: index)

                if pressure >= 1 {
                    forces[vertex]! += CGFloat(log(pressure)) * pow((360 - angle.degrees) / 180, 1) * normal
                } else {
                    forces[vertex]! += CGFloat(log(pressure)) * pow(angle.degrees / 180, 1) * normal
                }
            }
        }

        for face in graph.faces {
            let boundary = graph.boundary(of: face)
            for (index, vertex) in boundary.enumerated() {
                if graph.vertices(adjacentTo: vertex).count == 2 {
                    let (left, right) = Face(vertices: boundary).neighbors(of: vertex)
                    let pos = graph.position(of: vertex)
                    let pos1 = graph.position(of: left)
                    let pos2 = graph.position(of: right)

                    let polygon = graph.polygon(for: face)
                    let vector = polygon.normal(at: index).rotated(by: .init(degrees: 90))

                    forces[vertex]! += 5 * log(pos.distance(to: pos1) / pos.distance(to: pos2)) * vector
                }
            }
        }

        return forces
    }
}