//
//  Errors.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 24.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

public struct UnsupportedOperationError: Error {
    public init(file: StaticString = #file, line: Int = #line) {
        self.file = file
        self.line = line
    }

    let file: StaticString
    let line: Int
}
