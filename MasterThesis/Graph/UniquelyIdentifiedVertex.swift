//
//  UniquelyIdentifiedVertex.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 03.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

struct UniquelyIdentifiedVertex: Hashable, CustomStringConvertible, ExpressibleByIntegerLiteral {
    private static var nextID: Int = 0
    private let id: Int

    init(integerLiteral value: Int) {
        self.id = value
    }

    init() {
        self.id = Self.nextID
        Self.nextID += 1
    }

    var description: String {
        return "\(self.id)"
    }
}
