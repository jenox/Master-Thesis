//
//  EvaluateCommand.swift
//  Evaluation
//
//  Created by Christian Schnorr on 23.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Foundation
import ArgumentParser
import Framework
import Collections

struct EvaluateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "evaluate")

    @Option() private var numberOfVertices: Int
    @Option() private var nestingRatio: Double
    @Option() private var nestingBias: Double
    @Option() private var inputDirectory: URL
    @Option() private var outputDirectory: URL

    func validate() throws {
    }

    func run() throws {
        try FileManager.default.createDirectory(at: self.outputDirectory, withIntermediateDirectories: true)

        let parameters = "\(self.numberOfVertices)-\(self.nestingRatio)-\(self.nestingBias)"
        let inputDirectory = self.inputDirectory.appendingPathComponent(parameters)
        let urls = try FileManager.default.contentsOfDirectory(at: inputDirectory, includingPropertiesForKeys: nil)
        let urlsAndUUIDs = urls.compactMap({ url in UUID(uuidString: url.lastPathComponent).map({ (url, $0) }) })

        print("Found \(urlsAndUUIDs.count) instances in \(inputDirectory.absoluteURL)")

        var text = "uuid,initial number of clusters,nesting ratio,nesting bias,number of operations"
        text += ",maximum cartographic error,average cartographic error,maximum polygon complexity,average polygon complexity"
        text += ",number of internal vertices in cluster graph,number of external vertices in cluster graph,number of internal edges in cluster graph,number of external edges in cluster graph,number of faces in cluster graph"

        for (url, uuid) in urlsAndUUIDs {
            for i in 1... {
                guard let dual = try self.parseDualGraph(at: url.appendingPathComponent("map-\(i).json")) else { break }

                let errors = try! CartographicError().evaluate(in: dual)
                let complexities = try! PolygonComplexity().evaluate(in: dual)
                let primal = dual.embeddedClusterGraph

                text += "\n\(uuid),\(self.numberOfVertices),\(self.nestingRatio),\(self.nestingBias),\(i-1)"
                text += ",\(errors.max()!),\(errors.mean()!),\(complexities.max()!),\(complexities.mean()!)"
                text += ",\(primal.internalVertices.count),\(primal.externalVertices.count),\(primal.internalEdges.count),\(primal.externalEdges.count),\(primal.internalFaces.count)"
            }
        }

        let url = self.outputDirectory.appendingPathComponent("\(parameters).csv")
        try! text.data(using: .utf8)!.write(to: url)
    }

    private func parseDualGraph(at url: URL) throws -> PolygonalDual? {
        guard let data = try? Data(contentsOf: url) else { return nil }

        let graph = try JSONDecoder().decode(PolygonalDual.self, from: data)
        return graph
    }
}

private extension Collection where Element == Double {
    func mean() -> Double? {
        guard !self.isEmpty else { return nil }

        return self.reduce(0, +) / Double(self.count)
    }
}
