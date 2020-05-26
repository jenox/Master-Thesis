//
//  CanvasView.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 08.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import UIKit
import Geometry

protocol CanvasRenderer {
    func draw(in context: CGContext, scale: CGFloat, rotation: Angle)
}

class CanvasView: UIView {
    private let dummy = UIView(frame: .zero)

    var renderer: CanvasRenderer? {
        didSet { self.setNeedsDisplay() }
    }


    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.dummy)
        self.configureTransformGesture()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }


    // MARK: - Gestures

    private func configureTransformGesture() {
        self.addGestureRecognizer(TransformGestureRecognizer(target: self, action: #selector(self.transformGestureDidChange)))
    }

    @objc private func transformGestureDidChange(_ recognizer: TransformGestureRecognizer) {
        var transform = recognizer.transform(in: self.dummy)
        transform = self.committedUserTransform.concatenating(transform)

        switch recognizer.state {
        case .began, .changed:
            self.currentUserTransform = transform
        case .ended, .cancelled:
            self.committedUserTransform = transform
        case .possible, .failed:
            fatalError()
        @unknown default:
            break
        }
    }


    // MARK: - Transform

    private var committedUserTransform: CGAffineTransform = .identity {
        didSet { self.currentUserTransform = self.committedUserTransform }
    }

    private var currentUserTransform: CGAffineTransform = .identity {
        didSet { self.setNeedsDisplay() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.dummy.transform = self.normalizingTransform
    }

    private var normalizingTransform: CGAffineTransform {
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: 0, y: bounds.height)
        transform = transform.scaledBy(x: 1, y: -1)
        transform = transform.translatedBy(x: bounds.width / 2, y: bounds.height / 2)

        return transform
    }

    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!

        context.setFillColor(UIColor.white.cgColor)
        context.fill(rect)
        context.concatenate(self.normalizingTransform)
        context.concatenate(self.currentUserTransform)

        let scale = hypot(self.currentUserTransform.a, self.currentUserTransform.b)

        var angle = Angle.acos(self.currentUserTransform.a / scale)
        if self.currentUserTransform.b / scale < 0 { angle = -angle }

        self.renderer?.draw(in: context, scale: scale, rotation: angle)
    }
}
