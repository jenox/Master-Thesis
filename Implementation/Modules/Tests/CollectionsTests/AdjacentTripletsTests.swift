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

final class AdjacentTripletsTests: XCTestCase {
    func testAdjacentTriplets0() {
        let list: [Int] = []
        let expected: [(Int, Int, Int)] = []

        let triplets = list.adjacentTriplets(wraparound: false)

        XCTAssertEqual(triplets.count, expected.count)
        XCTAssertTrue(triplets.elementsEqual(expected, by: ==))
    }

    func testAdjacentTriplets1() {
        let list: [Int] = [1]
        let expected: [(Int, Int, Int)] = []

        let triplets = list.adjacentTriplets(wraparound: false)

        XCTAssertEqual(triplets.count, expected.count)
        XCTAssertTrue(triplets.elementsEqual(expected, by: ==))
    }

    func testAdjacentTriplets2() {
        let list: [Int] = [1, 2]
        let expected: [(Int, Int, Int)] = []

        let triplets = list.adjacentTriplets(wraparound: false)

        XCTAssertEqual(triplets.count, expected.count)
        XCTAssertTrue(triplets.elementsEqual(expected, by: ==))
    }

    func testAdjacentTriplets3() {
        let list: [Int] = [1, 2, 3]
        let expected: [(Int, Int, Int)] = [(1,2,3)]

        let triplets = list.adjacentTriplets(wraparound: false)

        XCTAssertEqual(triplets.count, expected.count)
        XCTAssertTrue(triplets.elementsEqual(expected, by: ==))
    }

    func testAdjacentTriplets4() {
        let list: [Int] = [1, 2, 3, 4]
        let expected: [(Int, Int, Int)] = [(1,2,3), (2,3,4)]

        let triplets = list.adjacentTriplets(wraparound: false)

        XCTAssertEqual(triplets.count, expected.count)
        XCTAssertTrue(triplets.elementsEqual(expected, by: ==))
    }

    func testAdjacentTripletsWraparound0() {
        let list: [Int] = []
        let expected: [(Int, Int, Int)] = []

        let triplets = list.adjacentTriplets(wraparound: true)

        XCTAssertEqual(triplets.count, expected.count)
        XCTAssertTrue(triplets.elementsEqual(expected, by: ==))
    }

    func testAdjacentTripletsWraparound1() {
        let list: [Int] = [1]
        let expected: [(Int, Int, Int)] = [(1,1,1)]

        let triplets = list.adjacentTriplets(wraparound: true)

        XCTAssertEqual(triplets.count, expected.count)
        XCTAssertTrue(triplets.elementsEqual(expected, by: ==))
    }

    func testAdjacentTripletsWraparound2() {
        let list: [Int] = [1, 2]
        let expected: [(Int, Int, Int)] = [(1,2,1), (2,1,2)]

        let triplets = list.adjacentTriplets(wraparound: true)

        XCTAssertEqual(triplets.count, expected.count)
        XCTAssertTrue(triplets.elementsEqual(expected, by: ==))
    }

    func testAdjacentTripletsWraparound3() {
        let list: [Int] = [1, 2, 3]
        let expected: [(Int, Int, Int)] = [(1,2,3), (2,3,1), (3,1,2)]

        let triplets = list.adjacentTriplets(wraparound: true)

        XCTAssertEqual(triplets.count, expected.count)
        XCTAssertTrue(triplets.elementsEqual(expected, by: ==))
    }

    func testAdjacentTripletsWraparound4() {
        let list: [Int] = [1, 2, 3, 4]
        let expected: [(Int, Int, Int)] = [(1,2,3), (2,3,4), (3,4,1), (4,1,2)]

        let triplets = list.adjacentTriplets(wraparound: true)

        XCTAssertEqual(triplets.count, expected.count)
        XCTAssertTrue(triplets.elementsEqual(expected, by: ==))
    }
}
