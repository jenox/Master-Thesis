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

if ProcessInfo.processInfo.environment["SWIFT_DETERMINISTIC_HASHING"] != "1" {
    print("Please turn on deterministic hashing:")
    print("export SWIFT_DETERMINISTIC_HASHING=\"1\"")
    fatalError()
}

#if DEBUG
print("Warning: running in debug mode!")
#endif

TopLevelCommand.main()
