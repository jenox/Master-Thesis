//
//  ContentView.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 23.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var pipeline: PrimaryPipeline

    var body: some View {
        let insets = EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)

        return SwiftUIGraphView(graph: self.pipeline.graph, forceComputer: self.pipeline.forceComputer)
            .overlay(self.statisticsView.padding(insets), alignment: .bottomLeading)
            .overlay(self.controlView.padding(insets), alignment: .topLeading)
            .overlay(self.forceConfigurationView.padding(insets), alignment: .topTrailing)
    }

    private var controlView: some View {
        let binding = Binding(value: self.pipeline.isRunning, enable: self.pipeline.start, disable: self.pipeline.stop)

        return VStack(alignment: .leading, content: {
            Toggle(isOn: binding, label: { Text("Step") })
            Button(action: self.pipeline.clear, label: { Text("Clear") }).disabled(self.pipeline.graph.isEmpty)
            Button(action: self.loadSmall, label: { Text("Load Small") }).disabled(!self.pipeline.graph.isEmpty)
            Button(action: self.loadLarge, label: { Text("Load Large") }).disabled(!self.pipeline.graph.isEmpty)
            Button(action: self.pipeline.generate, label: { Text("Generate") }).disabled(!self.pipeline.graph.isEmpty)
            Button(action: self.pipeline.transform, label: { Text("Transform") }).disabled(!self.pipeline.graph.isVertexWeighted)
            self.actions
        }).frame(width: 180, height: nil, alignment: .center)
    }

    private var forceConfigurationView: some View {
        return ConcreteForceComputerConfigurationView(forceComputer: self.$pipeline.forceComputer).frame(width: 400, height: nil, alignment: .center)
    }

    private var statisticsView: some View {
        return SwiftUIGraphStatisticsView(graph: self.pipeline.graph, qualityMetrics: self.pipeline.qualityMetrics)
    }

    var actions: some View {
        return Group(content: {
            Button(action: self.pipeline.changeRandomCountryWeight, label: { Text("Change Weight") }).disabled(self.pipeline.graph.isEmpty)
            Button(action: self.pipeline.insertRandomVertexInside, label: { Text("Insert Vertex Inside") }).disabled(self.pipeline.graph.isEmpty)
            Button(action: self.pipeline.insertRandomVertexOutside, label: { Text("Insert Vertex Outside") }).disabled(self.pipeline.graph.isEmpty)
            Button(action: self.pipeline.removeRandomInternalVertex, label: { Text("Remove Internal Vertex") }).disabled(self.pipeline.graph.isEmpty)
            Button(action: self.pipeline.removeRandomExternalVertex, label: { Text("Remove External Vertex") }).disabled(self.pipeline.graph.isEmpty)
            Button(action: self.pipeline.flipRandomInternalEdge, label: { Text("Flip Internal Edge") }).disabled(self.pipeline.graph.isEmpty)
            Button(action: self.pipeline.insertRandomEdgeOutside, label: { Text("Insert Edge Outside") }).disabled(self.pipeline.graph.isEmpty)
            Button(action: self.pipeline.removeRandomEdgeOutside, label: { Text("Remove Edge Outside") }).disabled(self.pipeline.graph.isEmpty)
        })
    }

    private func loadSmall() {
        self.pipeline.load(TestGraphs.makeSmallInputGraph())
    }

    private func loadLarge() {
        self.pipeline.load(TestGraphs.makeVoronoiInputGraph())
    }
}

private extension Binding where Value == Bool {
    init(value: @escaping @autoclosure () -> Bool, enable: @escaping () -> Void, disable: @escaping () -> Void) {
        self.init(get: value, set: { newValue in if newValue { enable() } else { disable() } })
    }
}
