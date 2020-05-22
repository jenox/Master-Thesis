//
//  FastPipeline.swift
//  Evaluation
//
//  Created by Christian Schnorr on 22.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Foundation

class FastPipeline {
    init(directory: URL, numberOfOptimizationSteps: Int, numberOfDynamicOperations: Int, generator: DelaunayGraphGenerator) {
        self.directory = directory
        self.numberOfOptimizationSteps = numberOfOptimizationSteps
        self.numberOfDynamicOperations = numberOfDynamicOperations
        self.generator = generator

        self.identifier = UUID()
        self.state = .vertexWeighted(try! generator.generateRandomGraph(using: &self.randomNumberGenerator))
    }

    private let directory: URL
    private let generator: DelaunayGraphGenerator
    private let numberOfOptimizationSteps: Int
    private let numberOfDynamicOperations: Int

    private let transformer: Transformer = NaiveTransformer()
    private let forceComputer: ForceComputer = ConcreteForceComputer()
    private let forceApplicator: ForceApplicator = PrEdForceApplicator()
    private var randomNumberGenerator: AnyRandomNumberGenerator = AnyRandomNumberGenerator(SystemRandomNumberGenerator())

    private var identifier: UUID
    private var state: EitherGraph

    private func regenerate() {
        self.identifier = UUID()
        self.state = .vertexWeighted(try! generator.generateRandomGraph(using: &self.randomNumberGenerator))
    }

    private func transform() {
        let untransformed = self.state.vertexWeightedGraph!
        let transformed = try! self.transformer.transform(untransformed)

        self.state = .faceWeighted(transformed)
    }

    private func createDirectory() {
        try! FileManager.default.createDirectory(at: self.directory.appendingPathComponent("\(self.identifier)"), withIntermediateDirectories: false)
    }

    private func save(withSuffix suffix: String) {
        let url = self.directory.appendingPathComponent("\(self.identifier)").appendingPathComponent("\(suffix).json")

        switch self.state {
        case .vertexWeighted(let graph):
            try! JSONEncoder().encode(graph).write(to: url)
        case .faceWeighted(let graph):
            try! JSONEncoder().encode(graph).write(to: url)
        }
    }

    private func step() {
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

    private func performRandomOperation() {
        var graph = self.state.faceWeightedGraph!

        for face in graph.faces {
            let generated = self.generator.generateRandomWeight(using: &self.randomNumberGenerator)
            let weight = 0.75 * graph.weight(of: face) + 0.25 * generated

            graph.setWeight(of: face, to: weight)
        }

        // TODO: try to keep number of vertices ~constant
        let possibleNames = "ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÄÆÃÅĀÈÉÊÊĒĖĘEÎÏÍĪĮÌÔÖÒÓŒØŌÕÛÜÙÚŪ".map(ClusterName.init)
        let name = possibleNames.first(where: { !graph.faces.contains($0) })!
        let weight = self.generator.generateRandomWeight(using: &self.randomNumberGenerator)
        var operations = Array(graph.possibleDynamicOperations(name: name, weight: weight))
        if Double(graph.faces.count) <= 0.8 * Double(self.generator.numberOfCountries) {
            operations.removeAll(where: \.isRemoval)
        }
        if Double(graph.faces.count) >= 1.2 * Double(self.generator.numberOfCountries) {
            operations.removeAll(where: \.isInsertion)
        }
        let operation = operations.randomElement(using: &self.randomNumberGenerator)!
        try! graph.apply(operation)

        self.state = .faceWeighted(graph)
    }

    func runThroughPipelineOnce() {
        self.regenerate()
        self.createDirectory()
        self.save(withSuffix: "cluster-0")
        for _ in 0..<self.numberOfOptimizationSteps { self.step() }
        self.save(withSuffix: "cluster-1")
        self.transform()
        self.save(withSuffix: "map-0")
        for _ in 0..<self.numberOfOptimizationSteps { self.step() }
        self.save(withSuffix: "map-1")
//        var last = CFAbsoluteTimeGetCurrent()
        for i in 0..<self.numberOfDynamicOperations {
            self.performRandomOperation()
            for _ in 0..<self.numberOfOptimizationSteps { self.step() }
            self.save(withSuffix: "map-\(2 + i)")
//            let now = CFAbsoluteTimeGetCurrent()
//            print((now - last) * 1e3, self.state.faceWeightedGraph!.faces.count)
//            last = now
        }
    }
}
