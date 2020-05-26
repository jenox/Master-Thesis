//
//  EitherGraph.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 27.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

public enum EitherGraph {
    case vertexWeighted(VertexWeightedGraph)
    case faceWeighted(PolygonalDual)
}

extension EitherGraph {
    public var vertexWeightedGraph: VertexWeightedGraph? {
        switch self {
        case .vertexWeighted(let graph): return graph
        case .faceWeighted: return nil
        }
    }

    public var faceWeightedGraph: PolygonalDual? {
        switch self {
        case .faceWeighted(let graph): return graph
        case .vertexWeighted: return nil
        }
    }
}

extension Optional where Wrapped == EitherGraph {
    public var isVertexWeighted: Bool {
        guard case .vertexWeighted = self else { return false }
        return true
    }

    public var isFaceWeighted: Bool {
        guard case .faceWeighted = self else { return false }
        return true
    }

    public var isEmpty: Bool {
        guard case .none = self else { return false }
        return true
    }
}
