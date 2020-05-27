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

struct CLI: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "CLI",
        abstract: "Interact with the GUI",
        subcommands: [Start.self, Stop.self, ChangeCountryWeight.self, FlipBorder.self]
    )

    struct Start: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "start",
            abstract: "Start the optimization algorithm"
        )

        func run() throws {
            send(StartCommand())
        }
    }

    struct Stop: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "stop",
            abstract: "Stop the optimization algorithm"
        )

        func run() throws {
            send(StopCommand())
        }
    }

    struct ChangeCountryWeight: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "weight",
            abstract: "Change a country's weight"
        )

        @Argument(help: "The country whose weight to change") var country: String
        @Argument(help: "The country's new weight") var weight: Double

        func run() throws {
            send(ChangeCountryWeightCommand(country: country, weight: weight))
        }
    }

    struct FlipBorder: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "flip",
            abstract: "Flip an internal border"
        )

        @Argument() var first: String
        @Argument() var second: String

        func run() throws {
            send(FlipBorderCommand(first: first, second: second))
        }
    }
}

CLI.main()
