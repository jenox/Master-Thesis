//
//  RootViewController.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 23.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import SwiftUI

typealias PrimaryPipeline = Pipeline<DelaunayGraphGenerator, NaiveTransformer, ConcreteForceComputer, PrEdForceApplicator>

class RootViewController: UIHostingController<AnyView> {
    let pipeline: PrimaryPipeline = .init(
        generator: DelaunayGraphGenerator(countries: OrderedSet(Array("ABCDEFGHIJKLMNOPQ").map(ClusterName.init)), nestingRatio: 0.3, nestingBias: 0.5),
        transformer: NaiveTransformer(),
        forceComputer: ConcreteForceComputer(),
        forceApplicator: PrEdForceApplicator(),
        qualityMetrics: [
            ("Statistical Accuracy", StatisticalAccuracy()),
            ("Distance from Circumcircle", DistanceFromCircumcircle()),
            ("Distance from Hull", DistanceFromConvexHull()),
            ("Entropy of Angles", EntropyOfAngles()),
            ("Entropy of Distances", EntropyOfDistancesFromCentroid()),
        ],
        randomNumberGenerator: AnyRandomNumberGenerator(SystemRandomNumberGenerator())
    )

    init() {
        super.init(rootView: AnyView(ContentView().environmentObject(self.pipeline)))
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}
