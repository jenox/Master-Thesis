//
//  CLIReceiver.swift
//  CLI
//
//  Created by Christian Schnorr on 08.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import UIKit
import MultipeerKit

final class CLIReceiver {
    private let transceiver: MultipeerTransceiver

    init() {
        var config = MultipeerConfiguration.default
        config.serviceType = "listrctl"

        self.transceiver = MultipeerTransceiver(configuration: config)
    }

    func start() {
        transceiver.receive(StartCommand.self, using: response(start(_:)))
        transceiver.receive(StopCommand.self, using: response(stop(_:)))
        transceiver.receive(ChangeCountryWeightCommand.self, using: response(changeCountryWeight))

        transceiver.resume()
    }

    private func response<T: Codable>(_ handler: @escaping (T) -> CLIResponse) -> (T) -> Void {
        return { [weak self] (command: T) in
            let result = handler(command)

            self?.transceiver.broadcast(result)
        }
    }

    private var viewController: ViewController {
        return UIApplication.shared.keyWindow!.rootViewController as! ViewController
    }

    private func start(_ command: StartCommand) -> CLIResponse {
        viewController.beginSteppingContinuously()
        return .message("ok")
    }

    private func stop(_ command: StopCommand) -> CLIResponse {
        viewController.endSteppingContinuously()
        return .message("ok")
    }

    private func changeCountryWeight(_ command: ChangeCountryWeightCommand) -> CLIResponse {
        viewController.performGraphOperation(named: "update weight", as: { graph in
            graph.setWeight(of: command.country, to: command.weight)
        })

        return .message("ok")
    }
}
