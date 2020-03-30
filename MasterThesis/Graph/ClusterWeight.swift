//
//  ClusterWeight.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 30.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

struct ClusterWeight: Equatable, Hashable, Comparable, RawRepresentable {
    let rawValue: Double

    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        return .init(rawValue: lhs.rawValue + rhs.rawValue)
    }
}

extension ClusterWeight: ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    init(integerLiteral value: Int) {
        self.rawValue = Double(value)
    }

    init(floatLiteral value: Double) {
        self.rawValue = value
    }
}
