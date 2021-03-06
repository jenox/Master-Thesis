//
//  Pipeline.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 23.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Foundation
import Combine
import Framework

final class Pipeline<Generator, Transformer, ForceApplicator>: ObservableObject where Generator: GraphGenerator, Transformer: Framework.Transformer, ForceApplicator: Framework.ForceApplicator {

    // MARK: - Initialization

    init(generator: Generator, transformer: Transformer, forceApplicator: ForceApplicator, randomNumberGenerator: AnyRandomNumberGenerator) {
        self.generator = generator
        self.transformer = transformer
        self.forceApplicator = forceApplicator
        self.randomNumberGenerator = randomNumberGenerator
    }


    // MARK: - Components

    @Published var generator: Generator { didSet { dispatchPrecondition(condition: .onQueue(.main)) } }
    @Published var transformer: Transformer { didSet { dispatchPrecondition(condition: .onQueue(.main)) } }
    @Published var forceApplicator: ForceApplicator { didSet { dispatchPrecondition(condition: .onQueue(.main)) } }
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

        stepOnce(completion: { success in
            if success {
                if self.isRunning && !self.hasScheduledNextSteppingBlock {
                    GraphModificationQueue.schedule(self.stepOnceAndScheduleNextIfNeeded, after: 0.01)
                }
            } else {
                self.isRunning = false
            }
        })
    }

    private func stepOnce(completion: ((Bool) -> Void)? = nil) {
        self.scheduleOperation(named: "step", {
            switch self.graph {
            case .vertexWeighted(var graph):
                try self.forceApplicator.applyForces(to: &graph)
                return .vertexWeighted(graph)
            case .faceWeighted(var graph):
                try graph.willStepOnce()
                try self.forceApplicator.applyForces(to: &graph)
                try graph.didStepOnce()
                return .faceWeighted(graph)
            case .none:
                throw UnsupportedOperationError()
            }
        }, completion: { result in
            completion?(result.isSuccess)
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
//                    if case .faceWeighted(let graph) = graph {
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
//                            try! graph.ensureAllValidOperationsPass()
//                        })
//                    }

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

    func clear(completion: CompletionHandler? = nil) {
        self.scheduleReplacementOperation(named: "clear", {
            return nil
        }, completion: completion)
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
    }

    func changeRandomCountryWeight() {
        self.scheduleMutationOperation(named: "random weight change", { graph in
            guard let country = graph.faces.randomElement(using: &self.randomNumberGenerator) else { throw UnsupportedOperationError() }
            let weight = self.generator.generateRandomWeight(using: &self.randomNumberGenerator)
            try graph.adjustWeight(of: country, to: weight)
        })
    }

    func insertRandomVertexInside() {
        self.scheduleMutationOperation(named: "insert vertex inside", { graph in
            let possibleNames = "ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÄÆÃÅĀÈÉÊÊĒĖĘEÎÏÍĪĮÌÔÖÒÓŒØŌÕÛÜÙÚŪ".map(ClusterName.init)
            let name = possibleNames.first(where: { !graph.faces.contains($0) })!
            let weight = self.generator.generateRandomWeight(using: &self.randomNumberGenerator)
            let operations = graph.possibleInsertFaceInsideOperations(name: name, weight: weight)
            guard !operations.isEmpty else { throw UnsupportedOperationError() }
            let operation = operations.randomElement(using: &self.randomNumberGenerator)!
            print("Applying", operation)
            try! graph.insertFaceInside(operation)
        })
    }

    func insertRandomVertexOutside() {
        self.scheduleMutationOperation(named: "insert vertex outside", { graph in
            let possibleNames = "ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÄÆÃÅĀÈÉÊÊĒĖĘEÎÏÍĪĮÌÔÖÒÓŒØŌÕÛÜÙÚŪ".map(ClusterName.init)
            let name = possibleNames.first(where: { !graph.faces.contains($0) })!
            let weight = self.generator.generateRandomWeight(using: &self.randomNumberGenerator)
            let operations = graph.possibleInsertFaceOutsideOperations(name: name, weight: weight)
            guard !operations.isEmpty else { throw UnsupportedOperationError() }
            let operation = operations.randomElement(using: &self.randomNumberGenerator)!
            print("Applying", operation)
            try! graph.insertFaceOutside(operation)
        })
    }

    func removeRandomInternalVertex() {
        self.scheduleMutationOperation(named: "remove internal vertex", { graph in
            let operations = graph.possibleRemoveFaceWithoutBoundaryToExternalFaceOperations()
            guard !operations.isEmpty else { throw UnsupportedOperationError() }
            let operation = operations.randomElement(using: &self.randomNumberGenerator)!
            print("Applying", operation)
            try! graph.removeFaceWithoutBoundaryToExternalFace(operation)
        })
    }

    func removeRandomExternalVertex() {
        self.scheduleMutationOperation(named: "remove external vertex", { graph in
            let operations = graph.possibleRemoveFaceWithBoundaryToExternalFaceOperations()
            guard !operations.isEmpty else { throw UnsupportedOperationError() }
            let operation = operations.randomElement(using: &self.randomNumberGenerator)!
            print("Applying", operation)
            try! graph.removeFaceWithBoundaryToExternalFace(operation)
        })
    }

    func flipRandomInternalEdge() {
        self.scheduleMutationOperation(named: "random edge flip", { graph in
            let operations = graph.possibleFlipAdjacencyOperations()
            guard !operations.isEmpty else { throw UnsupportedOperationError() }
            let operation = operations.randomElement(using: &self.randomNumberGenerator)!
            print("Applying", operation)
            try! graph.flipAdjacency(operation)
        })
    }

    func insertRandomEdgeOutside() {
        self.scheduleMutationOperation(named: "random edge insertion", { graph in
            let operations = graph.possibleCreateAdjacencyOperations()
            guard !operations.isEmpty else { throw UnsupportedOperationError() }
            let operation = operations.randomElement(using: &self.randomNumberGenerator)!
            print("Applying", operation)
            try! graph.createAdjacency(operation)
        })
    }

    func removeRandomEdgeOutside() {
        self.scheduleMutationOperation(named: "random edge removal", { graph in
            let operations = graph.possibleRemoveAdjacencyOperations()
            guard !operations.isEmpty else { throw UnsupportedOperationError() }
            let operation = operations.randomElement(using: &self.randomNumberGenerator)!
            print("Applying", operation)
            try! graph.removeAdjacency(operation)
        })
    }
}

private enum GraphModificationQueue {
    private static let queue = DispatchQueue(label: "GraphModificationQueue")

    static func schedule(_ closure: @escaping () -> Void, after delay: TimeInterval = 0) {
        self.queue.asyncAfter(deadline: .now() + delay, execute: closure)
    }
}
