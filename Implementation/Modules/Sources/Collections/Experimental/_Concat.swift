/*
 MIT License

 Copyright (c) 2020 Christian Schnorr

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import Swift

public struct Concat<S, T> where S: Collection, T: Collection, S.Element == T.Element {
    @usableFromInline internal let base1: S
    @usableFromInline internal let base2: T

    @inlinable
    public init(_ base1: S, with base2: T) {
        self.base1 = base1
        self.base2 = base2
    }
}

extension Concat: Collection {
    public typealias Element = (S.Element)
    //    public typealias Iterator = IndexingIterator<AdjacentPairs>
    //    public typealias SubSequence = Slice<AdjacentPairs>
    //    public typealias Indices = DefaultIndices<AdjacentPairs>

    public enum Index: Comparable {
        case inFirst(S.Index)
        case inSecond(T.Index)

        @inlinable
        public static func < (lhs: Concat<S, T>.Index, rhs: Concat<S, T>.Index) -> Bool {
            switch (lhs, rhs) {
            case (.inFirst, .inSecond): return true
            case (.inSecond, .inFirst): return false
            case (.inFirst(let lhs), .inFirst(let rhs)): return lhs < rhs
            case (.inSecond(let lhs), .inSecond(let rhs)): return lhs < rhs
            }
        }
    }

    @inlinable
    public var startIndex: Index {
        if self.base1.startIndex == self.base1.endIndex {
            return .inSecond(self.base2.startIndex)
        } else {
            return .inFirst(self.base1.startIndex)
        }
    }

    @inlinable
    public var endIndex: Index {
        return .inSecond(self.base2.endIndex)
    }

    @inlinable
    public func index(after index: Index) -> Index {
        switch index {
        case .inFirst(let index):
            let next = self.base1.index(after: index)
            return next == self.base1.endIndex ? .inSecond(self.base2.startIndex) : .inFirst(next)
        case .inSecond(let index):
            return .inSecond(self.base2.index(after: index))
        }
    }

    @inlinable
    public subscript(position: Index) -> (S.Element) {
        switch position {
        case .inFirst(let index):
            return self.base1[index]
        case .inSecond(let index):
            return self.base2[index]
        }
    }
}

extension Concat: BidirectionalCollection where S: BidirectionalCollection, T: BidirectionalCollection {
    @inlinable
    public func index(before index: Index) -> Index {
        switch index {
        case .inFirst(let index):
            return .inFirst(self.base1.index(before: index))
        case .inSecond(let index):
            if index == self.base2.startIndex {
                return .inFirst(self.base1.indices.last!)
            } else {
                return .inSecond(self.base2.index(before: index))
            }
        }
    }
}
