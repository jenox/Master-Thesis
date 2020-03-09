//
//  GraphStatisticsView.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 09.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import UIKit

class GraphStatisticsView: UIView {
    var graph: FaceWeightedGraph {
        didSet {
            (self.statisticsView.rows, self.statisticsView.footer) = Self.computeStatistics(for: self.graph)
        }
    }

    private let statisticsView: StatisticsView

    init(graph: FaceWeightedGraph) {
        let header = StatisticsRow(name: "Country", weight: "Weight", area: "Normalized Area", statisticalAccuracy: "Accuracy", localFatness: "Fatness", backgroundColor: nil)
        let (rows, summary) = Self.computeStatistics(for: graph)

        self.graph = graph
        self.statisticsView = StatisticsView(header: header, rows: rows, footer: summary, columns: [\.name, \.weight, \.area, \.statisticalAccuracy, \.localFatness])

        super.init(frame: .zero)

        self.addSubview(self.statisticsView)
        self.statisticsView.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private class func computeStatistics(for graph: FaceWeightedGraph) -> (countries: [StatisticsRow], summary: StatisticsRow) {
        var countries: [StatisticsRow] = []
        let totalweight = graph.faces.map(graph.weight(of:)).reduce(0, +)
        let totalarea = graph.faces.map(graph.area(of:)).reduce(0, +)

        var statisticalAccuracies: [Double] = []
//        var localFatnesses: [Double] = []

        func format(absolute: Double) -> String {
            if round(absolute) == absolute { return "\(Int(absolute))" }
            else { return "\(round(10 * absolute) / 10)" }
        }
        func format(percentage: Double) -> String {
            return "\(round(1e3 * percentage) / 1e1)%"
        }

        for face in graph.faces {
            let name = graph.name(of: face)
            let weight = graph.weight(of: face)
            let area = graph.area(of: face)
            let normalizedArea = (area / totalarea) * totalweight
            let pressure = (weight / totalweight) / (area / totalarea)

            let statisticalAccuracy = min(pressure, 1 / pressure)
            statisticalAccuracies.append(statisticalAccuracy)

            countries.append(StatisticsRow(
                name: "\(name)",
                weight: format(absolute: weight),
                area: format(absolute: normalizedArea),
                statisticalAccuracy: format(percentage: statisticalAccuracy),
                localFatness: nil,
                backgroundColor: UIColor.color(for: name)
            ))
        }

        return (countries, StatisticsRow(
            name: "Summary",
            statisticalAccuracy: format(percentage: statisticalAccuracies.average)
        ))
    }
}

extension Array where Element == Double {
    var average: Double {
        return self.reduce(0, +) / Double(self.count)
    }
}
