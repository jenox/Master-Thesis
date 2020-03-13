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
        self.graphView = FaceWeightedGraphView(frame: UIScreen.main.bounds, graph: self.graph)
        self.statisticsView = GraphStatisticsView(graph: self.graph)

        super.init(nibName: nil, bundle: nil)

        self.toggle.addTarget(self, action: #selector(self.toggleDidChange), for: .valueChanged)
        self.statisticsView.isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError()
    }


    // MARK: - View Management

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
    private let toggle = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.graphView)
        self.view.addSubview(self.statisticsView)
        self.view.addSubview(self.toggle)

        self.graphView.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })

        self.toggle.snp.makeConstraints({ make in
            make.right.equalToSuperview().inset(40)
            make.top.equalToSuperview().inset(40)
        })

        self.statisticsView.snp.makeConstraints({ make in
            make.left.bottom.equalToSuperview().inset(20)
        })
    }


    // MARK: - Stepping

    @objc private func toggleDidChange() {
        if self.toggle.isOn {
            self.beginSteppingContinuously()
        } else {
            self.endSteppingContinuously()
        }
    }

    private let queue = DispatchQueue(label: "GraphModificationQueue")
    private var isSteppingContinuously: Bool = false
    private var hasScheduledNextSteppingBlock: Bool = false

    func beginSteppingContinuously() {
        self.toggle.setOn(true, animated: true)
        guard !isSteppingContinuously else { return }

        self.isSteppingContinuously = true

        if !self.hasScheduledNextSteppingBlock {
            self.hasScheduledNextSteppingBlock = true

            self.queue.async(execute: self.stepOnceAndScheduleNextIfNeeded)
        }
    }

    func endSteppingContinuously() {
        self.toggle.setOn(false, animated: true)
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

            let forces = ForceComputer().forces(in: graph)
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
