//
//  Commands.swift
//  CLI
//
//  Created by Christian Schnorr on 08.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Foundation

struct StartCommand: Hashable, Codable {}
struct StopCommand: Hashable, Codable {}

struct ChangeCountryWeightCommand: Hashable, Codable {
    let country: String
    let weight: Double
}
