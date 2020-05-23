//
//  main.swift
//  Evaluation
//
//  Created by Christian Schnorr on 22.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Foundation
import ArgumentParser

private struct TopLevelCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "evaluate",
        subcommands: [GenerateUUIDsCommand.self, RunThroughPipelineCommand.self, EvaluateCommand.self]
    )
}

TopLevelCommand.main()
