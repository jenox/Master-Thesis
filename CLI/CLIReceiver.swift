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
        transceiver.receive(StartCommand.self, using: response(start(_:completion:)))
        transceiver.receive(StopCommand.self, using: response(stop(_:completion:)))
        transceiver.receive(ChangeCountryWeightCommand.self, using: response(changeCountryWeight(_:completion:)))
        transceiver.receive(FlipBorderCommand.self, using: response(flipBorder(_:completion:)))


        transceiver.resume()
    }

    private func response<T: Codable>(_ handler: @escaping (T, @escaping (CLIResponse) -> Void) -> Void) -> (T) -> Void {
        return { [weak self] command in
            handler(command, { response in
                self?.transceiver.broadcast(response)
            })
        }
    }

    private func start(_ command: StartCommand, completion: @escaping (CLIResponse) -> Void) {
        viewController.pipeline.isSteppingContinuously = true

        completion(.message("ok"))
    }

    private func stop(_ command: StopCommand, completion: @escaping (CLIResponse) -> Void) {
        viewController.pipeline.isSteppingContinuously = false

        completion(.message("ok"))
    }

    private func changeCountryWeight(_ command: ChangeCountryWeightCommand, completion: @escaping (CLIResponse) -> Void) {
        viewController.pipeline.scheduleMutationOperation(named: "change weight", as: { graph in
            try graph.setWeight(of: command.country, to: command.weight)
        }, completion: self.wrapCompletionHandler(completion))
    }

    private func flipBorder(_ command: FlipBorderCommand, completion: @escaping (CLIResponse) -> Void) {
        viewController.pipeline.scheduleMutationOperation(named: "flip border", as: { graph in
            try graph.flipBorder(between: command.first, and: command.second)
        }, completion: self.wrapCompletionHandler(completion))
    }

    private func wrapCompletionHandler(_ completion: @escaping (CLIResponse) -> Void) -> (Result<Void, Error>) -> Void {
        return { result in
            switch result {
            case .success:
                completion(.message("ok"))
            case .failure(let error):
                completion(.message("error: \(error)"))
            }
        }
    }

    private var viewController: RootViewController {
        return UIApplication.shared.windows.first!.rootViewController as! RootViewController
    }
}
