//
//  Vertex.swift
//  DelaunayTriangulationSwift
//
//  Created by Alex Littlejohn on 2016/01/08.
//  Copyright © 2016 zero. All rights reserved.
//

import CoreGraphics

public struct Vertex {

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public func pointValue() -> CGPoint {
        return CGPoint(x: x, y: y)
    }

    public let x: Double
    public let y: Double
}

extension Vertex: Equatable, Hashable {
}

extension Array where Element:Equatable {
    func removeDuplicates() -> [Element] {
        var result = [Element]()

        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }

        return result
    }
}
