//
//  Other.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 22.02.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift
import Collections

extension Comparable {
    mutating func formMinimum(with other: Self) {
        self = min(self, other)
    }

    mutating func formMaximum(with other: Self) {
        self = max(self, other)
    }
}

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
}
