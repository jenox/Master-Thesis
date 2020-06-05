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
    @Option(default: true) private var pressure: Bool

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

            var colors: [ClusterName: Color] = [:]

            for t in 1...5 {
                var copy = generator

                guard let dual = try self.parseDualGraph(at: url.appendingPathComponent("map-\(t).json")) else { break }
                guard let data = dual.svgData(using: &copy, colors: &colors, colorized: !self.pressure) else { break }

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
    func svgData<T>(using generator: inout T, colors: inout [ClusterName: Color], colorized: Bool) -> Data? where T: RandomNumberGenerator {
        var bounds = CGRect(boundingBoxOf: self.vertices.map(self.position(of:)))
        bounds = bounds.scaled(by: 1.1, around: bounds.center)

        let width = bounds.width.rounded(.up)
        let height = bounds.height.rounded(.up)

        let stroke = 0.5 * fmax(width, height) / 240
        let radius = 1.5 * fmax(width, height) / 240

        var svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\(width)\" height=\"\(height)\">"
        svg += "<g transform=\"matrix(1,0,0,-1,0,\(height)),matrix(1,0,0,1,\(-bounds.minX),\(-bounds.minY))\">"

        let clusterGraph = self.embeddedClusterGraph
        var counts: [Color: Int] = Dictionary(grouping: colors.values, by: { $0 }).mapValues({ $0.count })

        for cluster in clusterGraph.vertices where colors[cluster] == nil {
            let availableColors = Set(Color.allCases).subtracting(clusterGraph.vertices(adjacentTo: cluster).compactMap({ colors[$0] }))
            var color: Color? = nil

            for count in 0...5 {
                if let availableColor = availableColors.filter({ counts[$0, default: 0] == count }).randomElement(using: &generator) {
                    color = availableColor
                    break
                }
            }

            if let color = color {
                colors[cluster] = color
                counts[color, default: 0] += 1
            } else {
                print("Cannot export, didn't find valid color!")
                return nil
            }
        }

        let totalweight = self.faces.map(self.weight(of:)).reduce(0, +).rawValue
        let totalarea = self.faces.map(self.area(of:)).reduce(0, +)

        // faces
        svg += "<g stroke=\"none\">"
        for face in self.faces {
            let points = self.boundary(of: face).map(self.position(of:))
            let d = "M \(points[0].x),\(points[0].y) \(points.dropFirst().map({ " L \($0.x),\($0.y)" }).joined(separator: " ")) Z"

            if colorized {
                svg += "<path d=\"\(d)\" fill=\"\(colors[face]!.rgbValue)\" opacity=\"0.25\" />"
            } else {
                let weight = self.weight(of: face).rawValue
                let area = self.area(of: face)
                let normalizedArea = (area / totalarea) * totalweight
                let ratio = normalizedArea / weight // in (0, inf)
                let x = (ratio <= 1 ? ratio : 2 - 1 / ratio) / 2
                let present = (2 - 2 * x).clamped(to: 0...1)
                let notpresent = (1 - 2 * x).clamped(to: 0...1)

                let r = Int((255 * notpresent).rounded().clamped(to: 0...255))
                let g = Int((255 * present).rounded().clamped(to: 0...255))
                let b = Int((255 * notpresent).rounded().clamped(to: 0...255))

                svg += "<path d=\"\(d)\" fill=\"rgb(\(r),\(g),\(b))\" opacity=\"1\" />"
            }
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


private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
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
