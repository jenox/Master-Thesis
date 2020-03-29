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

final class PairsTests: XCTestCase {
    func testCartesianPairs0() {
        let list: [Int] = []
        let expected: [(Int, Int)] = []

        let pairs = list.cartesianPairs()

        XCTAssertEqual(pairs.count, expected.count)
        XCTAssertTrue(pairs.elementsEqual(expected, by: ==))
    }

    func testCartesianPairs1() {
        let list: [Int] = [1]
        let expected: [(Int, Int)] = [(1,1)]

        let pairs = list.cartesianPairs()

        XCTAssertEqual(pairs.count, expected.count)
        XCTAssertTrue(pairs.elementsEqual(expected, by: ==))
    }

    func testCartesianPairs2() {
        let list: [Int] = [1, 2]
        let expected: [(Int, Int)] = [(1,1), (1,2), (2,1), (2,2)]

        let pairs = list.cartesianPairs()

        XCTAssertEqual(pairs.count, expected.count)
        XCTAssertTrue(pairs.elementsEqual(expected, by: ==))
    }

    func testCartesianPairs3() {
        let list: [Int] = [1, 2, 3]
        let expected: [(Int, Int)] = [(1,1), (1,2), (1,3), (2,1), (2,2), (2,3), (3,1), (3,2), (3,3)]

        let pairs = list.cartesianPairs()

        XCTAssertEqual(pairs.count, expected.count)
        XCTAssertTrue(pairs.elementsEqual(expected, by: ==))
    }

    func testTriangularPairs0() {
        let list: [Int] = []
        let expected: [(Int, Int)] = []

        let pairs = list.triangularPairs()

        XCTAssertTrue(pairs.allSatisfy({ $0 <= $1 }))
        XCTAssertEqual(pairs.count, expected.count)
        XCTAssertTrue(pairs.elementsEqual(expected, by: ==))
    }

    func testTriangularPairs1() {
        let list: [Int] = [1]
        let expected: [(Int, Int)] = [(1,1)]

        let pairs = list.triangularPairs()

        XCTAssertTrue(pairs.allSatisfy({ $0 <= $1 }))
        XCTAssertEqual(pairs.count, expected.count)
        XCTAssertTrue(pairs.elementsEqual(expected, by: ==))
    }

    func testTriangularPairs2() {
        let list: [Int] = [1, 2]
        let expected: [(Int, Int)] = [(1,1), (1,2), (2,2)]

        let pairs = list.triangularPairs()

        XCTAssertTrue(pairs.allSatisfy({ $0 <= $1 }))
        XCTAssertEqual(pairs.count, expected.count)
        XCTAssertTrue(pairs.elementsEqual(expected, by: ==))
    }

    func testTriangularPairs3() {
        let list: [Int] = [1, 2, 3]
        let expected: [(Int, Int)] = [(1,1), (1,2), (1,3), (2,2), (2,3), (3,3)]

        let pairs = list.triangularPairs()

        XCTAssertTrue(pairs.allSatisfy({ $0 <= $1 }))
        XCTAssertEqual(pairs.count, expected.count)
        XCTAssertTrue(pairs.elementsEqual(expected, by: ==))
    }

    func testStrictlyTriangularPairs0() {
        let list: [Int] = []
        let expected: [(Int, Int)] = []

        let pairs = list.strictlyTriangularPairs()

        XCTAssertTrue(pairs.allSatisfy({ $0 < $1 }))
        XCTAssertEqual(pairs.count, expected.count)
        XCTAssertTrue(pairs.elementsEqual(expected, by: ==))
    }

    func testStrictlyTriangularPairs1() {
        let list: [Int] = [1]
        let expected: [(Int, Int)] = []

        let pairs = list.strictlyTriangularPairs()

        XCTAssertTrue(pairs.allSatisfy({ $0 < $1 }))
        XCTAssertEqual(pairs.count, expected.count)
        XCTAssertTrue(pairs.elementsEqual(expected, by: ==))
    }

    func testStrictlyTriangularPairs2() {
        let list: [Int] = [1, 2]
        let expected: [(Int, Int)] = [(1,2)]

        let pairs = list.strictlyTriangularPairs()

        XCTAssertTrue(pairs.allSatisfy({ $0 < $1 }))
        XCTAssertEqual(pairs.count, expected.count)
        XCTAssertTrue(pairs.elementsEqual(expected, by: ==))
    }

    func testStrictlyTriangularPairs3() {
        let list: [Int] = [1, 2, 3]
        let expected: [(Int, Int)] = [(1,2), (1,3), (2,3)]

        let pairs = list.strictlyTriangularPairs()

        XCTAssertTrue(pairs.allSatisfy({ $0 < $1 }))
        XCTAssertEqual(pairs.count, expected.count)
        XCTAssertTrue(pairs.elementsEqual(expected, by: ==))
    }
}
