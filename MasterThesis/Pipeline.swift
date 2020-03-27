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

class Pipeline: ObservableObject {
    @Published private(set) var graph: EitherGraph? = nil
    @Published var generator = DelaunayGraphGenerator(countries: Array("ABCDEFGHIJKLMNOPQ"), nestingRatio: 0.3, nestingBias: 0.5)
    @Published var transformer = NaiveTransformer()
    @Published var forceComputer = ConcreteForceComputer()
    @Published var forceApplicator = PrEdForceApplicator()

    @Published var statisticalAccuracyMetric = StatisticalAccuracy()
    @Published var distanceFromCircumcircleMetric = DistanceFromCircumcircle()
    @Published var distanceFromConvexHullMetric = DistanceFromConvexHull()
    @Published var entropyOfAnglesMetric = EntropyOfAngles()
    @Published var entropyOfDistancesFromCentroidMetric = EntropyOfDistancesFromCentroid()

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
        self.scheduleReplacementOperation(named: "generate", as: {
            return .vertexWeighted(try self.generator.generateRandomGraph())
        })
    }

    func replaceGraph(with graph: VertexWeightedGraph) {
        self.scheduleReplacementOperation(named: "original", as: {
            return .vertexWeighted(graph)
        })
    }

    func replaceGraph(with graph: FaceWeightedGraph) {
        self.scheduleReplacementOperation(named: "dual", as: {
            return .faceWeighted(graph)
        })
    }

    func transformVertexWeightedGraph() {
        self.scheduleMutationOperation(named: "transform", as: { graph in
            guard case .vertexWeighted(let untransformed) = graph else { throw UnsupportedOperationError() }

            let transformed = try self.transformer.transform(untransformed)

            return .faceWeighted(transformed)
        })
    }

    func performRandomWeightChange() {
        self.scheduleMutationOperation(named: "random weight", as: { graph in
            guard case .faceWeighted(var graph) = graph else { throw UnsupportedOperationError() }
            guard let face = graph.faces.randomElement() else { throw UnsupportedOperationError() }
            let weight = Double.random(in: self.generator.weights)
            try graph.setWeight(of: face, to: weight)

            return .faceWeighted(graph)
        })
    }

    func performRandomEdgeFlip() {
        self.scheduleMutationOperation(named: "random edge flip", as: { graph in
            guard case .faceWeighted(var graph) = graph else { throw UnsupportedOperationError() }

            var boundaries: [FaceWeightedGraph.Face: Set<FaceWeightedGraph.Vertex>] = [:]
            var adjacencies: [FaceWeightedGraph.Face: Set<FaceWeightedGraph.Face>] = [:]

            for face in graph.faces {
                boundaries[face] = Set(graph.boundary(of: face))
            }

            for (u, v) in graph.edges {
                let faces = graph.faces.filter({ boundaries[$0]!.contains(u) && boundaries[$0]!.contains(v) })
                precondition(faces.count == 1 || faces.count == 2)

                if faces.count == 2 {
                    adjacencies[faces[0], default: []].insert(faces[1])
                    adjacencies[faces[1], default: []].insert(faces[0])
                }
            }

            let linearized = adjacencies.flatMap({ key, value in value.map({ (key, $0) }) })
            let filtered = linearized.filter({ (u,v) in
                let boundary = graph.boundary(between: u, and: v)!
                let count1 = graph.faces.filter({ boundaries[$0]!.contains(boundary.first!) }).count
                let count2 = graph.faces.filter({ boundaries[$0]!.contains(boundary.last!) }).count
                return count1 == 3 && count2 == 3
            })

            guard let selected = filtered.randomElement() else { throw UnsupportedOperationError() }

            try graph.flipBorder(between: selected.0, and: selected.1)

            return .faceWeighted(graph)
        })
    }

    private func stepOnceAndScheduleNextIfNeeded() {
        DispatchQueue.main.async(execute: {
            self.hasScheduledNextSteppingBlock = false
        })

        self.scheduleMutationOperation(named: "step", as: { graph in
            guard case .faceWeighted(var graph) = graph else { throw UnsupportedOperationError() }

            for (u, v) in graph.edges {
                guard graph.contains(u) && graph.contains(v) else { continue } // may have been removed in previous contract operation
                guard graph.distance(from: u, to: v) < 2 else { continue } // must be close enough

                graph.contractEdgeIfPossible(between: u, and: v)
            }

            let forces = self.forceComputer.forces(in: graph)
            self.forceApplicator.apply(forces, to: &graph)

            return .faceWeighted(graph)
        }, completion: { result in
            DispatchQueue.main.async(execute: {
                if result.isSuccess {
                    if self.isSteppingContinuously && !self.hasScheduledNextSteppingBlock {
                        self.queue.asyncAfter(deadline: .now() + 0.01, execute: self.stepOnceAndScheduleNextIfNeeded)
                    }
                } else {
                    self.isSteppingContinuously = false
                }
            })
        })
    }

    func scheduleReplacementOperation(named name: String, as transform: @escaping () throws -> EitherGraph?, completion: ((Result<Void, Error>) -> Void)? = nil) {
        self.queue.async(execute: {
            let result: Result<Void, Error>
            defer { DispatchQueue.main.async(execute: { completion?(result) }) }

            let before = CFAbsoluteTimeGetCurrent()
            do {
                let graph = try transform()
                DispatchQueue.main.async(execute: {
                    self.graph = graph
                })
                result = .success(())
            } catch let error {
                result = .failure(error)
            }
            let after = CFAbsoluteTimeGetCurrent()

            let verb = result.isSuccess ? "Performed" : "Failed"
            print("\(verb) replacement operation “\(name)” in \(String(format: "%.3f", 1e3 * (after - before)))ms")
        })
    }

    func scheduleMutationOperation(named name: String, as transform: @escaping (EitherGraph) throws -> EitherGraph, completion: ((Result<Void, Error>) -> Void)? = nil) {
        self.queue.async(execute: {
            let result: Result<Void, Error>
            defer { DispatchQueue.main.async(execute: { completion?(result) }) }

            let before = CFAbsoluteTimeGetCurrent()
            do {
                guard var graph = self.graph else { throw UnsupportedOperationError() }
                graph = try transform(graph)
                DispatchQueue.main.async(execute: {
                    self.graph = graph
                })
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

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
}
