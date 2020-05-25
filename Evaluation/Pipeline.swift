//
//  Pipeline.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 25.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Foundation

struct Pipeline {
    init(seed: UInt64, generator: DelaunayGraphGenerator) {
        self.seed = seed
        self.generator = generator
        self.randomNumberGenerator = .init(seed: seed)
        self.state = .vertexWeighted(try! generator.generateRandomGraph(using: &self.randomNumberGenerator))
    }

    private let seed: UInt64
    private let generator: DelaunayGraphGenerator
    private var state: EitherGraph

    private let transformer: Transformer = NaiveTransformer()
    private let forceComputer: ForceComputer = ConcreteForceComputer()
    private let forceApplicator: ForceApplicator = PrEdForceApplicator()
    private var randomNumberGenerator: Xoroshiro128PlusRandomNumberGenerator

    var data: Data {
        switch self.state {
        case .vertexWeighted(let graph):
            return try! JSONEncoder().encode(graph)
        case .faceWeighted(let graph):
            return try! JSONEncoder().encode(graph)
        }
    }

    mutating func transform() {
        let untransformed = self.state.vertexWeightedGraph!
        let transformed = try! self.transformer.transform(untransformed)

        self.state = .faceWeighted(transformed)
    }

    mutating func save(to url: URL) {
        switch self.state {
        case .vertexWeighted(let graph):
            try! JSONEncoder().encode(graph).write(to: url)
        case .faceWeighted(let graph):
            try! JSONEncoder().encode(graph).write(to: url)
        }
    }

    mutating func step() {
        switch self.state {
        case .vertexWeighted(var graph):
            let forces = try! self.forceComputer.forces(in: graph)
            try! self.forceApplicator.apply(forces, to: &graph)
            self.state = .vertexWeighted(graph)
        case .faceWeighted(var graph):
            try! graph.willStepOnce()
            let forces = try! self.forceComputer.forces(in: graph)
            try! self.forceApplicator.apply(forces, to: &graph)
            try! graph.didStepOnce()
            self.state = .faceWeighted(graph)
        }
    }

    mutating func applyRandomOperation() {
        var graph = self.state.faceWeightedGraph!

        for face in graph.faces {
            let generated = self.generator.generateRandomWeight(using: &self.randomNumberGenerator)
            let weight = 0.75 * graph.weight(of: face) + 0.25 * generated

            graph.setWeight(of: face, to: weight)
        }

        let possibleNames = "ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÄÆÃÅĀÈÉÊÊĒĖĘEÎÏÍĪĮÌÔÖÒÓŒØŌÕÛÜÙÚŪ".map(ClusterName.init)
        let name = possibleNames.first(where: { !graph.faces.contains($0) })!
        let weight = self.generator.generateRandomWeight(using: &self.randomNumberGenerator)
        let operation = graph.randomDynamicOperation(name: name, weight: weight, using: &self.randomNumberGenerator)

        try! graph.apply(operation)

        self.state = .faceWeighted(graph)
    }
}
