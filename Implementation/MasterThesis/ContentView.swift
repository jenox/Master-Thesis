//
//  ContentView.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 23.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import SwiftUI
import Framework

struct ContentView: View {
    @EnvironmentObject private var pipeline: PrimaryPipeline

    var body: some View {
        let insets = EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)

        return SwiftUIGraphView(graph: self.pipeline.graph, forceApplicator: self.pipeline.forceApplicator)
            .overlay(self.controlView.padding(insets), alignment: .topLeading)
            .overlay(self.forceConfigurationView.padding(insets), alignment: .topTrailing)
    }

    private var controlView: some View {
        let binding = Binding(value: self.pipeline.isRunning, enable: self.pipeline.start, disable: self.pipeline.stop)

        return VStack(alignment: .leading, content: {
            Button(action: self.pipeline.undo, label: { Text("Undo") }).disabled(self.pipeline.previousGraph == nil)
            Toggle(isOn: binding, label: { Text("Step") })
            Button(action: { self.pipeline.clear() }, label: { Text("Clear") }).disabled(self.pipeline.graph.isEmpty)
            Button(action: self.loadSmall, label: { Text("Load Small") }).disabled(!self.pipeline.graph.isEmpty)
            Button(action: self.loadLarge, label: { Text("Load Large") }).disabled(!self.pipeline.graph.isEmpty)
            Button(action: self.pipeline.generate, label: { Text("Generate") }).disabled(!self.pipeline.graph.isEmpty)
            Button(action: self.pipeline.transform, label: { Text("Transform") }).disabled(!self.pipeline.graph.isVertexWeighted)
            self.dynamicOperationsView.disabled(!self.pipeline.graph.isFaceWeighted)
        }).frame(width: 190, height: nil, alignment: .center)
    }

    private var forceConfigurationView: some View {
        if self.pipeline.graph.isFaceWeighted {
            return AnyView(PrEdForceApplicatorConfigurationView(forceApplicator: self.$pipeline.forceApplicator).frame(width: 400, height: nil, alignment: .center))
        } else {
            return AnyView(EmptyView())
        }
    }

    private var dynamicOperationsView: some View {
        return Group(content: {
            Button(action: self.pipeline.changeRandomCountryWeight, label: { Text("Change Weight") })
            Button(action: self.pipeline.insertRandomVertexInside, label: { Text("Insert Vertex Inside") })
            Button(action: self.pipeline.insertRandomVertexOutside, label: { Text("Insert Vertex Outside") })
            Button(action: self.pipeline.removeRandomInternalVertex, label: { Text("Remove Internal Vertex") })
            Button(action: self.pipeline.removeRandomExternalVertex, label: { Text("Remove External Vertex") })
            Button(action: self.pipeline.flipRandomInternalEdge, label: { Text("Flip Internal Edge") })
            Button(action: self.pipeline.insertRandomEdgeOutside, label: { Text("Insert Edge Outside") })
            Button(action: self.pipeline.removeRandomEdgeOutside, label: { Text("Remove Edge Outside") })
        })
    }

    private func loadSmall() {
        self.pipeline.load(TestGraphs.makeSmallInputGraph())
    }

    private func loadLarge() {
        self.pipeline.load(TestGraphs.makeVoronoiInputGraph())
    }
}

private struct PrEdForceApplicatorConfigurationView: View {
    var forceApplicator: Binding<PrEdForceApplicator>

    var body: some View {
        return VStack(content: {
            self.logarithmicSlider(value: self.forceApplicator.airPressureStrength, range: 1e-2...1e1, text: "Air Pressure")
            self.logarithmicSlider(value: self.forceApplicator.angularResolutionStrength, range: 1e-2...1e2, text: "Angular Resolution")
            self.logarithmicSlider(value: self.forceApplicator.vertexVertexRepulsionStrength, range: 1e-2...1e3, text: "V-V Repulsion")
            self.logarithmicSlider(value: self.forceApplicator.vertexEdgeRepulsionStrength, range: 1e-2...1e3, text: "V-E Repulsion")
        })
    }

    private func logarithmicSlider(value: Binding<CGFloat>, range: ClosedRange<CGFloat>, text: String) -> Slider<EmptyView, AnyView> {
        let binding = Binding(get: { log10(value.wrappedValue) }, set: { value.wrappedValue = pow(10, $0) })
        let range = log10(range.lowerBound)...log10(range.upperBound)
        let minimumValueLabel = AnyView(Text(verbatim: text))
        let maximumValueLabel = AnyView(EmptyView())

        return Slider(value: binding, in: range, minimumValueLabel: minimumValueLabel, maximumValueLabel: maximumValueLabel, label: { EmptyView() })
    }
}

private struct SwiftUIGraphView: View, UIViewRepresentable {
    var graph: EitherGraph?
    var forceApplicator: PrEdForceApplicator

    func makeUIView(context: UIViewRepresentableContext<SwiftUIGraphView>) -> GraphView {
        return GraphView(frame: UIScreen.main.bounds, graph: self.graph, forceApplicator: self.forceApplicator)
    }

    func updateUIView(_ view: GraphView, context: UIViewRepresentableContext<SwiftUIGraphView>) {
        view.graph = self.graph
        view.forceApplicator = self.forceApplicator
    }

    static func dismantleUIView(_ uiView: GraphView, coordinator: Void) {
    }
}

private extension Binding where Value == Bool {
    init(value: @escaping @autoclosure () -> Bool, enable: @escaping () -> Void, disable: @escaping () -> Void) {
        self.init(get: value, set: { newValue in if newValue { enable() } else { disable() } })
    }
}
