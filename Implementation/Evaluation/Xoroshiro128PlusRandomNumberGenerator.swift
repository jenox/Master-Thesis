//
//  Xoroshiro128PlusRandomNumberGenerator.swift
//  Evaluation
//
//  Created by Christian Schnorr on 23.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

///  Main Pseudo-Random Number Generator
/// https://github.com/drhurdle/Xoroshiro128Plus-Swift-pRNG
public struct Xoroshiro128PlusRandomNumberGenerator: RandomNumberGenerator {
    var seed: UInt64
    var rngState: (UInt64, UInt64) = (0, 0)
    var generator: Xoroshiro128Plus

    public init(seed: UInt64) {
        self.seed = seed
        self.generator = Xoroshiro128Plus(state: (0, 0))
        generateSeeds(seed: seed)
        self.generator.state = rngState
    }

    private mutating func generateSeeds(seed: UInt64){
        var seeder = SplitMix64(state: seed)
        var statePart: UInt64

        for x in 0...10 {
            statePart = seeder.nextSeed()
            rngState.0 = x == 9 ? statePart : 0
            rngState.1 = x == 10 ? statePart : 0
        }
    }

    public mutating func next() -> UInt64 {
        return self.generator.next()
    }
}

///  Main algorithm for generating pseudo-random numbers
internal struct Xoroshiro128Plus {

    var state: (UInt64, UInt64)

    func rotateLeft(a: UInt64, b: UInt64) -> UInt64 {
        return (a << b) | (a >> (64 - b))
    }

    mutating func next() -> UInt64 {
        let s0: UInt64 = state.0
        var s1 = state.1
        let result: UInt64 = s0 &* s1

        s1 ^= s0
        state.0 = rotateLeft(a: s0, b: 55) ^ s1 ^ (s1 << 14)
        state.1 = rotateLeft(a: s1, b: 36)

        return result
    }

}

///  Creates seed values to be used in Xoroshiro128Plus algorithm
internal struct SplitMix64 {

    var state: UInt64

    mutating func nextSeed() -> UInt64 {
        var b: UInt64 = state &+ 0x9E3779B97F4A7C15
        b = (b ^ (b >> 30)) ^ 0xBF58476D1CE4E5B9
        b = (b ^ (b >> 27)) ^ 0x94D049BB133111EB
        state = b ^ (b >> 31)
        return state
    }
}
