//
//  ContentView.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 23.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var pipeline: Pipeline

    var body: some View {
        let insets = EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)

        return GraphView(graph: self.pipeline.graph, forceComputer: self.pipeline.forceComputer)
            .overlay(self.statisticsView.padding(insets), alignment: .bottomLeading)
            .overlay(self.controlView.padding(insets), alignment: .topLeading)
            .overlay(self.forceConfigurationView.padding(insets), alignment: .topTrailing)
    }

    private var controlView: some View {
        return VStack(alignment: .leading, content: {
            Toggle(isOn: self.$pipeline.isSteppingContinuously, label: { Text("Step") })
            Button(action: self.clear, label: { Text("Clear") })
            Button(action: self.loadSmall, label: { Text("Small") })
            Button(action: self.loadLarge, label: { Text("Large") })
            Button(action: self.generateRandom, label: { Text("Random") })
        }).frame(width: 160, height: nil, alignment: .center)
    }

    private var forceConfigurationView: some View {
        return ConcreteForceComputerConfigurationView(forceComputer: self.$pipeline.forceComputer).frame(width: 400, height: nil, alignment: .center)
    }

    private var statisticsView: some View {
        return StatisticsViewWrapper(
            graph: self.pipeline.graph,
            statisticalAccuracyMetric: self.pipeline.statisticalAccuracyMetric,
            distanceFromCircumcircleMetric: self.pipeline.distanceFromCircumcircleMetric,
            distanceFromConvexHullMetric: self.pipeline.distanceFromConvexHullMetric,
            entropyOfAnglesMetric: self.pipeline.entropyOfAnglesMetric,
            entropyOfDistancesFromCentroidMetric: self.pipeline.entropyOfDistancesFromCentroidMetric
        )
    }

    private func clear() {
        self.pipeline.clearGraph()
    }

    private func loadSmall() {
        self.pipeline.replaceGraph(with: TestGraphs.makeSmallInputGraph())
    }

    private func loadLarge() {
        self.pipeline.replaceGraph(with: TestGraphs.makeVoronoiInputGraph())
    }

    private func generateRandom() {
        self.pipeline.generateNewGraph()
    }
}


struct GraphView: View, UIViewRepresentable {
    var graph: FaceWeightedGraph?
    var forceComputer: ConcreteForceComputer

    func makeUIView(context: UIViewRepresentableContext<GraphView>) -> FaceWeightedGraphView {
        return FaceWeightedGraphView(frame: UIScreen.main.bounds, graph: self.graph, forceComputer: self.forceComputer)
    }

    func updateUIView(_ view: FaceWeightedGraphView, context: UIViewRepresentableContext<GraphView>) {
        view.graph = self.graph
        view.forceComputer = self.forceComputer
    }

    static func dismantleUIView(_ uiView: FaceWeightedGraphView, coordinator: Void) {
    }
}

struct StatisticsViewWrapper: View, UIViewRepresentable {
    var graph: FaceWeightedGraph?

    var statisticalAccuracyMetric: StatisticalAccuracy
    var distanceFromCircumcircleMetric: DistanceFromCircumcircle
    var distanceFromConvexHullMetric: DistanceFromConvexHull
    var entropyOfAnglesMetric: EntropyOfAngles
    var entropyOfDistancesFromCentroidMetric: EntropyOfDistancesFromCentroid

    typealias UIViewType = WrapperView<GraphStatisticsView>

    func makeUIView(context: UIViewRepresentableContext<StatisticsViewWrapper>) -> UIViewType {
        let view = GraphStatisticsView(graph: self.graph, qualityMetrics: self.qualityMetrics)

        return WrapperView(contentView: view)
    }

    func updateUIView(_ view: UIViewType, context: UIViewRepresentableContext<StatisticsViewWrapper>) {
        view.contentView.graph = self.graph
        view.contentView.qualityMetrics = self.qualityMetrics
    }

    static func dismantleUIView(_ uiView: UIViewType, coordinator: Void) {
    }

    private var qualityMetrics: [(String, QualityEvaluator)] {
        return [
            ("Statistical Accuracy", self.statisticalAccuracyMetric),
            ("Distance from Circumcircle", self.distanceFromCircumcircleMetric),
            ("Distance from Hull", self.distanceFromConvexHullMetric),
            ("Entropy of Angles", self.entropyOfAnglesMetric),
            ("Entropy of Distances", self.entropyOfDistancesFromCentroidMetric),
        ]
    }
}

class WrapperView<ContentView>: UIView where ContentView: UIView {
    let contentView: ContentView
    init(contentView: ContentView) {
        self.contentView = contentView
        super.init(frame: contentView.bounds)
        self.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.setContentHuggingPriority(.required, for: .horizontal)
        self.setContentHuggingPriority(.required, for: .vertical)
        self.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override var intrinsicContentSize: CGSize {
        return contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }
}
