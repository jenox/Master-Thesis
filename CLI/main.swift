//
//  main.swift
//  CLI
//
//  Created by Christian Schnorr on 08.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Foundation
import ArgumentParser

CLITransmitter.current.start()

struct ListrCTL: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "listrctl",
        abstract: "",
        subcommands: [Start.self, Stop.self, ChangeCountryWeight.self]
    )

    struct Start: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "start",
            abstract: ""
        )

        func run() throws {
            send(StartCommand())
        }
    }

    struct Stop: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "stop",
            abstract: ""
        )

        func run() throws {
            send(StopCommand())
        }
    }

    struct ChangeCountryWeight: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "weight",
            abstract: ""
        )

        @Argument(help: "") var country: String
        @Argument(help: "") var weight: Double

        func run() throws {
            send(ChangeCountryWeightCommand(country: country, weight: weight))
        }
    }
}

ListrCTL.main()
