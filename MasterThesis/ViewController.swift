//
//  ViewController.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 12.01.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    override func loadView() {
        self.view = Canvas(frame: UIScreen.main.bounds)
    }
}

extension Collection where Element == CGPoint {
    var centroid: CGPoint {
        let count = self.isEmpty ? 1 : CGFloat(self.count)
        let x = self.reduce(0, { $0 + $1.x }) / count
        let y = self.reduce(0, { $0 + $1.y  }) / count

        return CGPoint(x: x, y: y)
    }
}

extension CGContext {
    func fill(_ point: CGPoint, diameter: CGFloat, color: UIColor) {
        self.setFillColor(color.cgColor)
        self.fillEllipse(in: CGRect(x: point.x - diameter / 2, y: point.y - diameter / 2, width: diameter, height: diameter))
    }

    func stroke(from source: CGPoint, to target: CGPoint, color: UIColor) {
        self.setStrokeColor(color.cgColor)
        self.beginPath()
        self.move(to: source)
        self.addLine(to: target)
        self.strokePath()
    }
}

class Canvas: UIView {
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!

        context.setFillColor(UIColor.white.cgColor)
        context.fill(rect)

        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: bounds.width / 2, y: bounds.height / 2)

        let edges: [(Character, Character)] = [("A","B"),("A","C"),("B","C"),("B","D"),("C","D")]
        let faces: Set<Set<Character>> = [["A","B","C"],["B","C","D"]]
        let positions: [Character: CGPoint] = [
            "A": CGPoint(x: 0, y: 130),
            "B": CGPoint(x: -75, y: 0),
            "C": CGPoint(x: 75, y: 0),
            "D": CGPoint(x: 0, y: -130)
        ]

        do {
            for (endpoint1, endpoint2) in edges {
                context.stroke(from: positions[endpoint1]!, to: positions[endpoint2]!, color: .black)
            }

            for (_, position) in positions {
                context.fill(position, diameter: 10, color: .blue)
            }
        }

        context.scaleBy(x: 1.25, y: 1.25)

        do {
            for (endpoint1, endpoint2) in edges {
                let faces = faces.filter({ $0.contains(endpoint1) && $0.contains(endpoint2) }) as Array

                if faces.count == 2 {
                    let centroid1 = faces[0].map({ positions[$0]! }).centroid
                    let centroid2 = faces[1].map({ positions[$0]! }).centroid
                    let mid = [centroid1, centroid2].centroid

                    context.stroke(from: mid, to: centroid1, color: .red)
                    context.stroke(from: mid, to: centroid2, color: .red)
                    context.fill(mid, diameter: 10, color: .green)
                } else {
                    let position1 = positions[endpoint1]!
                    let position2 = positions[endpoint2]!
                    let centroid = faces[0].map({ positions[$0]! }).centroid
                    // results in 'degenerate' drawing but guarantees we don't introduce weird crossings
                    let target = [position1, position2].centroid

                    context.stroke(from: centroid, to: target, color: .red)
                    context.stroke(from: target, to: position1, color: .red)
                    context.stroke(from: target, to: position2, color: .red)
                    context.fill(target, diameter: 10, color: .green)
                    context.fill(position1, diameter: 10, color: .green) // we fill those twice...
                    context.fill(position2, diameter: 10, color: .green) // we fill those twice...
                }
            }

            for face in faces {
                let positions = face.map({ positions[$0]! })
                context.fill(positions.centroid, diameter: 10, color: .green)
            }
        }
    }
}
