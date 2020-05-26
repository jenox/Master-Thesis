//
//  GraphProtocol.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 31.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry

internal protocol StraightLineGraph: PlanarGraph {
    func position(of vertex: Vertex) -> CGPoint
    mutating func move(_ vertex: Vertex, to position: CGPoint)
}

extension StraightLineGraph {
    mutating func displace(_ vertex: Vertex, by displacement: CGVector) {
        self.move(vertex, to: self.position(of: vertex) + displacement)
    }

    func segment(from u: Vertex, to v: Vertex) -> Segment {
        return Segment(from: self.position(of: u), to: self.position(of: v))
    }

    func vector(from u: Vertex, to v: Vertex) -> CGVector {
        return CGVector(from: self.position(of: u), to: self.position(of: v))
    }

    func vector(from u: Vertex, to point: CGPoint) -> CGVector {
        return CGVector(from: self.position(of: u), to: point)
    }

    func distance(from u: Vertex, to v: Vertex) -> CGFloat {
        return self.vector(from: u, to: v).length
    }

    func polygon(on vertices: [Vertex]) -> Polygon {
        return Polygon(points: vertices.map(self.position(of:)))
    }

    func angle(from u: Vertex, to v: Vertex) -> Angle {
        let vector = self.vector(from: u, to: v)
        return Angle.atan2(vector.dy, vector.dx)
    }

    func angle(from u: Vertex, via v: Vertex, to w: Vertex) -> Angle {
        return Angle(from: self.position(of: u), by: self.position(of: v), to: self.position(of: w))
    }

    func internalFacesAndOuterFace() -> (internal: [Face<Vertex>], outer: Face<Vertex>) {
        var faces = self.allFaces()
        let index = faces.partition(by: { self.polygon(on: $0.vertices).area >= 0 })
        precondition(index == 1)
        return (internal: Array(faces.dropFirst()), outer: faces[0])
    }
}
