//
//  Result.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 29.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
}
