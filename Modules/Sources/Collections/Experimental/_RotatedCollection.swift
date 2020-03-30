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

// Trivial implementation as concat of two!
// But: loses ability to index by base indices. though we might want that?
public struct RotatedCollection<Base> where Base: Collection {
    private let base: Base
    private let _indices: Concat<Base.Indices, Base.Indices>

    fileprivate init(base: Base, middle: Base.Index) {
        self.base = base
        self._indices = Concat(base.indices[middle...], with: base.indices[..<middle])
    }
}

extension RotatedCollection: Collection {
    public typealias Element = Base.Element
    public typealias Index = Concat<Base.Indices, Base.Indices>.Index
    public typealias Iterator = IndexingIterator<RotatedCollection>
    public typealias SubSequence = Slice<RotatedCollection>
    public typealias Indices = DefaultIndices<RotatedCollection>

    public var startIndex: Index {
        return self._indices.startIndex
    }

    public var endIndex: Index {
        return self._indices.endIndex
    }

    public func index(after index: Index) -> Index {
        return self._indices.index(after: index)
    }

    public subscript(position: Index) -> Base.Element {
        return self.base[self._indices[position]]
    }

    // Overload to prevent deep nesting of RotatedCollection<_>
    //    public func rotated(shiftingToStart middle: Index) -> RotatedCollection<Base> {
    //        fatalError()
    ////        return RotatedCollection(base: self, middle: middle)
    //    }
}

extension RotatedCollection: BidirectionalCollection where Base: BidirectionalCollection {
    public func index(before index: Index) -> Index {
        return self._indices.index(before: index)
    }
}
// TODO: Conditional RandomAccessCollection conformance.

extension Collection {
    public func rotated(shiftingToStart middle: Index) -> RotatedCollection<Self> {
        return RotatedCollection(base: self, middle: middle)
    }
}
