//
//  RootViewController.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 23.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import SwiftUI

class RootViewController: UIHostingController<AnyView> {
    let pipeline = Pipeline()

    init() {
        super.init(rootView: AnyView(ContentView().environmentObject(self.pipeline)))
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}
