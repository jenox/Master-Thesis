//
//  Pipeline+Operations.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 22.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift



extension PolygonalDual {
    enum AnyDynamicOperation: Hashable {
        case insertFaceInside(PolygonalDual.InsertFaceInsideOperation)
        case insertFaceOutside(PolygonalDual.InsertFaceOutsideOperation)
        case removeFaceWithoutBoundaryToExternalFace(PolygonalDual.RemoveFaceWithoutBoundaryToExternalFaceOperation)
        case removeFaceWithBoundaryToExternalFace(PolygonalDual.RemoveFaceWithBoundaryToExternalFaceOperation)
        case flipAdjacency(PolygonalDual.FlipAdjacencyOperation)
        case createAdjacency(PolygonalDual.CreateAdjacencyOperation)
        case removeAdjacency(PolygonalDual.RemoveAdjacencyOperation)
    }

    func possibleDynamicOperations(name: ClusterName, weight: ClusterWeight) -> Set<AnyDynamicOperation> {
        var operations: Set<AnyDynamicOperation> = []

        for op in self.possibleInsertFaceInsideOperations(name: name, weight: weight) { operations.insert(.insertFaceInside(op)) }
        for op in self.possibleInsertFaceOutsideOperations(name: name, weight: weight) { operations.insert(.insertFaceOutside(op)) }
        for op in self.possibleRemoveFaceWithoutBoundaryToExternalFaceOperations() { operations.insert(.removeFaceWithoutBoundaryToExternalFace(op)) }
        for op in self.possibleRemoveFaceWithBoundaryToExternalFaceOperations() { operations.insert(.removeFaceWithBoundaryToExternalFace(op)) }
        for op in self.possibleFlipAdjacencyOperations() { operations.insert(.flipAdjacency(op)) }
        for op in self.possibleCreateAdjacencyOperations() { operations.insert(.createAdjacency(op)) }
        for op in self.possibleRemoveAdjacencyOperations() { operations.insert(.removeAdjacency(op)) }

        return operations
    }

    mutating func apply(_ operation: AnyDynamicOperation) throws {
        switch operation {
        case .insertFaceInside(let operation): try self.insertFaceInside(operation)
        case .insertFaceOutside(let operation): try self.insertFaceOutside(operation)
        case .removeFaceWithoutBoundaryToExternalFace(let operation): try self.removeFaceWithoutBoundaryToExternalFace(operation)
        case .removeFaceWithBoundaryToExternalFace(let operation): try self.removeFaceWithBoundaryToExternalFace(operation)
        case .flipAdjacency(let operation): try self.flipAdjacency(operation)
        case .createAdjacency(let operation): try self.createAdjacency(operation)
        case .removeAdjacency(let operation): try self.removeAdjacency(operation)
        }
    }
}
