//
//  main.swift
//  Evaluation
//
//  Created by Christian Schnorr on 22.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Foundation

let directory = URL(fileURLWithPath: "/Users/jenox/Desktop/Evaluation/")
let generator = DelaunayGraphGenerator(numberOfCountries: 10, nestingRatio: 0, nestingBias: 0)

let group = DispatchGroup()
let queue = DispatchQueue(label: "pipeline-queue", qos: .userInitiated, attributes: .concurrent)

for _ in 0..<ProcessInfo.processInfo.activeProcessorCount {
    queue.async(group: group, execute: {
        let pipeline = FastPipeline(directory: directory, numberOfOptimizationSteps: 100, numberOfDynamicOperations: 20, generator: generator)
        for _ in 0..<10 {
            pipeline.runThroughPipelineOnce()
        }
    })
}

group.wait()
