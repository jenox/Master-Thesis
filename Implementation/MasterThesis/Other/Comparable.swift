//
//  Other.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 22.02.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }

    mutating func formMinimum(with other: Self) {
        self = min(self, other)
    }

    mutating func formMaximum(with other: Self) {
        self = max(self, other)
    }
}
