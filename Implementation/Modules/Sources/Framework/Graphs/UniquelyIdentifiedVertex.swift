//
//  UniquelyIdentifiedVertex.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 03.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

public struct UniquelyIdentifiedVertex: Hashable, Comparable, CustomStringConvertible, ExpressibleByIntegerLiteral {
    public static func < (lhs: UniquelyIdentifiedVertex, rhs: UniquelyIdentifiedVertex) -> Bool {
        return lhs.id < rhs.id
    }

    private let id: Int

    public init(integerLiteral value: Int) {
        self.id = value
    }

    public init(id: Int) {
        self.id = id
    }

    public var description: String {
        return "\(self.id)"
    }
}

extension UniquelyIdentifiedVertex: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.id = try container.decode(Int.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.id)
    }
}
