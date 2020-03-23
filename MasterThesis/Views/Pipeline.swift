//
//  Pipeline.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 23.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Dispatch
import Combine
import CoreFoundation

class Pipeline: ObservableObject {
    @Published private(set) var graph: FaceWeightedGraph?
    @Published var forceComputer = ConcreteForceComputer()
    @Published var forceApplicator = PrEdForceApplicator()
    @Published var isSteppingContinuously: Bool = false {
        didSet {
            if self.isSteppingContinuously, !oldValue, !self.hasScheduledNextSteppingBlock {
                self.hasScheduledNextSteppingBlock = true
                self.queue.async(execute: self.stepOnceAndScheduleNextIfNeeded)
            }
        }
    }

    private let queue = DispatchQueue(label: "GraphModificationQueue")
    private var hasScheduledNextSteppingBlock: Bool = false

    func clearGraph() {
        self.scheduleReplacementOperation(named: "clear", as: {
            return nil
        })
    }

    func generateNewGraph() {
        fatalError()
    }

    func replaceGraph(with graph: VertexWeightedGraph) {
        self.scheduleReplacementOperation(named: "original", as: {
            return graph.subdividedDual()
        })
    }

    func replaceGraph(with graph: FaceWeightedGraph) {
        self.scheduleReplacementOperation(named: "dual", as: {
            return graph
        })
    }

    private func stepOnceAndScheduleNextIfNeeded() {
        DispatchQueue.main.async(execute: {
            self.hasScheduledNextSteppingBlock = false
        })

        self.scheduleMutationOperation(named: "step", as: { graph in
            for (u, v) in graph.edges {
                guard graph.contains(u) && graph.contains(v) else { continue } // may have been removed in previous contract operation
                guard graph.distance(from: u, to: v) < 2 else { continue } // must be close enough

                graph.contractEdgeIfPossible(between: u, and: v)
            }

            let forces = self.forceComputer.forces(in: graph)
            PrEdForceApplicator().apply(forces, to: &graph)
        }, completion: { result in
            if result.isSuccess {
                DispatchQueue.main.async(execute: {
                    if self.isSteppingContinuously && !self.hasScheduledNextSteppingBlock {
                        self.queue.asyncAfter(deadline: .now() + 0.05, execute: self.stepOnceAndScheduleNextIfNeeded)
                    }
                })
            } else {
                self.isSteppingContinuously = false
            }
        })
    }

    func scheduleReplacementOperation(named name: String, as transform: @escaping () throws -> FaceWeightedGraph?, completion: ((Result<Void, Error>) -> Void)? = nil) {
        self.queue.async(execute: {
            let result: Result<Void, Error>
            defer { DispatchQueue.main.async(execute: { completion?(result) }) }

            let before = CFAbsoluteTimeGetCurrent()
            do {
                self.graph = try transform()
                result = .success(())
            } catch let error {
                result = .failure(error)
            }
            let after = CFAbsoluteTimeGetCurrent()

            let verb = result.isSuccess ? "Performed" : "Failed"
            print("\(verb) replacement operation “\(name)” in \(String(format: "%.3f", 1e3 * (after - before)))ms")
        })
    }

    func scheduleMutationOperation(named name: String, as transform: @escaping (inout FaceWeightedGraph) throws -> Void, completion: ((Result<Void, Error>) -> Void)? = nil) {
        self.queue.async(execute: {
            let result: Result<Void, Error>
            defer { DispatchQueue.main.async(execute: { completion?(result) }) }

            let before = CFAbsoluteTimeGetCurrent()
            do {
                guard var graph = self.graph else { throw MutationOperationError.noGraphToBeMutated }
                try transform(&graph)
                self.graph = graph
                result = .success(())
            } catch let error {
                result = .failure(error)
            }
            let after = CFAbsoluteTimeGetCurrent()

            let verb = result.isSuccess ? "Performed" : "Failed"
            print("\(verb) mutation operation “\(name)” in \(String(format: "%.3f", 1e3 * (after - before)))ms")
        })
    }
}

enum MutationOperationError: Error {
    case noGraphToBeMutated
}

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
}
