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

    @Option() private var uuidFile: URL
    @Option() private var inputDirectory: URL
    @Option() private var outputDirectory: URL
    @Option(default: nil) private var limitedToNumberOfIdentifiers: Int?

    @Option(parsing: .upToNextOption) private var sizes: [Int]
    @Option(parsing: .upToNextOption) private var complexities: [Complexity]
    @Option(parsing: .upToNextOption) private var times: [Int]

    func validate() throws {
        guard self.sizes.count >= 1 else { throw ValidationError("") }
        guard self.complexities.count >= 1 else { throw ValidationError("") }
        guard self.times.count >= 1 else { throw ValidationError("") }
    }

    func run() throws {
        print("Sizes:", self.sizes)
        print("Complexities:", self.complexities.map({ ($0.nestingRatio, $0.nestingBias) }))
        print("Times:", self.times)

        let lines = String(data: try Data(contentsOf: self.uuidFile), encoding: .utf8)!.components(separatedBy: .newlines)
        var uuids = ArraySlice(lines.compactMap(UUID.init))
        if let limitedToNumberOfUUIDs = self.limitedToNumberOfIdentifiers {
            uuids = uuids.prefix(limitedToNumberOfUUIDs)
        }

        var dictionary: [Key: Value] = [:]
        dictionary.reserveCapacity(self.sizes.count * self.complexities.count * self.times.count * uuids.count)

        for (size, complexity) in self.sizes.cartesianProduct(with: self.complexities) {
            print("Parsing \(size)-\(complexity.nestingRatio)-\(complexity.nestingBias)...")
            for (uuid, time) in uuids.cartesianProduct(with: self.times) {
                autoreleasepool(invoking: {
                    let url = self.inputDirectory.appendingPathComponent("\(size)-\(complexity.nestingRatio)-\(complexity.nestingBias)").appendingPathComponent(uuid.uuidString).appendingPathComponent("map-\(time).json")
                    let graph = self.parseGraph(at: url)

                    let errors = try! CartographicError().evaluate(in: graph)
                    let complexities = try! PolygonComplexity().evaluate(in: graph)

                    let key = Key(uuid: uuid, size: size, complexity: complexity, time: time)
                    let value = Value(maxerror: errors.max()!, avgerror: errors.mean()!, maxcomplexity: complexities.max()!, avgcomplexity: complexities.mean()!)

                    dictionary[key] = value
                })
            }
        }

        print("Creating CSVs for variable time")
        for (size, complexity) in self.sizes.cartesianProduct(with: self.complexities) {
            var text = "uuid,number of operations,maximum cartographic error,average cartographic error,maximum polygon complexity,average polygon complexity"
            for (uuid, time) in uuids.cartesianProduct(with: self.times) {
                let value = dictionary[Key(uuid: uuid, size: size, complexity: complexity, time: time)]!
                text += "\n\(uuid),\(time),\(value.maxerror),\(value.avgcomplexity),\(value.maxcomplexity),\(value.avgcomplexity)"
            }
            let url = self.outputDirectory.appendingPathComponent("t=?,n=\(size),a=\(complexity.nestingRatio),b=\(complexity.nestingBias).csv")
            try! text.data(using: .utf8)!.write(to: url)
        }

        print("Creating CSVs for variable size")
        for (complexity, time) in self.complexities.cartesianProduct(with: self.times) {
            var text = "uuid,number of vertices,maximum cartographic error,average cartographic error,maximum polygon complexity,average polygon complexity"
            for (uuid, size) in uuids.cartesianProduct(with: self.sizes) {
                let value = dictionary[Key(uuid: uuid, size: size, complexity: complexity, time: time)]!
                text += "\n\(uuid),\(size),\(value.maxerror),\(value.avgcomplexity),\(value.maxcomplexity),\(value.avgcomplexity)"
            }
            let url = self.outputDirectory.appendingPathComponent("n=?,a=\(complexity.nestingRatio),b=\(complexity.nestingBias),t=\(time).csv")
            try! text.data(using: .utf8)!.write(to: url)
        }

        print("Creating CSVs for variable complexity")
        for (size, time) in self.sizes.cartesianProduct(with: self.times) {
            var text = "uuid,nesting ratio and bias,maximum cartographic error,average cartographic error,maximum polygon complexity,average polygon complexity"
            for (uuid, complexity) in uuids.cartesianProduct(with: self.complexities) {
                let value = dictionary[Key(uuid: uuid, size: size, complexity: complexity, time: time)]!
                text += "\n\(uuid),\(complexity.nestingRatio)-\(complexity.nestingBias),\(value.maxerror),\(value.avgcomplexity),\(value.maxcomplexity),\(value.avgcomplexity)"
            }
            let url = self.outputDirectory.appendingPathComponent("a=?,b=?,n=\(size),t=\(time).csv")
            try! text.data(using: .utf8)!.write(to: url)
        }
    }

    private func parseGraph(at url: URL) -> PolygonalDual {
        let data = try! Data(contentsOf: url)
        let graph = try! JSONDecoder().decode(PolygonalDual.self, from: data)
        return graph
    }
}

private struct Complexity: Hashable, ExpressibleByArgument {
    var nestingRatio: Double
    var nestingBias: Double

    init?(argument: String) {
        let components = argument.components(separatedBy: ",")
        assert(components.count == 2)

        guard let nestingRatio = Double(argument: components[0]) else { return nil }
        guard let nestingBias = Double(argument: components[1]) else { return nil }

        self.nestingRatio = nestingRatio
        self.nestingBias = nestingBias
    }
}

private struct Key: Hashable, CustomStringConvertible {
    var uuid: UUID
    var size: Int
    var complexity: Complexity
    var time: Int

    var description: String {
        return "(\(self.uuid)|\(self.size)|\(self.complexity.nestingRatio)|\(self.complexity.nestingBias)|\(self.time))"
    }
}

private struct Value: Hashable, CustomStringConvertible {
    var maxerror: Double
    var avgerror: Double
    var maxcomplexity: Double
    var avgcomplexity: Double

    var description: String {
        return "(\(self.maxerror)|\(self.avgerror)|\(self.maxcomplexity)|\(self.avgcomplexity))"
    }
}

private extension Collection where Element == Double {
    func mean() -> Double? {
        guard !self.isEmpty else { return nil }

        return self.reduce(0, +) / Double(self.count)
    }
}
