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

        return SwiftUIGraphView(graph: self.pipeline.graph, forceComputer: self.pipeline.forceComputer)
            .overlay(self.statisticsView.padding(insets), alignment: .bottomLeading)
            .overlay(self.controlView.padding(insets), alignment: .topLeading)
            .overlay(self.forceConfigurationView.padding(insets), alignment: .topTrailing)
    }

    private var controlView: some View {
        return VStack(alignment: .leading, content: {
            Toggle(isOn: self.$pipeline.isSteppingContinuously, label: { Text("Step") })
            Button(action: self.clear, label: { Text("Clear") }).disabled(self.pipeline.graph.isEmpty)
            Button(action: self.loadSmall, label: { Text("Load Small") }).disabled(!self.pipeline.graph.isEmpty)
            Button(action: self.loadLarge, label: { Text("Load Large") }).disabled(!self.pipeline.graph.isEmpty)
            Button(action: self.generateRandom, label: { Text("Generate Random") }).disabled(!self.pipeline.graph.isEmpty)
            Button(action: self.transform, label: { Text("Transform") }).disabled(!self.pipeline.graph.isVertexWeighted)
            Button(action: self.performRandomWeightChange, label: { Text("Random Weight") }).disabled(self.pipeline.graph.isEmpty)
            Button(action: self.performRandomEdgeFlip, label: { Text("Random Flip") }).disabled(self.pipeline.graph.isEmpty)
        }).frame(width: 160, height: nil, alignment: .center)
    }

    private var forceConfigurationView: some View {
        return ConcreteForceComputerConfigurationView(forceComputer: self.$pipeline.forceComputer).frame(width: 400, height: nil, alignment: .center)
    }

    private var statisticsView: some View {
        return SwiftUIGraphStatisticsView(
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

    private func transform() {
        self.pipeline.transformVertexWeightedGraph()
    }

    private func performRandomWeightChange() {
        self.pipeline.performRandomWeightChange()
    }

    private func performRandomEdgeFlip() {
        self.pipeline.performRandomEdgeFlip()
    }
}
