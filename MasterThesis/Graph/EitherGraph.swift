//
//  EitherGraph.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 27.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

enum EitherGraph {
    case vertexWeighted(VertexWeightedGraph)
    case faceWeighted(PolygonalDual)
}

extension EitherGraph {
    var vertexWeightedGraph: VertexWeightedGraph? {
        switch self {
        case .vertexWeighted(let graph): return graph
        case .faceWeighted: return nil
        }
    }

    var faceWeightedGraph: PolygonalDual? {
        switch self {
        case .faceWeighted(let graph): return graph
        case .vertexWeighted: return nil
        }
    }
}

extension Optional where Wrapped == EitherGraph {
    var isVertexWeighted: Bool {
        guard case .vertexWeighted = self else { return false }
        return true
    }

    var isFaceWeighted: Bool {
        guard case .faceWeighted = self else { return false }
        return true
    }

    var isEmpty: Bool {
        guard case .none = self else { return false }
        return true
    }
}
