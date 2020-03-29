//
//  AnyRandomNumberGenerator.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 27.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

struct AnyRandomNumberGenerator: RandomNumberGenerator {
    private(set) var generator: RandomNumberGenerator

    init<T>(_ generator: T) where T: RandomNumberGenerator {
        self.generator = generator
    }

    mutating func next() -> UInt64 {
        return self.generator.next()
    }
}
