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
    @Published private(set) var previousGraph: EitherGraph? = nil { didSet { dispatchPrecondition(condition: .onQueue(.main)) } }
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

        self.scheduleOperation(named: "step", {
            switch self.graph {
            case .vertexWeighted(var graph):
                let forces = try self.forceComputer.forces(in: graph)
                try self.forceApplicator.apply(forces, to: &graph)
                return .vertexWeighted(graph)
            case .faceWeighted(var graph):
                try graph.willStepOnce()
                let forces = try self.forceComputer.forces(in: graph)
                try self.forceApplicator.apply(forces, to: &graph)
                try graph.didStepOnce()
                return .faceWeighted(graph)
            case .none:
                throw UnsupportedOperationError()
            }
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

    private typealias ReplacementOperation = () throws -> EitherGraph?
    private typealias MutationOperation = (inout PolygonalDual) throws -> Void
    typealias CompletionHandler = (Result<Void, Error>) -> Void

    private func scheduleReplacementOperation(named name: String, _ operation: @escaping ReplacementOperation, completion: CompletionHandler? = nil) {
        self.scheduleOperation(named: name, {
            return try operation()
        }, completion: completion)
    }

    private func scheduleMutationOperation(named name: String, _ operation: @escaping MutationOperation, completion: CompletionHandler? = nil) {
        self.scheduleOperation(named: name, {
            guard case .faceWeighted(var graph) = self.graph else { throw UnsupportedOperationError() }
            try operation(&graph)
            return .faceWeighted(graph)
        }, completion: completion)
    }

    private func scheduleOperation(named name: String, _ operation: @escaping ReplacementOperation, completion: CompletionHandler? = nil) {
        GraphModificationQueue.schedule({
            let result: Result<EitherGraph?, Error>
            defer { DispatchQueue.main.async(execute: { completion?(result.map({ _ in () })) }) }

            let before = CFAbsoluteTimeGetCurrent()
            do {
                result = .success(try operation())
            } catch let error {
                result = .failure(error)
            }
            let after = CFAbsoluteTimeGetCurrent()

            let verb = result.isSuccess ? "Performed" : "Failed"
            let duration = "\(String(format: "%.3f", 1e3 * (after - before)))ms"
            print("\(verb) operation “\(name)” in \(duration)")

            if case .success(let graph) = result {
                DispatchQueue.main.sync(execute: {
                    self.previousGraph = self.graph
                    self.graph = graph
                })
            }
        })
    }


    // MARK: - Concrete Operations

    func undo() {
        self.scheduleReplacementOperation(named: "undo", {
            return self.previousGraph
        })
    }

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
        self.scheduleOperation(named: "transform", {
            guard case .vertexWeighted(let untransformed) = self.graph else { throw UnsupportedOperationError() }
            let transformed = try self.transformer.transform(untransformed)
            return .faceWeighted(transformed)
        })

//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
//            self.scheduleMutationOperation(named: "move", { graph in
//                graph.displace(graph.vertices[0], by: CGVector(dx: 0, dy: 25))
//                graph.displace(graph.vertices[10], by: CGVector(dx: -15, dy: 70))
//            })
//        })
    }

    func changeRandomCountryWeight() {
        self.scheduleMutationOperation(named: "random weight change", { graph in
            guard let country = graph.faces.randomElement() else { throw UnsupportedOperationError() }
            let weight = self.generator.generateRandomWeight(using: &self.randomNumberGenerator)
            try graph.adjustWeight(of: country, to: weight)
        })
    }

    func changeWeight(of country: ClusterName, to weight: ClusterWeight, completion: @escaping CompletionHandler) {
        self.scheduleMutationOperation(named: "edge flip", { graph in
            guard graph.faces.contains(country) else { throw UnsupportedOperationError() }
            try graph.adjustWeight(of: country, to: weight)
        }, completion: completion)
    }

    func insertRandomVertexInside() {
        self.scheduleMutationOperation(named: "insert vertex inside", { graph in
            let possibleNames = "ABCDEFGHJIKLMNOPQRSTUVWXYZ".map(ClusterName.init)
            let name = possibleNames.first(where: { !graph.faces.contains($0) })!
            let weight = self.generator.generateRandomWeight(using: &self.randomNumberGenerator)

            try graph.insertFaceInsideRandomly(named: name, weight: weight, using: &self.randomNumberGenerator)
        })
    }

    func insertRandomVertexOutside() {
        self.scheduleMutationOperation(named: "insert vertex outside", { graph in
            let possibleNames = "ABCDEFGHJIKLMNOPQRSTUVWXYZ".map(ClusterName.init)
            let name = possibleNames.first(where: { !graph.faces.contains($0) })!
            let weight = self.generator.generateRandomWeight(using: &self.randomNumberGenerator)

            try graph.insertFaceOutsideRandomly(named: name, weight: weight, using: &self.randomNumberGenerator)
        })
    }

    func removeRandomInternalVertex() {
        self.scheduleMutationOperation(named: "remove internal vertex", { graph in
            try graph.removeRandomInternalFace(using: &self.randomNumberGenerator)
        })
    }

    func removeRandomExternalVertex() {
        self.scheduleMutationOperation(named: "remove internal vertex", { graph in
            try graph.removeRandomExternalFace(using: &self.randomNumberGenerator)
        })
    }

    func flipRandomInternalEdge() {
        self.scheduleMutationOperation(named: "random edge flip", { graph in
            try graph.flipRandomAdjacency(using: &self.randomNumberGenerator)
        })
    }

    func flipAdjacency(between first: ClusterName, and second: ClusterName, completion: @escaping CompletionHandler) {
        self.scheduleMutationOperation(named: "edge flip", { graph in
            try graph.flipAdjanency(between: first, and: second)
        }, completion: completion)
    }

    func insertRandomEdgeOutside() {
    }

    func removeRandomEdgeOutside() {
    }
}

private enum GraphModificationQueue {
    private static let queue = DispatchQueue(label: "GraphModificationQueue")

    static func schedule(_ closure: @escaping () -> Void, after delay: TimeInterval = 0) {
        self.queue.asyncAfter(deadline: .now() + delay, execute: closure)
    }
}
