//
//  GraphStatisticsView.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 09.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import UIKit

class GraphStatisticsView: UIView {
    var graph: FaceWeightedGraph? {
        didSet { self.statisticsView.rows = self.graph?.faces.map({ (self.graph, $0) }) ?? [] }
    }

    var qualityMetrics: [(String, QualityEvaluator)] {
        didSet { self.statisticsView.columns[3...] = ArraySlice(self.qualityMetrics.map(Self.column(for:))) }
    }

    private let statisticsView: StatisticsView<(FaceWeightedGraph?, FaceWeightedGraph.Face)>

    init(graph: FaceWeightedGraph?, qualityMetrics: [(String, QualityEvaluator)]) {
        self.graph = graph
        self.qualityMetrics = qualityMetrics

        self.statisticsView = StatisticsView(rows: graph?.faces.map({ (graph, $0) }) ?? [], columns: [
            Self.column(named: "Country", value: { Self.name(of: $1, in: $0) }),
            Self.column(named: "Weight", value: { Self.weight(of: $1, in: $0) }),
            Self.column(named: "Normalized Area", value: { Self.normalizedArea(of: $1, in: $0) }),
        ] + qualityMetrics.map(Self.column(for:)))

        super.init(frame: .zero)

        self.addSubview(self.statisticsView)
        self.statisticsView.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private class func column(named name: String, value: @escaping (FaceWeightedGraph?, FaceWeightedGraph.Face) throws -> String) -> Column<(FaceWeightedGraph?, FaceWeightedGraph.Face)> {
        return .init(title: name, value: { try value($0.0, $0.1) }, backgroundColor: { UIColor.color(for: $0.1) })
    }

    private class func column(for qualityMetric: (name: String, evaluator: QualityEvaluator)) -> Column<(FaceWeightedGraph?, FaceWeightedGraph.Face)> {
        return .init(title: qualityMetric.name, value: { graph, face in
            switch try qualityMetric.evaluator.quality(of: face, in: graph!) {
            case .integer(let value): return self.format(integer: value)
            case .percentage(let value): return self.format(percentage: value)
            }
        }, backgroundColor: { UIColor.color(for: $0.1) })
    }

    private class func name(of face: FaceWeightedGraph.Face, in graph: FaceWeightedGraph?) -> String {
        return face
    }

    private class func weight(of face: FaceWeightedGraph.Face, in graph: FaceWeightedGraph?) -> String {
        guard let graph = graph else { return "" }

        return Self.format(double: graph.weight(of: face))
    }

    private class func normalizedArea(of face: FaceWeightedGraph.Face, in graph: FaceWeightedGraph?) -> String {
        guard let graph = graph else { return "" }

        let totalweight = graph.faces.map(graph.weight(of:)).reduce(0, +)
        let totalarea = graph.faces.map(graph.area(of:)).reduce(0, +)
        let area = graph.area(of: face)
        let normalizedArea = (area / totalarea) * totalweight

        return Self.format(double: normalizedArea)
    }

    private class func format(integer: Int) -> String {
        return "\(integer)"
    }

    private class func format(double: Double) -> String {
        if round(10 * double) == 10 * double { return "\(Int(double))" }
        else { return "\(round(10 * double) / 10)" }
    }

    private class func format(percentage: Double) -> String {
        return "\(round(1e3 * percentage) / 1e1)%"
    }
}
