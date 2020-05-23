//
//  EvaluateCommand.swift
//  Evaluation
//
//  Created by Christian Schnorr on 23.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Foundation
import ArgumentParser

struct EvaluateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "evaluate"
    )

    func validate() throws {
    }

    func run() throws {
        throw UnsupportedOperationError()
    }
}

//let directory = URL(fileURLWithPath: "/Users/jenox/Desktop/Evaluation-10-0-0/")
//let generator = DelaunayGraphGenerator(numberOfCountries: 10, nestingRatio: 0, nestingBias: 0)
//
//let group = DispatchGroup()
//let queue = DispatchQueue(label: "pipeline-queue", qos: .userInitiated, attributes: .concurrent)
//
//for _ in 0..<ProcessInfo.processInfo.activeProcessorCount {
//    queue.async(group: group, execute: {
//        let pipeline = FastPipeline(directory: directory, numberOfOptimizationSteps: 100, numberOfDynamicOperations: 20, generator: generator)
//        for _ in 0..<20 {
//            pipeline.runThroughPipelineOnce()
//        }
//    })
//}
//
//group.wait()

//func evaluate(_ graph: PolygonalDual) -> (Double, Double, Double, Double) {
//    let errors = try! CartographicError().evaluate(in: graph)
//    let complexities = try! PolygonComplexity().evaluate(in: graph)
//
//    return (
//        errors.max()!.rounded(scale: 1e3),
//        errors.mean()!.rounded(scale: 1e3),
//        complexities.max()!.rounded(scale: 1e3),
//        complexities.mean()!.rounded(scale: 1e3)
//    )
//}
//
//func urls(at path: String) -> [URL] {
//    let directory = URL(fileURLWithPath: path)
//    let urls = try! FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
//    return urls.filter({ UUID(uuidString: $0.lastPathComponent) != nil })
//}
//
//func parseGraph(at url: URL) -> PolygonalDual {
//    let data = try! Data(contentsOf: url)
//    let graph = try! JSONDecoder().decode(PolygonalDual.self, from: data)
//    return graph
//}
//
//func dumpDynamicsCSV() {
//    var text = "id,number of operations,maximum cartographic error,average cartographic error,maximum polygon complexity,average polygon complexity"
//
//    for (url, ops) in urls(at: "/Users/jenox/Desktop/Evaluation/Evaluation-10-0-0/").cartesianProduct(with: [1,3,5,7,11,21]) {
//        let id = url.pathComponents.last!
//        let graph = parseGraph(at: url.appendingPathComponent("map-\(ops).json"))
//        let (a,b,c,d) = evaluate(graph)
//        text += "\n\(id),\(ops-1),\(a),\(b),\(c),\(d)"
//    }
//
//    try! text.data(using: .utf8)!.write(to: URL(fileURLWithPath: "/Users/jenox/Desktop/Plots/Dynamics.csv"))
//}
//
//func dumpSizesCSV() {
//    var text = "id,number of vertices,maximum cartographic error,average cartographic error,maximum polygon complexity,average polygon complexity"
//
//    for numberOfVertices in [10,15,20] {
//        for url in urls(at: "/Users/jenox/Desktop/Evaluation/Evaluation-\(numberOfVertices)-0-0/") {
//            let id = url.pathComponents.last!
//            let graph = parseGraph(at: url.appendingPathComponent("map-1.json"))
//            let (a,b,c,d) = evaluate(graph)
//            text += "\n\(id),\(numberOfVertices),\(a),\(b),\(c),\(d)"
//        }
//    }
//
//    try! text.data(using: .utf8)!.write(to: URL(fileURLWithPath: "/Users/jenox/Desktop/Plots/Sizes.csv"))
//}
//
//dumpDynamicsCSV()
//dumpSizesCSV()
