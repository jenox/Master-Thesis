//
//  SwiftUIGraphView.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 27.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import UIKit
import SwiftUI

struct SwiftUIGraphView: View, UIViewRepresentable {
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
