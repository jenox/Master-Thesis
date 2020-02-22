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

            let polygon = Polygon(points: face.vertices.map(graph.position(of:)))

            for (index, vertex) in face.vertices.enumerated() {
                let (normal, angle) = polygon.normalAndAngle(at: index)

                if pressure >= 1 {
                    forces[vertex]! += CGFloat(log(pressure)) * pow((360 - angle.degrees) / 180, 1) * normal
                } else {
                    forces[vertex]! += CGFloat(log(pressure)) * pow(angle.degrees / 180, 1) * normal
                }
            }
        }

        for face in graph.faces {
            for (index, vertex) in face.vertices.enumerated() {
                switch vertex {
                case .subdivision1, .subdivision2, .subdivision3:
                    let (left, right) = face.neighbors(of: vertex)
                    let pos = graph.position(of: vertex)
                    let pos1 = graph.position(of: left)
                    let pos2 = graph.position(of: right)

                    let polygon = Polygon(points: face.vertices.map(graph.position(of:)))
                    let vector = polygon.normal(at: index).rotated(by: .init(degrees: 90))

                    forces[vertex]! += 5 * log(pos.distance(to: pos1) / pos.distance(to: pos2)) * vector
                default:
                    break
                }
            }
        }

        return forces
    }
}
