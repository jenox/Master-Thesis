//
//  ClusterName.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 30.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

struct ClusterName: Equatable, Hashable, RawRepresentable {
    let rawValue: String
}

extension ClusterName: Comparable {
    static func < (lhs: ClusterName, rhs: ClusterName) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension ClusterName: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.rawValue = value
    }

    init(extendedGraphemeClusterLiteral value: Character) {
        self.rawValue = String(value)
    }
}

extension ClusterName: CustomStringConvertible {
    var description: String {
        return self.rawValue
    }
}

extension ClusterName: Codable {}
