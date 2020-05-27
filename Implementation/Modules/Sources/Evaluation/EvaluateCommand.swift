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

        var text = "uuid,number of vertices,nesting ratio,nesting bias,number of operations,maximum cartographic error,average cartographic error,maximum polygon complexity,average polygon complexity"

        for (url, uuid) in urlsAndUUIDs {
            for i in 1... {
                guard let graph = try self.parseGraph(at: url.appendingPathComponent("map-\(i).json")) else { break }

                let errors = try! CartographicError().evaluate(in: graph)
                let complexities = try! PolygonComplexity().evaluate(in: graph)

                text += "\n\(uuid),\(self.numberOfVertices),\(self.nestingRatio),\(self.nestingBias),\(i-1),\(errors.max()!),\(errors.mean()!),\(complexities.max()!),\(complexities.mean()!)"
            }
        }

        let url = self.outputDirectory.appendingPathComponent("\(parameters).csv")
        try! text.data(using: .utf8)!.write(to: url)
    }

    private func parseGraph(at url: URL) throws -> PolygonalDual? {
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
