//
//  File.swift
//  
//
//  Created by Christian Schnorr on 11.04.20.
//

import Foundation

// https://en.cppreference.com/w/cpp/algorithm/partial_sum
// https://forums.swift.org/t/add-accumulate-scan-to-the-standard-library/19484
// https://forums.swift.org/t/reconsider-adding-scan-i-e-progressively-reduce-a-k-a-iota-partial-sum-reductions-accumulate/32658
// https://forums.swift.org/t/a-running-reduce/20691
// https://stackoverflow.com/questions/35160890/swift-running-sum
// https://developer.apple.com/documentation/swift/lazysequenceprotocol

extension Collection {
    // Eager variant returning a contiguous array.
    func partial_sum(operation: (Element, Element) -> Element) -> [Element] {
        let count = self.count

        var result: [Element] = []
        result.reserveCapacity(count)

        var index = self.startIndex

        for _ in 0..<count {
            if let last = result.last {
                result.append(operation(last, self[index]))
            } else {
                result.append(self[index])
            }

            self.formIndex(after: &index)
        }

        return Array.init(result)
    }
}

extension Sequence {
    func scan<Result>(_ initialResult: Result, _ nextPartialResult: @escaping (Result, Element) throws -> Result) rethrows -> [Result] {
        print("eager")
        var result: [Result] = []
        result.reserveCapacity(self.underestimatedCount)

        for value in self {
            result.append(try nextPartialResult(result.last ?? initialResult, value))
        }

        return result
    }
}

extension LazySequenceProtocol {
    func scan<Result>(_ initialResult: Result, _ nextPartialResult: @escaping (Result, Element) -> Result) -> LazyScanSequence<Elements, Result> {
        print("lazy")
        return LazyScanSequence(base: self.elements, initialResult: initialResult, nextPartialResult: nextPartialResult)
    }
}

struct LazyScanSequence<Base, Result> where Base: Sequence {
    let base: Base
    let initialResult: Result
    let nextPartialResult: (Result, Base.Element) -> Result
}

// we cannot be lazycollection because we cannot guarantee O(1) index access?
extension LazyScanSequence: Sequence {
    typealias Element = Result

    func makeIterator() -> Iterator {
        return Iterator(base: self.base.makeIterator(), initialResult: self.initialResult, lastResult: nil, nextPartialResult: self.nextPartialResult)
    }

    var underestimatedCount: Int {
        return self.base.underestimatedCount
    }

    struct Iterator: IteratorProtocol {
        typealias Element = Result

        var base: Base.Iterator
        let initialResult: Result
        var lastResult: Result?
        let nextPartialResult: (Result, Base.Element) -> Result

        mutating func next() -> Result? {
            guard let next = self.base.next() else { return nil }

            self.lastResult = self.nextPartialResult(self.lastResult ?? self.initialResult, next)

            return self.lastResult
        }
    }
}

extension LazyScanSequence: LazySequenceProtocol {
    typealias Elements = LazyScanSequence<Base, Result>

    var elements: LazyScanSequence<Base, Result> {
        return self
    }
}
