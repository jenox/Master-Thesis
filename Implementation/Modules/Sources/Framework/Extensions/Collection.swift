//
//  Created by Christian Schnorr on 26.05.20.
//

import Swift
import Collections

extension Collection {
    func min<T>(by closure: (Element) throws -> T) rethrows -> Element? where T: Comparable {
        return try self.map({ ($0, try closure($0)) }).min(by: { $0.1 < $1.1 })?.0
    }

    func max<T>(by closure: (Element) throws -> T) rethrows -> Element? where T: Comparable {
        return try self.map({ ($0, try closure($0)) }).max(by: { $0.1 < $1.1 })?.0
    }

    func firstIndexOfMinimum<T>(by transform: (Element) throws -> T) rethrows -> Index? where T: Comparable {
        return try self.indices.map({ ($0, try transform(self[$0])) }).min(by: { $0.1 < $1.1 })?.0
    }

    func firstIndexOfMaximum<T>(by transform: (Element) throws -> T) rethrows -> Index? where T: Comparable {
        return try self.indices.map({ ($0, try transform(self[$0])) }).max(by: { $0.1 < $1.1 })?.0
    }

    func count(where predicate: (Element) throws -> Bool) rethrows -> Int {
        return try self.reduce(0, { $0 + (try predicate($1) ? 1 : 0) })
    }

    func destructured1() -> (Element)? {
        let array = Array(self)
        return array.count == 1 ? (array[0]) : nil
    }

    func destructured2() -> (Element, Element)? {
        let array = Array(self)
        return array.count == 2 ? (array[0], array[1]) : nil
    }

    func destructured3() -> (Element, Element, Element)? {
        let array = Array(self)
        return array.count == 3 ? (array[0], array[1], array[2]) : nil
    }
}

extension Collection where Element: Equatable {
    func rotated(shiftingElementToStart element: Element) -> RotatedCollection<Self> {
        return self.rotated(shiftingToStart: self.firstIndex(of: element)!)
    }
}
