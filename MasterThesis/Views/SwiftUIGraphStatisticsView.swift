//
//  SwiftUIGraphStatisticsView.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 27.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import UIKit
import SwiftUI

struct SwiftUIGraphStatisticsView: View, UIViewRepresentable {
    var graph: EitherGraph?
    var qualityMetrics: [(String, QualityEvaluator)]

    typealias UIViewType = UIViewHostingView<GraphStatisticsView>

    func makeUIView(context: UIViewRepresentableContext<SwiftUIGraphStatisticsView>) -> UIViewType {
        let view = GraphStatisticsView(graph: self.graph?.faceWeightedGraph, qualityMetrics: self.qualityMetrics)

        return UIViewHostingView(contentView: view)
    }

    func updateUIView(_ view: UIViewType, context: UIViewRepresentableContext<SwiftUIGraphStatisticsView>) {
        view.contentView.graph = self.graph?.faceWeightedGraph
        view.contentView.qualityMetrics = self.qualityMetrics
    }

    static func dismantleUIView(_ uiView: UIViewType, coordinator: Void) {
    }
}
