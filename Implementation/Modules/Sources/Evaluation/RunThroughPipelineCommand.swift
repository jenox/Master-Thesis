//
//  RunThroughPipelineCommand.swift
//  Evaluation
//
//  Created by Christian Schnorr on 23.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Foundation
import ArgumentParser
import Framework

struct RunThroughPipelineCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pipeline"
    )

    @Option() var numberOfVertices: Int
    @Option() var nestingRatio: Double
    @Option() var nestingBias: Double
    @Option(default: 10) var numberOfOptimizationStepsPerVertex: Int
    @Option(default: 20) var numberOfDynamicOperations: Int
    @Option(default: ProcessInfo.processInfo.activeProcessorCount) var numberOfThreads: Int
    @Option() var uuidFile: URL
    @Option() var outputDirectory: URL

    func validate() throws {
        guard self.numberOfVertices >= 3 else { throw ValidationError("") }
        guard 0...1 ~= self.nestingRatio else { throw ValidationError("") }
        guard 0..<1 ~= self.nestingBias else { throw ValidationError("") }
        guard self.numberOfOptimizationStepsPerVertex >= 0 else { throw ValidationError("") }
        guard self.numberOfDynamicOperations >= 0 else { throw ValidationError("") }
        guard self.numberOfThreads >= 1 else { throw ValidationError("") }
    }

    func run() throws {
        let generator = DelaunayGraphGenerator(numberOfCountries: self.numberOfVertices, nestingRatio: self.nestingRatio, nestingBias: self.nestingBias)

        let group = DispatchGroup()
        let queue = DispatchQueue(label: "pipeline-queue", qos: .userInitiated, attributes: .concurrent)

        let lines = String(data: try Data(contentsOf: self.uuidFile), encoding: .utf8)!.components(separatedBy: .newlines)
        let uuids = lines.compactMap(UUID.init)

        var index = -1 as Int32

        for thread in 0..<self.numberOfThreads {
            queue.async(group: group, execute: {
                while let index = Int(OSAtomicIncrement32(&index)) as Optional, index < uuids.count {
                    let uuid = uuids[index]

                    print("Starting instance \(uuid) on thread #\(thread)")

                    let directory = self.outputDirectory.appendingPathComponent(uuid.uuidString)
                    try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)

                    var hasher = Hasher()
                    hasher.combine(uuid.uuidString)
                    hasher.combine(self.numberOfVertices)
                    hasher.combine(self.nestingRatio)
                    hasher.combine(self.nestingBias)
                    let seed = UInt64(bitPattern: Int64(hasher.finalize()))

                    var pipeline = Pipeline(seed: seed, generator: generator)
                    pipeline.save(to: directory.appendingPathComponent("cluster-0.json"))
                    for _ in 0..<pipeline.numberOfOperations(multiplier: self.numberOfOptimizationStepsPerVertex) { pipeline.step() }
                    pipeline.save(to: directory.appendingPathComponent("cluster-1.json"))
                    pipeline.transform()
                    pipeline.save(to: directory.appendingPathComponent("map-0.json"))
                    for _ in 0..<pipeline.numberOfOperations(multiplier: self.numberOfOptimizationStepsPerVertex) { pipeline.step() }
                    pipeline.save(to: directory.appendingPathComponent("map-1.json"))

                    for i in 0..<self.numberOfDynamicOperations {
                        pipeline.applyRandomOperation()
                        for _ in 0..<pipeline.numberOfOperations(multiplier: self.numberOfOptimizationStepsPerVertex) { pipeline.step() }
                        pipeline.save(to: directory.appendingPathComponent("map-\(2 + i).json"))
                    }
                }
            })
        }

        group.wait()
    }
}
