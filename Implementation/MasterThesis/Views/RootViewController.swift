//
//  RootViewController.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 23.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import SwiftUI
import Framework

typealias PrimaryPipeline = Pipeline<DelaunayGraphGenerator, NaiveTransformer, PrEdForceApplicator>

class RootViewController: UIHostingController<AnyView> {
    let pipeline: PrimaryPipeline = .init(
        generator: DelaunayGraphGenerator(numberOfCountries: 10, nestingRatio: 0, nestingBias: 0),
        transformer: NaiveTransformer(),
        forceApplicator: PrEdForceApplicator(),
//        qualityMetrics: [
//            ("Statistical Accuracy", StatisticalAccuracy()),
////            ("Distance from Circumcircle", DistanceFromCircumcircle()),
////            ("Distance from Hull", DistanceFromConvexHull()),
////            ("Entropy of Angles", EntropyOfAngles()),
////            ("Entropy of Distances", EntropyOfDistancesFromCentroid()),
//        ],
        randomNumberGenerator: AnyRandomNumberGenerator(SystemRandomNumberGenerator())
    )

    init() {
        super.init(rootView: AnyView(ContentView().environmentObject(self.pipeline)))
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}
