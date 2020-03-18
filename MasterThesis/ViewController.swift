//
//  ViewController.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 12.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import UIKit
import SnapKit

class ViewController: UIViewController {

    // MARK: - Initialization

    init() {
        self.graphView = FaceWeightedGraphView(frame: UIScreen.main.bounds, graph: self.graph, forceComputer: self.forceComputer)
        self.statisticsView = GraphStatisticsView(graph: self.graph)

        self.floatSettingViews = [
            .init(title: "V-V Repulsion", value: self.forceComputer.force1Strength, range: 1e-2...1e3),
            .init(title: "V-V Attraction", value: self.forceComputer.force2Strength, range: 1e-2...1e1),
            .init(title: "V-E Repulsion", value: self.forceComputer.force3Strength, range: 1e-2...1e3),
            .init(title: "Pressure", value: self.forceComputer.force4Strength, range: 1e-2...1e1),
            .init(title: "Angle", value: self.forceComputer.force5Strength, range: 1e-2...1e2)
        ]

        super.init(nibName: nil, bundle: nil)

        self.stepToggle.addTarget(self, action: #selector(self.toggleDidChange), for: .valueChanged)
        self.floatSettingViews.forEach({ $0.valueChanged = { [weak self] in self?.forceSettingDidChange()} })
        self.statisticsView.isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError()
    }


    // MARK: - View Management

    var forceComputer: ForceComputer = .init() {
        didSet { self.graphView.forceComputer = self.forceComputer }
    }

//    var graph = ViewController.makeSmallInputGraph().subdividedDual() {
    var graph = ViewController.makeVoronoiInputGraph().subdividedDual() {
        didSet {
            DispatchQueue.main.async(execute: {
                self.graphView.graph = self.graph
                self.statisticsView.graph = self.graph
            })
        }
    }

    private let graphView: FaceWeightedGraphView
    private let statisticsView: GraphStatisticsView
    private let stepToggle = UISwitch()
    private let floatSettingViews: [FloatSettingView]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.graphView)
        self.view.addSubview(self.statisticsView)
        self.view.addSubview(self.stepToggle)
        self.floatSettingViews.forEach(self.view.addSubview(_:))

        self.graphView.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })

        self.stepToggle.snp.makeConstraints({ make in
            make.top.left.equalToSuperview().inset(40)
        })

        self.floatSettingViews.first!.snp.makeConstraints({ make in
            make.top.equalToSuperview().inset(40)
            make.right.equalToSuperview().inset(20)
        })

        for (above, below) in zip(self.floatSettingViews, self.floatSettingViews.dropFirst()) {
            below.snp.makeConstraints({ make in
                make.top.equalTo(above.snp.bottom).offset(10)
                make.right.equalTo(above)
            })
        }

        self.statisticsView.snp.makeConstraints({ make in
            make.left.bottom.equalToSuperview().inset(20)
        })
    }

    @objc private func forceSettingDidChange() {
        self.forceComputer.force1Strength = self.floatSettingViews[0].value
        self.forceComputer.force2Strength = self.floatSettingViews[1].value
        self.forceComputer.force3Strength = self.floatSettingViews[2].value
        self.forceComputer.force4Strength = self.floatSettingViews[3].value
        self.forceComputer.force5Strength = self.floatSettingViews[4].value
    }


    // MARK: - Stepping

    @objc private func toggleDidChange() {
        if self.stepToggle.isOn {
            self.beginSteppingContinuously()
        } else {
            self.endSteppingContinuously()
        }
    }

    private let queue = DispatchQueue(label: "GraphModificationQueue")
    private var isSteppingContinuously: Bool = false
    private var hasScheduledNextSteppingBlock: Bool = false

    func beginSteppingContinuously() {
        self.stepToggle.setOn(true, animated: true)
        guard !isSteppingContinuously else { return }

        self.isSteppingContinuously = true

        if !self.hasScheduledNextSteppingBlock {
            self.hasScheduledNextSteppingBlock = true

            self.queue.async(execute: self.stepOnceAndScheduleNextIfNeeded)
        }
    }

    func endSteppingContinuously() {
        self.stepToggle.setOn(false, animated: true)
        isSteppingContinuously = false
    }

    private func stepOnceAndScheduleNextIfNeeded() {
        DispatchQueue.main.async(execute: {
            self.hasScheduledNextSteppingBlock = false
        })

        self.scheduleGraphOperation(named: "step", as: { graph in
            for (u, v) in graph.edges {
                guard graph.contains(u) && graph.contains(v) else { continue } // may have been removed in previous contract operation
                guard graph.distance(from: u, to: v) < 2 else { continue } // must be close enough

                graph.contractEdgeIfPossible(between: u, and: v)
            }

            let forces = self.forceComputer.forces(in: graph)
            ForceApplicator().apply(forces, to: &graph)
        }, completion: { _ in })

        DispatchQueue.main.async(execute: {
            if self.isSteppingContinuously && !self.hasScheduledNextSteppingBlock {
                self.queue.asyncAfter(deadline: .now() + 0.05, execute: self.stepOnceAndScheduleNextIfNeeded)
            }
        })
    }

    func scheduleGraphOperation(named name: String, as transform: @escaping (inout FaceWeightedGraph) throws -> Void, completion: @escaping (Result<Void, Error>) -> Void) {
        self.queue.async(execute: {
            let result: Result<Void, Error>
            defer { DispatchQueue.main.async(execute: { completion(result) }) }

            let before = CACurrentMediaTime()
            do {
                try transform(&self.graph)
                result = .success(())
            } catch let error {
                result = .failure(error)
            }
            let after = CACurrentMediaTime()

            print("Performed operation in \(String(format: "%.3f", 1e3 * (after - before)))ms: \(name)")
        })
    }


    // MARK: - Test Graphs

    private class func makeVoronoiInputGraph() -> VertexWeightedGraph {
        var graph = VertexWeightedGraph()
        graph.insert("A", at: CGPoint(x: -100, y: 150), weight: 34)
        graph.insert("B", at: CGPoint(x: 0, y: 150), weight: 5)
        graph.insert("C", at: CGPoint(x: 100, y: 150), weight: 21)
        graph.insert("D", at: CGPoint(x: -150, y: 50), weight: 8)
        graph.insert("E", at: CGPoint(x: -50, y: 50), weight: 8)
        graph.insert("F", at: CGPoint(x: 50, y: 50), weight: 5)
        graph.insert("G", at: CGPoint(x: 150, y: 50), weight: 8)
        graph.insert("H", at: CGPoint(x: -100, y: -50), weight: 5)
        graph.insert("I", at: CGPoint(x: 0, y: -50), weight: 13)
        graph.insert("J", at: CGPoint(x: 100, y: -50), weight: 21)
        graph.insert("K", at: CGPoint(x: -50, y: -150), weight: 8)
        graph.insert("L", at: CGPoint(x: 50, y: -150), weight: 8)

        graph.insertEdge(between: "A", and: "B")
        graph.insertEdge(between: "B", and: "C")
        graph.insertEdge(between: "D", and: "E")
        graph.insertEdge(between: "E", and: "F")
        graph.insertEdge(between: "F", and: "G")
        graph.insertEdge(between: "H", and: "I")
        graph.insertEdge(between: "I", and: "J")
        graph.insertEdge(between: "K", and: "L")
        graph.insertEdge(between: "A", and: "D")
        graph.insertEdge(between: "A", and: "E")
        graph.insertEdge(between: "B", and: "E")
        graph.insertEdge(between: "B", and: "F")
        graph.insertEdge(between: "C", and: "F")
        graph.insertEdge(between: "C", and: "G")
        graph.insertEdge(between: "D", and: "H")
        graph.insertEdge(between: "E", and: "H")
        graph.insertEdge(between: "E", and: "I")
        graph.insertEdge(between: "F", and: "I")
        graph.insertEdge(between: "F", and: "J")
        graph.insertEdge(between: "G", and: "J")
        graph.insertEdge(between: "H", and: "K")
        graph.insertEdge(between: "I", and: "K")
        graph.insertEdge(between: "I", and: "L")
        graph.insertEdge(between: "J", and: "L")

        return graph
    }

    private class func makeSmallInputGraph() -> VertexWeightedGraph {
        var graph = VertexWeightedGraph()
        graph.insert("A", at: CGPoint(x: 0, y: 130), weight: 34)
        graph.insert("B", at: CGPoint(x: -75, y: 0), weight: 5)
        graph.insert("C", at: CGPoint(x: 75, y: 0), weight: 21)
        graph.insert("D", at: CGPoint(x: 0, y: -130), weight: 8)
        graph.insertEdge(between: "A", and: "B")
        graph.insertEdge(between: "A", and: "C")
        graph.insertEdge(between: "B", and: "C")
        graph.insertEdge(between: "B", and: "D")
        graph.insertEdge(between: "C", and: "D")

        graph.insert("E", at: CGPoint(x: 0, y: 50), weight: 13)
        graph.insertEdge(between: "E", and: "A")
        graph.insertEdge(between: "E", and: "B")
        graph.insertEdge(between: "E", and: "C")

        return graph
    }
}
