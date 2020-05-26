//
//  DelaunayGraphGenerator.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 23.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry
import Delaunay

public struct DelaunayGraphGenerator: GraphGenerator {
    private static let countries: OrderedSet<ClusterName> = OrderedSet(Array("ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÄÆÃÅĀÈÉÊÊĒĖĘEÎÏÍĪĮÌÔÖÒÓŒØŌÕÛÜÙÚŪ").map(ClusterName.init))

    public init(numberOfCountries: Int, nestingRatio: Double, nestingBias: Double) {
        self.numberOfCountries = numberOfCountries
        self.bounds = CGRect(x: -256, y: -256, width: 512, height: 512)
        self.nestingRatio = nestingRatio
        self.nestingBias = nestingBias
        self.weights = 1...50
    }

    let numberOfCountries: Int
    let bounds: CGRect
    let nestingRatio: Double
    let nestingBias: Double
    let weights: ClosedRange<ClusterWeight>

    public func generateRandomWeight<T>(using generator: inout T) -> ClusterWeight where T : RandomNumberGenerator {
        return .init(rawValue: .random(in: self.weights.lowerBound.rawValue...self.weights.upperBound.rawValue, using: &generator))
    }

    public func generateRandomGraph<T>(using generator: inout T) throws -> VertexWeightedGraph where T: RandomNumberGenerator {
        precondition(self.numberOfCountries >= 3)

        var graph = VertexWeightedGraph()
        var vertices: [HashablePoint: ClusterName] = [:]

        let numberOfTopLevelCountries = max(3, Int(round((1 - self.nestingRatio) * Double(self.numberOfCountries))))

        // Create n - k top level points
        for country in Self.countries.prefix(numberOfTopLevelCountries) {
            let weight = self.generateRandomWeight(using: &generator)
            let position = self.randomPoint(existing: vertices.keys.map(\.point), using: &generator)

            let oldValue = vertices.updateValue(country, forKey: .init(point: position))
            assert(oldValue == nil)

            graph.insert(country, at: position, weight: weight)
        }

        // Triangulate
        let triangles = Delaunay().triangulate(vertices.keys.map(\.point).map(Vertex.init))
        for triangle in triangles {
            let v1 = vertices[.init(point: triangle.v1())]!
            let v2 = vertices[.init(point: triangle.v2())]!
            let v3 = vertices[.init(point: triangle.v3())]!

            for (u, v) in [(v1, v2), (v2, v3), (v3, v1)] {
                if !graph.containsEdge(between: u, and: v) {
                    graph.insertEdge(between: u, and: v)
                }
            }
        }

        // Nest remaining k vertices into existing triangles
        var trianglesByDepth: [Int: [Triangle]] = [0: triangles]
        for country in Self.countries.prefix(self.numberOfCountries).dropFirst(numberOfTopLevelCountries) {
            let depths = trianglesByDepth.compactMap({ $0.value.isEmpty ? nil : $0.key })
            let depth = depths.randomElement(weightedBy: { 1 / pow(1 - self.nestingBias, Double($0)) }, using: &generator)!
            let index = trianglesByDepth[depth]!.indices.randomElement(using: &generator)!
            let triangle = trianglesByDepth[depth]!.remove(at: index)

            let a = triangle.v1()
            let b = triangle.v2()
            let c = triangle.v3()
            let x = CGPoint.random(in: triangle, using: &generator)

            trianglesByDepth[depth + 1, default: []].append(contentsOf: [
                Triangle(a, b, x),
                Triangle(b, c, x),
                Triangle(c, a, x)
            ])

            graph.insert(country, at: x, weight: self.generateRandomWeight(using: &generator))
            vertices[.init(point: x)] = country
            graph.insertEdge(between: vertices[.init(point: a)]!, and: country)
            graph.insertEdge(between: vertices[.init(point: b)]!, and: country)
            graph.insertEdge(between: vertices[.init(point: c)]!, and: country)
        }

        return graph
    }

    private func randomPoint<T>(existing: [CGPoint], using generator: inout T) -> CGPoint where T: RandomNumberGenerator {
        return CGPoint.random(in: self.bounds, using: &generator)
    }
}

private extension Vertex {
    init(_ point: CGPoint) {
        self = Vertex(x: Double(point.x), y: Double(point.y))
    }
}

private extension Triangle {
    init(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) {
        self = Triangle(vertex1: .init(p1), vertex2: .init(p2), vertex3: .init(p3))
    }

    var centroid: CGPoint {
        return CGPoint.centroid(of: self.v1(), self.v2(), self.v3())
    }
}

private extension BidirectionalCollection {
    func randomElement<T>(weightedBy weight: (Element) -> Double, using generator: inout T) -> Element? where T: RandomNumberGenerator {
        let weights = self.map(weight)
        let sum = weights.reduce(0, +)
        var value = Double.random(in: 0..<sum, using: &generator)

        for (element, weight) in zip(self, weights) {
            if weight >= value {
                value -= weight
            } else {
                return element
            }
        }

        return self.last
    }
}

private extension CGPoint {
    static func random<T>(in bounds: CGRect, using generator: inout T) -> CGPoint where T: RandomNumberGenerator {
        let x = CGFloat.random(in: bounds.minX...bounds.maxX, using: &generator)
        let y = CGFloat.random(in: bounds.minY...bounds.maxY, using: &generator)

        return CGPoint(x: x, y: y)
    }

    static func random<T>(in triangle: Triangle, using generator: inout T) -> CGPoint where T: RandomNumberGenerator {
        while true {
            let a = CGFloat.random(in: 0.1...0.9, using: &generator)
            let b = CGFloat.random(in: 0.1...0.9, using: &generator)
            guard a + b <= 0.9 else { continue }

            return triangle.v1() + a * CGVector(from: triangle.v1(), to: triangle.v2()) + b * CGVector(from: triangle.v1(), to: triangle.v3())
        }
    }
}

struct HashablePoint: Hashable {
    var point: CGPoint

    func hash(into hasher: inout Hasher) {
        self.point.x.hash(into: &hasher)
        self.point.y.hash(into: &hasher)
    }
}
