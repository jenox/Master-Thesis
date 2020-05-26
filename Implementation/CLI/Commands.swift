//
//  Commands.swift
//  CLI
//
//  Created by Christian Schnorr on 08.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Foundation

struct StartCommand: Codable {}

struct StopCommand: Codable {}

struct ChangeCountryWeightCommand: Codable {
    let country: String
    let weight: Double
}

struct FlipBorderCommand: Codable {
    let first: String
    let second: String
}
