//
//  TransformGestureRecognizer.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 08.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import UIKit

class TransformGestureRecognizer: UIGestureRecognizer {

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        let numberOfTrackedTouches = self.trackedTouchOrigins.count

        if numberOfTrackedTouches < 2 {
            let newTouches = Set(self.trackedTouchOrigins.keys).union(touches.prefix(2 - numberOfTrackedTouches))

            self.commitSubgestureBeingTracked()
            self.startTrackingSubgesture(with: newTouches)
        }

        for touch in touches.dropFirst(2 - numberOfTrackedTouches) {
            self.ignore(touch, for: event)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        self.continueTrackingTouches()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        let remainingTouches = Set(self.trackedTouchOrigins.keys).subtracting(touches)

        self.commitSubgestureBeingTracked()

        if !remainingTouches.isEmpty {
            self.startTrackingSubgesture(with: remainingTouches)
        }

        self.continueTrackingTouches()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        let remainingTouches = Set(self.trackedTouchOrigins.keys).subtracting(touches)

        self.commitSubgestureBeingTracked()

        if !remainingTouches.isEmpty {
            self.startTrackingSubgesture(with: remainingTouches)
        }

        self.continueTrackingTouches()
    }

    override func reset() {
        self.committedSubgestures.removeAll()
        self.trackedTouchOrigins.removeAll()
    }


    // MARK: - Logic

    private var committedSubgestures: [Subgesture] = []
    private var trackedTouchOrigins: [UITouch: CGPoint] = [:]

    private func continueTrackingTouches() {
        switch self.state {
        case .possible:
            let transform = self.transform(in: UIScreen.main.fixedCoordinateSpace)

            if self.shouldStartGesture(for: transform) {
                self.state = .began
            }
        case .began, .changed:
            if self.trackedTouchOrigins.isEmpty {
                self.state = .ended
            } else {
                self.state = .changed
            }
        case .ended, .cancelled, .failed:
            preconditionFailure()
        @unknown default:
            break
        }
    }

    private var subgestureBeingTracked: Subgesture? {
        let moves = self.trackedTouchOrigins.map({ Movement(from: $0.value, to: $0.key.location(in: $0.key.window!), in: $0.key.window!) })

        if let first = moves.first, let second = moves.dropFirst().first {
            return .twoFingers(first, second)
        } else if let first = moves.first {
            return .oneFinger(first)
        } else {
            return nil
        }
    }

    private func commitSubgestureBeingTracked() {
        if let subgesture = self.subgestureBeingTracked {
            self.committedSubgestures.append(subgesture)
        }

        self.trackedTouchOrigins.removeAll()
    }

    private func startTrackingSubgesture(with touches: Set<UITouch>) {
        self.trackedTouchOrigins = Dictionary(uniqueKeysWithValues: touches.map({ ($0, $0.location(in: nil)) }))
    }

    private func shouldStartGesture(for transform: CGAffineTransform) -> Bool {
        return true
    }


    // MARK: - Public Interface

    func transform(in coordinateSpace: UICoordinateSpace) -> CGAffineTransform {
        let transforms = self.committedSubgestures.map({ $0.transform(in: coordinateSpace) })
        var transform = transforms.reduce(CGAffineTransform.identity, { $0.concatenating($1) })

        if let subgesture = self.subgestureBeingTracked {
            transform = transform.concatenating(subgesture.transform(in: coordinateSpace))
        }

        return transform
    }
}

private enum Subgesture {
    case oneFinger(Movement)
    case twoFingers(Movement, Movement)

    func transform(in coordinateSpace: UICoordinateSpace) -> CGAffineTransform {
        switch self {
        case .oneFinger(let movement):
            let displacement = movement.displacement(in: coordinateSpace)
            let tx = displacement.end.x - displacement.start.x
            let ty = displacement.end.y - displacement.start.y

            return CGAffineTransform(translationX: tx, y: ty)
        case .twoFingers(let touch1, let touch2):
            let displacement1 = touch1.displacement(in: coordinateSpace)
            let displacement2 = touch2.displacement(in: coordinateSpace)

            let (p_0, p_1) = (displacement1.start, displacement1.end)
            let (q_0, q_1) = (displacement2.start, displacement2.end)

            let phase_0 = atan2(q_0.y - p_0.y, q_0.x - p_0.x)
            let phase_1 = atan2(q_1.y - p_1.y, q_1.x - p_1.x)
            let phi = phase_1 - phase_0

            let distance_0 = hypot(q_0.x - p_0.x, q_0.y - p_0.y)
            let distance_1 = hypot(q_1.x - p_1.x, q_1.y - p_1.y)
            let scale = distance_1 / distance_0

            let a = scale * cos(phi)
            let b = scale * sin(phi)
            let c = scale * -sin(phi)
            let d = scale * cos(phi)
            let tx = p_1.x - a * p_0.x - c * p_0.y
            let ty = p_1.y - b * p_0.x - d * p_0.y

            return CGAffineTransform(a: a, b: b, c: c, d: d, tx: tx, ty: ty)
        }
    }
}

// TouchMovement
private struct Movement {
    init(from start: CGPoint, to end: CGPoint, in window: UIWindow) {
        self.start = start
        self.end = end
        self.window = window
    }

    let start: CGPoint
    let end: CGPoint
    let window: UIWindow

    func displacement(in coordinateSpace: UICoordinateSpace) -> Displacement {
        let start = coordinateSpace.convert(self.start, from: self.window)
        let end = coordinateSpace.convert(self.end, from: self.window)

        return Displacement(from: start, to: end)
    }
}

// InterpolationRules
private struct Displacement {
    init(from start: CGPoint, to end: CGPoint) {
        self.start = start
        self.end = end
    }

    let start: CGPoint
    let end: CGPoint
}
