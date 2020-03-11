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
        let metrics = QualityMetricComputer().qualityMetrics(in: graph)
        var countries: [StatisticsRow] = []

        func format(absolute: Double) -> String {
            if round(absolute) == absolute { return "\(Int(absolute))" }
            else { return "\(round(10 * absolute) / 10)" }
        }

        func format(percentage: Double) -> String {
            return "\(round(1e3 * percentage) / 1e1)%"
        }

        for (name, metrics) in metrics.sorted(by: { $0.0 < $1.0 }) {
            countries.append(StatisticsRow(
                name: "\(name)",
                weight: format(absolute: metrics.weight),
                area: format(absolute: metrics.normalizedArea),
                statisticalAccuracy: format(percentage: metrics.statisticalAccuracy),
                localFatness: format(percentage: metrics.localFatness),
                backgroundColor: UIColor.color(for: name.first!)
            ))
        }

        return (countries, StatisticsRow(
            name: "Summary",
            statisticalAccuracy: format(percentage: metrics.map({ $0.1.statisticalAccuracy }).average),
            localFatness: format(percentage: metrics.map({ $0.1.localFatness }).average)
        ))
    }
}

extension Array where Element == Double {
    var average: Double {
        return self.reduce(0, +) / Double(self.count)
    }
}
