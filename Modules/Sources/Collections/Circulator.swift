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

// TODO: Check with CGAL behavior. Is that also infinite?
public struct Circulator<Base> where Base: Collection {
    private let base: Base
    private var index: Base.Index

    public init(base: Base) {
        self.base = base
        self.index = base.startIndex
    }

    public func index(_ index: Base.Index, offsetBy distance: Int) -> Base.Index {
        var index = index

        // TODO: what if distance is negative? Extend to BidirectionalCollection?
        for _ in 0..<distance {
            if index == self.base.endIndex {
                index = self.base.startIndex
            } else {
                let next = self.base.index(after: index)
                if next == self.base.endIndex {
                    index = self.base.startIndex
                } else {
                    index = next
                }
            }
        }

        return index
    }
}

extension Circulator: IteratorProtocol {
    public typealias Element = Base.Element

    public mutating func next() -> Element? {
        if self.index == self.base.endIndex {
            return nil
        } else {
            defer { self.index = self.index(self.index, offsetBy: 1) }
            return self.base[index]
        }
    }
}
