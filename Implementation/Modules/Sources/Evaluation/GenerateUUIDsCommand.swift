//
//  GenerateUUIDsCommand.swift
//  Evaluation
//
//  Created by Christian Schnorr on 23.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Foundation
import ArgumentParser

struct GenerateUUIDsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate"
    )

    @Option(default: 100, help: "") private var numberOfIdentifiers: Int
    @Option(help: "") private var outputFile: URL

    func validate() throws {
        guard self.numberOfIdentifiers >= 1 else { throw ValidationError("") }
    }

    func run() throws {
        var text = ""

        for _ in 0..<self.numberOfIdentifiers {
            text.append(UUID().uuidString)
            text.append("\n")
        }

        try text.data(using: .utf8)!.write(to: self.outputFile)
    }
}
