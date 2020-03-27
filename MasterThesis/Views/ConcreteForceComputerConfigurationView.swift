//
//  ConcreteForceComputerConfigurationView.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 23.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import SwiftUI

struct ConcreteForceComputerConfigurationView: View {
    var forceComputer: Binding<ConcreteForceComputer>

    var body: some View {
        return VStack(content: {
            self.logarithmicSlider(value: self.forceComputer.force1Strength, range: 1e-2...1e3, text: "V-V Repulsion")
            self.logarithmicSlider(value: self.forceComputer.force2Strength, range: 1e-2...1e1, text: "V-V Attraction")
            self.logarithmicSlider(value: self.forceComputer.force3Strength, range: 1e-2...1e3, text: "V-E Repulsion")
            self.logarithmicSlider(value: self.forceComputer.force4Strength, range: 1e-2...1e1, text: "Pressure")
            self.logarithmicSlider(value: self.forceComputer.force5Strength, range: 1e-2...1e2, text: "Angle")
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