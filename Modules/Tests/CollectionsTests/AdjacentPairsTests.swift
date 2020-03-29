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

import XCTest
@testable import Collections

final class AdjacentPairsTests: XCTestCase {
    func testAdjacentPairs0() {
        let list: [Int] = []
        let expected: [(Int, Int)] = []

        let pairs = list.adjacentPairs(wraparound: false)

        XCTAssertEqual(pairs.count, expected.count)
        XCTAssertTrue(pairs.elementsEqual(expected, by: ==))
    }

    func testAdjacentPairs1() {
        let list: [Int] = [1]
        let expected: [(Int, Int)] = []

        let pairs = list.adjacentPairs(wraparound: false)

        XCTAssertEqual(pairs.count, expected.count)
        XCTAssertTrue(pairs.elementsEqual(expected, by: ==))
    }

    func testAdjacentPairs2() {
        let list: [Int] = [1, 2]
        let expected: [(Int, Int)] = [(1,2)]

        let pairs = list.adjacentPairs(wraparound: false)

        XCTAssertEqual(pairs.count, expected.count)
        XCTAssertTrue(pairs.elementsEqual(expected, by: ==))
    }

    func testAdjacentPairs3() {
        let list: [Int] = [1, 2, 3]
        let expected: [(Int, Int)] = [(1,2), (2,3)]

        let pairs = list.adjacentPairs(wraparound: false)

        XCTAssertEqual(pairs.count, expected.count)
        XCTAssertTrue(pairs.elementsEqual(expected, by: ==))
    }

    func testAdjacentPairsWraparound0() {
        let list: [Int] = []
        let expected: [(Int, Int)] = []

        let pairs = list.adjacentPairs(wraparound: true)

        XCTAssertEqual(pairs.count, expected.count)
        XCTAssertTrue(pairs.elementsEqual(expected, by: ==))
    }

    func testAdjacentPairsWraparound1() {
        let list: [Int] = [1]
        let expected: [(Int, Int)] = [(1,1)]

        let pairs = list.adjacentPairs(wraparound: true)

        XCTAssertEqual(pairs.count, expected.count)
        XCTAssertTrue(pairs.elementsEqual(expected, by: ==))
    }

    func testAdjacentPairsWraparound2() {
        let list: [Int] = [1, 2]
        let expected: [(Int, Int)] = [(1,2), (2,1)]

        let pairs = list.adjacentPairs(wraparound: true)

        XCTAssertEqual(pairs.count, expected.count)
        XCTAssertTrue(pairs.elementsEqual(expected, by: ==))
    }

    func testAdjacentPairsWraparound3() {
        let list: [Int] = [1, 2, 3]
        let expected: [(Int, Int)] = [(1,2), (2,3), (3,1)]

        let pairs = list.adjacentPairs(wraparound: true)

        XCTAssertEqual(pairs.count, expected.count)
        XCTAssertTrue(pairs.elementsEqual(expected, by: ==))
    }
}
