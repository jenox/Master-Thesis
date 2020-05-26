//
//  ClusterName.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 30.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

public struct ClusterName: Equatable, Hashable, RawRepresentable {
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public let rawValue: String
}

extension ClusterName: Comparable {
    public static func < (lhs: ClusterName, rhs: ClusterName) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension ClusterName: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public init(extendedGraphemeClusterLiteral value: Character) {
        self.rawValue = String(value)
    }
}

extension ClusterName: CustomStringConvertible {
    public var description: String {
        return self.rawValue
    }
}

extension ClusterName: Codable {}
