//
//  StringInterpolation.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 28.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Darwin

extension String.StringInterpolation {
    mutating func appendInterpolation(formatted value: Double) {
        self.appendInterpolation(round(value * 10) / 10)
    }
}
