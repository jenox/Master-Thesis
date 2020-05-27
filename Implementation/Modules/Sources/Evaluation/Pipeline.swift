//
//  Pipeline.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 25.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Foundation
import Framework

struct Pipeline {
    init(seed: UInt64, generator: DelaunayGraphGenerator) {
        self.seed = seed
        self.generator = generator
        self.randomNumberGenerator = .init(seed: seed)
        self.vertexWeightedGraph = try! generator.generateRandomGraph(using: &self.randomNumberGenerator)
        self.polygonalDual = nil
    }

    private let seed: UInt64
    private let generator: DelaunayGraphGenerator

    // Double optionals over enum to prevent COW
    private var vertexWeightedGraph: VertexWeightedGraph?
    private var polygonalDual: PolygonalDual?

    private let transformer: Transformer = NaiveTransformer()
    private let forceApplicator: ForceApplicator = PrEdForceApplicator()
    private var randomNumberGenerator: Xoroshiro128PlusRandomNumberGenerator

    func numberOfOperations(multiplier: Int) -> Int {
        if let graph = self.vertexWeightedGraph {
            return multiplier * graph.vertices.count
        } else if let graph = self.polygonalDual {
            return multiplier * graph.faces.count
        } else {
            fatalError()
        }
    }

    var data: Data {
        if let graph = self.vertexWeightedGraph {
            return try! JSONEncoder().encode(graph)
        } else if let graph = self.polygonalDual {
            return try! JSONEncoder().encode(graph)
        } else {
            fatalError()
        }
    }

    mutating func transform() {
        self.polygonalDual = try! self.transformer.transform(self.vertexWeightedGraph!)
        self.vertexWeightedGraph = nil
    }

    mutating func save(to url: URL) {
        if let graph = self.vertexWeightedGraph {
            try! JSONEncoder().encode(graph).write(to: url)
        } else if let graph = self.polygonalDual {
            try! JSONEncoder().encode(graph).write(to: url)
        } else {
            fatalError()
        }
    }

    mutating func step() {
        if self.vertexWeightedGraph != nil {
            try! self.forceApplicator.applyForces(to: &self.vertexWeightedGraph!)
        } else if self.polygonalDual != nil {
            try! self.polygonalDual!.willStepOnce()
            try! self.forceApplicator.applyForces(to: &self.polygonalDual!)
            try! self.polygonalDual!.didStepOnce()
        } else {
            fatalError()
        }
    }

    mutating func applyRandomOperation() {
        self.polygonalDual!.applyRandomOperation(using: self.generator, prng: &self.randomNumberGenerator)
    }
}

private extension PolygonalDual {
    mutating func applyRandomOperation<T>(using generator: DelaunayGraphGenerator, prng: inout T) where T: RandomNumberGenerator {
        for face in self.faces {
            let generated = generator.generateRandomWeight(using: &prng)
            let weight = 0.75 * self.weight(of: face) + 0.25 * generated

            try! self.adjustWeight(of: face, to: weight)
        }

        let possibleNames = "ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÄÆÃÅĀÈÉÊÊĒĖĘEÎÏÍĪĮÌÔÖÒÓŒØŌÕÛÜÙÚŪ".map(ClusterName.init)
        let name = possibleNames.first(where: { !self.faces.contains($0) })!
        let weight = generator.generateRandomWeight(using: &prng)
        let operation = self.randomDynamicOperation(name: name, weight: weight, using: &prng)

        try! self.apply(operation)
    }
}
