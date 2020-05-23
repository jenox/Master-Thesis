//
//  UniquelyIdentifiedVertex.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 03.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

struct UniquelyIdentifiedVertex: Hashable, Comparable, CustomStringConvertible, ExpressibleByIntegerLiteral {
    static func < (lhs: UniquelyIdentifiedVertex, rhs: UniquelyIdentifiedVertex) -> Bool {
        return lhs.id < rhs.id
    }

    private let id: Int

    init(integerLiteral value: Int) {
        self.id = value
    }

    init(id: Int) {
        self.id = id
    }

    var description: String {
        return "\(self.id)"
    }
}

extension UniquelyIdentifiedVertex: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.id = try container.decode(Int.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.id)
    }
}
