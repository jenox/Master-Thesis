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
        subcommands: [GenerateUUIDsCommand.self, RunThroughPipelineCommand.self, EvaluateCommand.self, BenchmarkCommand.self]
    )
}

#if DEBUG
print("Running in debug mode")
#elseif RELEASE
print("Running in release mode")
#endif

TopLevelCommand.main()
