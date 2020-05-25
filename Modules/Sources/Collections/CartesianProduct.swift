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

public struct CartesianProduct<Base1, Base2> where Base1: Collection, Base2: Collection {
    @usableFromInline internal let base1: Base1
    @usableFromInline internal let base2: Base2

    @usableFromInline
    internal init(base1: Base1, base2: Base2) {
        self.base1 = base1
        self.base2 = base2
    }
}

extension CartesianProduct: Collection {
    public typealias Element = (Base1.Element, Base2.Element)
    public typealias Iterator = IndexingIterator<CartesianProduct>
    public typealias SubSequence = Slice<CartesianProduct>
    public typealias Indices = DefaultIndices<CartesianProduct>

    public struct Index: Comparable, CustomDebugStringConvertible {
        @usableFromInline internal var index1: Base1.Index
        @usableFromInline internal var index2: Base2.Index

        @usableFromInline
        internal init(index1: Base1.Index, index2: Base2.Index) {
            self.index1 = index1
            self.index2 = index2
        }

        @inlinable
        public static func < (lhs: Index, rhs: Index) -> Bool {
            return (lhs.index1, lhs.index2) < (rhs.index1, rhs.index2)
        }

        @inlinable
        public var debugDescription: String {
            return "(\(self.index1), \(self.index2))"
        }
    }

    @inlinable
    public var startIndex: Index {
        let index = Index(index1: self.base1.startIndex, index2: self.base2.startIndex)
        return self.wraparound(index)
    }

    @inlinable
    public var endIndex: Index {
        return Index(index1: self.base1.endIndex, index2: self.base2.startIndex)
    }

    @inlinable
    public func index(after index: Index) -> Index {
        let index = Index(index1: index.index1, index2: self.base2.index(after: index.index2))
        return self.wraparound(index)
    }

    @inlinable
    public subscript(position: Index) -> (Base1.Element, Base2.Element) {
        return (self.base1[position.index1], self.base2[position.index2])
    }

    @usableFromInline
    internal func wraparound(_ index: Index) -> Index {
        var index = index
        while index.index2 == self.base2.endIndex && index.index1 < self.base1.endIndex {
            index = Index(index1: self.base1.index(after: index.index1), index2: self.base2.startIndex)
        }
        return index
    }
}

public extension Collection {
    @inlinable
    func cartesianProduct<T>(with other: T) -> CartesianProduct<Self, T> where T: Collection {
        return CartesianProduct(base1: self, base2: other)
    }
}
