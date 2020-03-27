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
    var forceComputer: ConcreteForceComputer

    func makeUIView(context: UIViewRepresentableContext<SwiftUIGraphView>) -> GraphView {
        return GraphView(frame: UIScreen.main.bounds, graph: self.graph, forceComputer: self.forceComputer)
    }

    func updateUIView(_ view: GraphView, context: UIViewRepresentableContext<SwiftUIGraphView>) {
        view.graph = self.graph
        view.forceComputer = self.forceComputer
    }

    static func dismantleUIView(_ uiView: GraphView, coordinator: Void) {
    }
}
