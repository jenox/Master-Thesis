//
//  File.swift
//  
//
//  Created by Christian Schnorr on 28.03.20.
//

import CoreGraphics

public struct Circle {
    public var center: CGPoint
    public var radius: CGFloat

    public init(center: CGPoint, radius: CGFloat) {
        self.center = center
        self.radius = radius
    }
}
