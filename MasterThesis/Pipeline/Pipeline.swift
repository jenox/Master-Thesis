//
//  Pipeline.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 23.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Dispatch
import Combine
import CoreGraphics
import CoreFoundation
import Foundation

final class Pipeline<Generator, Transformer, ForceComputer, ForceApplicator>: ObservableObject where Generator: GraphGenerator, Transformer: MasterThesis.Transformer, ForceComputer: MasterThesis.ForceComputer, ForceApplicator: MasterThesis.ForceApplicator {

    // MARK: - Initialization

    init(generator: Generator, transformer: Transformer, forceComputer: ForceComputer, forceApplicator: ForceApplicator, qualityMetrics: [(name: String, evaluator: QualityEvaluator)], randomNumberGenerator: AnyRandomNumberGenerator) {
        self.generator = generator
        self.transformer = transformer
        self.forceComputer = forceComputer
        self.forceApplicator = forceApplicator
        self.qualityMetrics = qualityMetrics
        self.randomNumberGenerator = randomNumberGenerator
    }


    // MARK: - Components

    @Published var generator: Generator { didSet { dispatchPrecondition(condition: .onQueue(.main)) } }
    @Published var transformer: Transformer { didSet { dispatchPrecondition(condition: .onQueue(.main)) } }
    @Published var forceComputer: ForceComputer { didSet { dispatchPrecondition(condition: .onQueue(.main)) } }
    @Published var forceApplicator: ForceApplicator { didSet { dispatchPrecondition(condition: .onQueue(.main)) } }
    let qualityMetrics: [(name: String, evaluator: QualityEvaluator)]
    private(set) var randomNumberGenerator: AnyRandomNumberGenerator


    // MARK: - Running

    @Published private(set) var graph: EitherGraph? = nil { didSet { dispatchPrecondition(condition: .onQueue(.main)) } }
    @Published private(set) var isRunning: Bool = false { didSet { dispatchPrecondition(condition: .onQueue(.main)) } }
    private var hasScheduledNextSteppingBlock: Bool = false { didSet { dispatchPrecondition(condition: .onQueue(.main)) } }

    func start() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard !self.isRunning else { return }

        self.isRunning = true
        self.hasScheduledNextSteppingBlock = true
        GraphModificationQueue.schedule(self.stepOnceAndScheduleNextIfNeeded)
    }

    func stop() {
        dispatchPrecondition(condition: .onQueue(.main))
        self.isRunning = false
    }

    private func stepOnceAndScheduleNextIfNeeded() {
        DispatchQueue.main.sync(execute: {
            self.hasScheduledNextSteppingBlock = false
        })

        self.scheduleMutationOperation(named: "step", { graph in
            guard case .faceWeighted(var graph) = graph else { throw UnsupportedOperationError() }

            for (u, v) in graph.edges {
                guard graph.contains(u) && graph.contains(v) else { continue } // may have been removed in previous contract operation
                guard graph.distance(from: u, to: v) < 2 else { continue } // must be close enough

                graph.contractEdgeIfPossible(between: u, and: v)
            }

            let forces = try self.forceComputer.forces(in: graph)
            try self.forceApplicator.apply(forces, to: &graph)

            return .faceWeighted(graph)
        }, completion: { result in
            if result.isSuccess {
                if self.isRunning && !self.hasScheduledNextSteppingBlock {
                    GraphModificationQueue.schedule(self.stepOnceAndScheduleNextIfNeeded, after: 0.01)
                }
            } else {
                self.isRunning = false
            }
        })
    }


    // MARK: - Abstract Operations

    private typealias Operation = () throws -> Void
    private typealias ReplacementOperation = () throws -> EitherGraph?
    private typealias MutationOperation = (EitherGraph) throws -> EitherGraph
    typealias CompletionHandler = (Result<Void, Error>) -> Void

    private func scheduleReplacementOperation(named name: String, _ operation: @escaping ReplacementOperation, completion: CompletionHandler? = nil) {
        self.scheduleOperation(named: name, {
            let graph = try operation()
            DispatchQueue.main.sync(execute: {
                self.graph = graph
            })
        }, completion: completion)
    }

    private func scheduleMutationOperation(named name: String, _ operation: @escaping MutationOperation, completion: CompletionHandler? = nil) {
        self.scheduleOperation(named: name, {
            guard var graph = self.graph else { throw UnsupportedOperationError() }
            graph = try operation(graph)
            DispatchQueue.main.sync(execute: {
                self.graph = graph
            })
        }, completion: completion)
    }

    private func scheduleOperation(named name: String, _ operation: @escaping Operation, completion: CompletionHandler? = nil) {
        GraphModificationQueue.schedule({
            let result: Result<Void, Error>
            defer { DispatchQueue.main.async(execute: { completion?(result) }) }

            let before = CFAbsoluteTimeGetCurrent()
            do {
                try operation()
                result = .success(())
            } catch let error {
                result = .failure(error)
            }
            let after = CFAbsoluteTimeGetCurrent()

            let verb = result.isSuccess ? "Performed" : "Failed"
            let duration = "\(String(format: "%.3f", 1e3 * (after - before)))ms"
            print("\(verb) operation “\(name)” in \(duration)")
        })
    }


    // MARK: - Concrete Operations

    func clear() {
        self.scheduleReplacementOperation(named: "clear", {
            return nil
        })
    }

    func load(_ graph: VertexWeightedGraph) {
        self.scheduleReplacementOperation(named: "load", {
            return .vertexWeighted(graph)
        })
    }

    func generate() {
        self.scheduleReplacementOperation(named: "generate", {
            return .vertexWeighted(try self.generator.generateRandomGraph(using: &self.randomNumberGenerator))
        })
    }

    func transform() {
        self.scheduleMutationOperation(named: "transform", { graph in
            guard case .vertexWeighted(let untransformed) = graph else { throw UnsupportedOperationError() }
            let transformed = try self.transformer.transform(untransformed)
            return .faceWeighted(transformed)
        })
    }

    func changeRandomCountryWeight() {
        self.scheduleMutationOperation(named: "random weight change", { graph in
            switch graph {
            case .vertexWeighted(var graph):
                guard let country = graph.vertices.randomElement() else { throw UnsupportedOperationError() }
                let weight = self.generator.generateRandomWeight(using: &self.randomNumberGenerator)
                try graph.adjustWeight(of: country, to: weight)
                return .vertexWeighted(graph)
            case .faceWeighted(var graph):
                guard let country = graph.faces.randomElement() else { throw UnsupportedOperationError() }
                let weight = self.generator.generateRandomWeight(using: &self.randomNumberGenerator)
                try graph.adjustWeight(of: country, to: weight)
                return .faceWeighted(graph)
            }
        })
    }

    func changeWeight(of country: String, to weight: Double, completion: @escaping CompletionHandler) {
        self.scheduleMutationOperation(named: "edge flip", { graph in
            switch graph {
            case .vertexWeighted(var graph):
                guard graph.vertices.contains(country) else { throw UnsupportedOperationError() }
                try graph.adjustWeight(of: country, to: weight)
                return .vertexWeighted(graph)
            case .faceWeighted(var graph):
                guard graph.faces.contains(country) else { throw UnsupportedOperationError() }
                try graph.adjustWeight(of: country, to: weight)
                return .faceWeighted(graph)
            }
        }, completion: completion)
    }

    func flipRandomAdjacency() {
        self.scheduleMutationOperation(named: "random edge flip", { graph in
            switch graph {
            case .vertexWeighted(var graph):
                try graph.flipRandomEdge(using: &self.randomNumberGenerator)
                return .vertexWeighted(graph)
            case .faceWeighted(var graph):
                try graph.flipRandomAdjacency(using: &self.randomNumberGenerator)
                return .faceWeighted(graph)
            }
        })
    }

    func flipAdjacency(between first: String, and second: String, completion: @escaping CompletionHandler) {
        self.scheduleMutationOperation(named: "edge flip", { graph in
            switch graph {
            case .vertexWeighted(var graph):
                try graph.flipEdge(between: first, and: second)
                return .vertexWeighted(graph)
            case .faceWeighted(var graph):
                try graph.flipAdjanency(between: first, and: second)
                return .faceWeighted(graph)
            }
        }, completion: completion)
    }
}

private enum GraphModificationQueue {
    private static let queue = DispatchQueue(label: "GraphModificationQueue")

    static func schedule(_ closure: @escaping () -> Void, after delay: TimeInterval = 0) {
        self.queue.asyncAfter(deadline: .now() + delay, execute: closure)
    }
}
