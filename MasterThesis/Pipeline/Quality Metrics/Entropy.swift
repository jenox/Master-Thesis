//
//  EntropyOfAngles.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 24.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import CoreGraphics
import Geometry

struct EntropyOfAngles: QualityEvaluator {
    func quality(of face: PolygonalDual.FaceID, in graph: PolygonalDual) throws -> QualityValue {
        let polygon = graph.polygon(for: face).withEvenlyDistributedEdgeLengths()
        let angles = polygon.points.indices.map(polygon.normalAndAngle(at:)).map({ Angle(turns: 1) - $0.angle })

        return .double(angles.localAngleFactor())
    }
}

struct EntropyOfDistancesFromCentroid: QualityEvaluator {
    func quality(of face: PolygonalDual.FaceID, in graph: PolygonalDual) throws -> QualityValue {
        let polygon = graph.polygon(for: face).withEvenlyDistributedEdgeLengths()
        let centroid = CGPoint.centroid(of: polygon.points)
        let distances = polygon.points.map(centroid.distance(to:))

        return .double(distances.globalDistanceFactor())
    }
}

private extension Array where Element == Double {
    func cost(atNumberOfBuckets K: Int) -> Double {
        var ξ: [[Double]] = .init(repeating: [], count: K)
        for value in self {
            ξ[Swift.min(Int(value * Double(K)), K - 1)].append(value)
        }

        let pdf = ξ.map({ Double($0.count) / Double(self.count) })

        let H = -pdf.filter({ $0 != 0 }).map({ $0 * log($0) }).sum
        let H_max = log(Double(self.count))

        var e = 0.0
        for rs in ξ {
            let μ = rs.average
            for ri in rs {
                e += pow(ri - μ, 2)
            }
        }
        e = sqrt(e / Double(self.count))
        let e_max = 0.25

        return H / H_max + e / e_max
    }

    func costAtOptimalNumberOfBuckets() -> Double {
        precondition(self.allSatisfy({ 0 <= $0 && $0 <= 1 }))

        let J_max = Int(ceil(log2(Double(self.count))))

        // min 2 such that we can use e_max = 0.25
        return (2...Swift.max(2, J_max)).map({ self.cost(atNumberOfBuckets: 1 << $0) }).min()!
    }
}

private extension Array where Element == CGFloat {
    /// Closer to 0 is better.
    func globalDistanceFactor() -> Double {
        guard let max = self.max(), max > 0 else { return 0 }

        let normalized = self.map({ Double($0 / max) })

        return normalized.costAtOptimalNumberOfBuckets()
    }
}

private extension Array where Element == Angle {
    /// Closer to 0 is better.
    func localAngleFactor() -> Double {
        guard !self.isEmpty else { return 0 }

        let normalized = self.map({ Double(Swift.min($0, Angle(turns: 1) - $0) / Angle(turns: 0.5)) })

        return normalized.costAtOptimalNumberOfBuckets()
    }
}

private extension Collection where Element == Double {
    var sum: Double {
        return self.reduce(0, +)
    }

    var average: Double {
        return self.reduce(0, +) / Double(self.count)
    }
}

private extension Polygon {
    func withEvenlyDistributedEdgeLengths() -> Polygon {
        let epsilon = 1 as CGFloat
        let segments = self.points.adjacentPairs(wraparound: true).map(Segment.init)
        let lengths = segments.map(\.length)
        let minimum = max(epsilon, lengths.min()!)

        var points: [CGPoint] = []
        for segment in segments {
            guard segment.length >= epsilon else { points.append(segment.start); continue }

            let factor = segment.length / minimum
            let error1 = minimum / (segment.length / ceil(factor)) - 1
            let error2 = (segment.length / floor(factor)) / minimum - 1
            precondition(error1 >= 0 && error2 >= 0)
            let count = error1 < error2 ? Int(ceil(factor)) : Int(floor(factor))

            for index in 0..<count {
                points.append(segment.point(at: CGFloat(index) / CGFloat(count)))
            }
        }

        return Polygon(points: points)
    }
}
