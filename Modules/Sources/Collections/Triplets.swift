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

// TODO: Make this implement BidirectionalCollection.
// TODO: Relax requirement to BidirectionalCollection.
public struct Triplets<Base> where Base: RandomAccessCollection {
    @usableFromInline internal let base: Base
    @usableFromInline internal let mode: CombinationMode

    @usableFromInline
    internal init(base: Base, mode: CombinationMode) {
        self.base = base
        self.mode = mode
    }

    @usableFromInline
    internal enum CombinationMode {
        case cartesian // any indices
        case triangular // nondecreasing indices
        case strictlyTriangular // increasing indices
    }
}

extension Triplets: Collection {
    public typealias Element = (Base.Element, Base.Element, Base.Element)
    public typealias Iterator = IndexingIterator<Triplets>
    public typealias SubSequence = Slice<Triplets>
    public typealias Indices = DefaultIndices<Triplets>

    public enum Index: Comparable, CustomDebugStringConvertible {
        case pastEnd
        case inRange(Int, Int, Int)

        @inlinable
        public static func < (lhs: Index, rhs: Index) -> Bool {
            switch (lhs, rhs) {
            case (.pastEnd, .pastEnd), (.pastEnd, .inRange):
                return false
            case (.inRange, .pastEnd):
                return true
            case (.inRange(let a, let b, let c), .inRange(let d, let e, let f)):
                return (a, b, c) < (d, e, f)
            }
        }

        @inlinable
        public var debugDescription: String {
            switch self {
            case .pastEnd:
                return ".pastEnd"
            case .inRange(let a, let b, let c):
                return ".inRange(\(a), \(b), \(c))"
            }
        }
    }

    @inlinable
    public var startIndex: Index {
        let count = self.base.count

        switch self.mode {
        case .cartesian:
            return count <= 0 ? .pastEnd : .inRange(0, 0, 0)
        case .triangular:
            return count <= 0 ? .pastEnd : .inRange(0, 0, 0)
        case .strictlyTriangular:
            return count <= 2 ? .pastEnd : .inRange(0, 1, 2)
        }
    }

    @inlinable
    public var endIndex: Index {
        return .pastEnd
    }

    @inlinable
    public func index(after index: Index) -> Index {
        guard case .inRange(let first, let second, let third) = index else { preconditionFailure() }

        let count = self.base.count

        switch self.mode {
        case .cartesian:
            if third + 1 < count {
                return .inRange(first, second, third + 1)
            } else if second + 1 < count {
                return .inRange(first, second + 1, 0)
            } else if first + 1 < count {
                return .inRange(first + 1, 0, 0)
            } else {
                return .pastEnd
            }
        case .triangular:
            if third + 1 < count {
                return .inRange(first, second, third + 1)
            } else if second + 1 < count {
                return .inRange(first, second + 1, second + 1)
            } else if first + 1 < count {
                return .inRange(first + 1, first + 1, first + 1)
            } else {
                return .pastEnd
            }
        case .strictlyTriangular:
            if third + 1 < count {
                return .inRange(first, second, third + 1)
            } else if second + 2 < count {
                return .inRange(first, second + 1, second + 2)
            } else if first + 3 < count {
                return .inRange(first + 1, first + 2, first + 3)
            } else {
                return .pastEnd
            }
        }
    }

    @inlinable
    public func index(before index: Index) -> Index {
        fatalError()
    }

    @inlinable
    public subscript(position: Index) -> Element {
        guard case .inRange(let first, let second, let third) = position else { preconditionFailure() }

        let firstIndex = self.base.index(self.base.startIndex, offsetBy: first)
        let secondIndex = self.base.index(self.base.startIndex, offsetBy: second)
        let thirdIndex = self.base.index(self.base.startIndex, offsetBy: third)

        return (self.base[firstIndex], self.base[secondIndex], self.base[thirdIndex])
    }
}

public extension RandomAccessCollection {
    @inlinable
    func cartesianTriplets() -> Triplets<Self> {
        return Triplets(base: self, mode: .cartesian)
    }

    @inlinable
    func triangularTriplets() -> Triplets<Self> {
        return Triplets(base: self, mode: .triangular)
    }

    @inlinable
    func strictlyTriangularTriplets() -> Triplets<Self> {
        return Triplets(base: self, mode: .strictlyTriangular)
    }
}
