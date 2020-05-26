//
//  Pipeline+Operations.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 22.05.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import Swift

extension PolygonalDual {
    private enum DynamicOperationKind: CaseIterable {
        case insertFaceInside
        case insertFaceOutside
        case removeFaceWithoutBoundaryToExternalFace
        case removeFaceWithBoundaryToExternalFace
        case flipAdjacency
        case createAdjacency
        case removeAdjacency
    }

    public enum AnyDynamicOperation: Hashable {
        case insertFaceInside(PolygonalDual.InsertFaceInsideOperation)
        case insertFaceOutside(PolygonalDual.InsertFaceOutsideOperation)
        case removeFaceWithoutBoundaryToExternalFace(PolygonalDual.RemoveFaceWithoutBoundaryToExternalFaceOperation)
        case removeFaceWithBoundaryToExternalFace(PolygonalDual.RemoveFaceWithBoundaryToExternalFaceOperation)
        case flipAdjacency(PolygonalDual.FlipAdjacencyOperation)
        case createAdjacency(PolygonalDual.CreateAdjacencyOperation)
        case removeAdjacency(PolygonalDual.RemoveAdjacencyOperation)
    }

    public func randomDynamicOperation<T>(name: ClusterName, weight: ClusterWeight, using generator: inout T) -> AnyDynamicOperation where T: RandomNumberGenerator {
        var operations: Set<AnyDynamicOperation> = []

        while operations.isEmpty {
            switch PolygonalDual.DynamicOperationKind.allCases.randomElement(using: &generator)! {
            case .insertFaceInside:
                for op in self.possibleInsertFaceInsideOperations(name: name, weight: weight) { operations.insert(.insertFaceInside(op)) }

            case .insertFaceOutside:
                for op in self.possibleInsertFaceOutsideOperations(name: name, weight: weight) { operations.insert(.insertFaceOutside(op)) }

            case .removeFaceWithoutBoundaryToExternalFace:
                for op in self.possibleRemoveFaceWithoutBoundaryToExternalFaceOperations() { operations.insert(.removeFaceWithoutBoundaryToExternalFace(op)) }

            case .removeFaceWithBoundaryToExternalFace:
                for op in self.possibleRemoveFaceWithBoundaryToExternalFaceOperations() { operations.insert(.removeFaceWithBoundaryToExternalFace(op)) }

            case .flipAdjacency:
                for op in self.possibleFlipAdjacencyOperations() { operations.insert(.flipAdjacency(op)) }

            case .createAdjacency:
                for op in self.possibleCreateAdjacencyOperations() { operations.insert(.createAdjacency(op)) }

            case .removeAdjacency:
                for op in self.possibleRemoveAdjacencyOperations() { operations.insert(.removeAdjacency(op)) }
            }
        }

        return operations.randomElement(using: &generator)!
    }

    public mutating func apply(_ operation: AnyDynamicOperation) throws {
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
