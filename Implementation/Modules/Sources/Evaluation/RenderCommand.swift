//
//  RenderCommand.swift
//  Evaluation
//
//  Created by Christian Schnorr on 29.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Foundation
import ArgumentParser
import Framework
import Collections
import Geometry

struct RenderCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "render")

    @Option() private var numberOfVertices: Int
    @Option() private var nestingRatio: Double
    @Option() private var nestingBias: Double
    @Option() private var inputDirectory: URL
    @Option() private var outputDirectory: URL

    func validate() throws {
    }

    func run() throws {
        let parameters = "\(self.numberOfVertices)-\(self.nestingRatio)-\(self.nestingBias)"
        let inputDirectory = self.inputDirectory.appendingPathComponent(parameters)
        let urls = try FileManager.default.contentsOfDirectory(at: inputDirectory, includingPropertiesForKeys: nil)
        let urlsAndUUIDs = urls.compactMap({ url in UUID(uuidString: url.lastPathComponent).map({ (url, $0) }) })

        try FileManager.default.createDirectory(at: self.outputDirectory.appendingPathComponent(parameters), withIntermediateDirectories: true)

        print("Found \(urlsAndUUIDs.count) instances in \(inputDirectory.absoluteURL)")

        for (url, uuid) in urlsAndUUIDs {
            var hasher = Hasher()
            hasher.combine(uuid.uuidString)
            hasher.combine(self.numberOfVertices)
            hasher.combine(self.nestingRatio)
            hasher.combine(self.nestingBias)
            let seed = UInt64(bitPattern: Int64(hasher.finalize()))
            let generator = Xoroshiro128PlusRandomNumberGenerator(seed: seed)

            for t in 1...5 {
                var copy = generator

                guard let dual = try self.parseDualGraph(at: url.appendingPathComponent("map-\(t).json")) else { break }
                guard let data = dual.svgData(using: &copy) else { break }

                try data.write(to: self.outputDirectory.appendingPathComponent(parameters).appendingPathComponent("\(uuid)-\(t - 1).svg"))
            }
        }
    }

    private func parseDualGraph(at url: URL) throws -> PolygonalDual? {
        guard let data = try? Data(contentsOf: url) else { return nil }

        let graph = try JSONDecoder().decode(PolygonalDual.self, from: data)
        return graph
    }
}

private extension PolygonalDual {
    func svgData<T>(using generator: inout T) -> Data? where T: RandomNumberGenerator {
        var bounds = CGRect(boundingBoxOf: self.vertices.map(self.position(of:)))
        bounds = bounds.scaled(by: 1.1, around: bounds.center)

        let width = bounds.width.rounded(.up)
        let height = bounds.height.rounded(.up)

        let stroke = 0.5 * fmax(width, height) / 240
        let radius = 1.5 * fmax(width, height) / 240

        var svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\(width)\" height=\"\(height)\">"
        svg += "<g transform=\"matrix(1,0,0,-1,0,\(height)),matrix(1,0,0,1,\(-bounds.minX),\(-bounds.minY))\">"

        let clusterGraph = self.embeddedClusterGraph
        var colors: [ClusterName: Color] = [:]
        var counts: [Color: Int] = [:]
        for cluster in clusterGraph.vertices {
            let availableColors = Set(Color.allCases).subtracting(clusterGraph.vertices(adjacentTo: cluster).compactMap({ colors[$0] }))
            var color: Color? = nil

            for count in 0...5 {
                if let availableColor = availableColors.filter({ counts[$0] == count }).randomElement(using: &generator) {
                    color = availableColor
                    break
                }
            }

            if let color = color {
                colors[cluster] = color
                counts[color, default: 0] += 1
            } else {
                return nil
            }
        }

        // faces
        svg += "<g stroke=\"none\">"
        for face in self.faces {
            let points = self.boundary(of: face).map(self.position(of:))

            svg += "<path d=\"M \(points[0].x),\(points[0].y) \(points.dropFirst().map({ " L \($0.x),\($0.y)" }).joined(separator: " ")) Z\" fill=\"\(colors[face]!.rgbValue)\" opacity=\"0.25\" />"
        }
        svg += "</g>"

        // edges
        do {
            var path = ""
            for face in self.faces {
                let points = self.boundary(of: face).map(self.position(of:))
                path += "M \(points[0].x),\(points[0].y) \(points.dropFirst().map({ " L \($0.x),\($0.y)" }).joined(separator: " ")) Z"
            }
            svg += "<path d=\"\(path)\" fill=\"none\" stroke=\"black\" stroke-width=\"\(stroke)\" stroke-linecap=\"round\" stroke-linejoin=\"round\" />"
        }

        // vertices
        svg += "<g fill=\"black\" stroke=\"none\">"
        for v in self.vertices {
            let position = self.position(of: v)
            svg += "<circle cx=\"\(position.x)\" cy=\"\(position.y)\" r=\"\(radius)\" />"
        }
        svg += "</g>"

        svg += "</g>"
        svg += "</svg>"

        return svg.data(using: .utf8)!
    }
}

private extension CGRect {
    init(boundingBoxOf points: [CGPoint]) {
        let minX = points.map(\.x).min()!
        let maxX = points.map(\.x).max()!
        let minY = points.map(\.y).min()!
        let maxY = points.map(\.y).max()!

        self = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    var center: CGPoint {
        return CGPoint(x: self.midX, y: self.midY)
    }
}

private extension ClusterName {
    private static let colors = [Color.red, .green, .blue, .cyan, .yellow, .magenta, .orange, .purple, .brown]

    var color: Color {
        return Self.colors[Int(rawValue.unicodeScalars.reduce(7, { $0 + $1.value })) % Self.colors.count]
    }
}

private enum Color: CaseIterable {
    case red
    case green
    case blue
    case cyan
    case yellow
    case magenta
    case orange
    case purple
    case brown

    var rgbValue: String {
        switch self {
        case .red: return "rgb(255,0,0)"
        case .green: return "rgb(0,255,0)"
        case .blue: return "rgb(0,0,255)"
        case .cyan: return "rgb(0,255,255)"
        case .yellow: return "rgb(255,255,0)"
        case .magenta: return "rgb(255,0,255)"
        case .orange: return "rgb(255,127,0)"
        case .purple: return "rgb(127,0,127)"
        case .brown: return "rgb(153,102,51)"
        }
    }
}
