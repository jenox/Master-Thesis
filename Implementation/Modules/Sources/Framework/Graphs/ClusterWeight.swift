//
//  ClusterWeight.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 30.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

public struct ClusterWeight: Equatable, Hashable, Comparable, RawRepresentable {
    public init(rawValue: Double) {
        self.rawValue = rawValue
    }

    public let rawValue: Double

    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    public static func + (lhs: Self, rhs: Self) -> Self {
        return .init(rawValue: lhs.rawValue + rhs.rawValue)
    }

    public static func * (lhs: Double, rhs: Self) -> Self {
        return .init(rawValue: lhs * rhs.rawValue)
    }
}

extension ClusterWeight: ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    public init(integerLiteral value: Int) {
        self.rawValue = Double(value)
    }

    public init(floatLiteral value: Double) {
        self.rawValue = value
    }
}

extension ClusterWeight: CustomStringConvertible {
    public var description: String {
        return "\(self.rawValue)"
    }
}

extension ClusterWeight: Codable {}
