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

// TODO: Naming. Wraparound, circular, cyclic, looping?
public struct AdjacentTriplets<Base> where Base: BidirectionalCollection {
    @usableFromInline internal let base: Base
    @usableFromInline internal let wraparound: Bool

    @usableFromInline
    internal init(base: Base, wraparound: Bool) {
        self.base = base
        self.wraparound = wraparound
    }
}

extension AdjacentTriplets: BidirectionalCollection {
    public typealias Element = (Base.Element, Base.Element, Base.Element)
    public typealias Iterator = IndexingIterator<AdjacentTriplets>
    public typealias SubSequence = Slice<AdjacentTriplets>
    public typealias Indices = DefaultIndices<AdjacentTriplets>

    public struct Index: Comparable {
        @usableFromInline internal var index: Base.Index

        @usableFromInline
        internal init(index: Base.Index) {
            self.index = index
        }

        @inlinable
        public static func < (lhs: Index, rhs: Index) -> Bool {
            return lhs.index < rhs.index
        }
    }

    @inlinable
    public var startIndex: Index {
        return Index(index: self.base.startIndex)
    }

    @inlinable
    public var endIndex: Index {
        if self.wraparound {
            return Index(index: self.base.endIndex)
        } else {
            let startIndex = self.base.startIndex
            let endIndex = self.base.endIndex

            if let requiredIndex = self.base.index(endIndex, offsetBy: -3, limitedBy: startIndex) {
                return Index(index: self.base.index(after: requiredIndex))
            } else {
                return Index(index: startIndex)
            }
        }
    }

    @inlinable
    public func index(after index: Index) -> Index {
        // TODO: Prevent advancement past endIndex for non-wraparound?
        return Index(index: self.base.index(after: index.index))
    }

    @inlinable
    public func index(before index: Index) -> Index {
        return Index(index: self.base.index(before: index.index))
    }

    @inlinable
    public subscript(position: Index) -> (Base.Element, Base.Element, Base.Element) {
        let circulator = Circulator(base: self.base)

        let firstIndex = position.index
        let secondIndex = circulator.index(firstIndex, offsetBy: 1)
        let thirdIndex = circulator.index(secondIndex, offsetBy: 1)

        return (self.base[firstIndex], self.base[secondIndex], self.base[thirdIndex])
    }
}

public extension BidirectionalCollection {
    @inlinable
    func adjacentTriplets(wraparound: Bool) -> AdjacentTriplets<Self> {
        return AdjacentTriplets(base: self, wraparound: wraparound)
    }
}
