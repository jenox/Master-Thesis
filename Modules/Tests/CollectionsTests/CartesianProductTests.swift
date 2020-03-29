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

final class CartesianProductTests: XCTestCase {

    // TODO: inline
    private let i0: [Int] = []
    private let i1: [Int] = [1]
    private let i2: [Int] = [1, 2]
    private let i3: [Int] = [1, 2, 3]
    private let c0: [Character] = []
    private let c1: [Character] = ["1"]
    private let c2: [Character] = ["1", "2"]
    private let c3: [Character] = ["1", "2", "3"]

    func testCartesianProduct00() {
        let list1: [Int] = i0
        let list2: [Character] = c0
        let expected: [(Int, Character)] = []

        let cartesian = list1.cartesianProduct(with: list2)

        XCTAssertEqual(cartesian.count, expected.count)
        XCTAssertTrue(cartesian.elementsEqual(expected, by: ==))
    }

    func testCartesianProduct01() {
        let list1: [Int] = i0
        let list2: [Character] = c1
        let expected: [(Int, Character)] = []

        let cartesian = list1.cartesianProduct(with: list2)

        XCTAssertEqual(cartesian.count, expected.count)
        XCTAssertTrue(cartesian.elementsEqual(expected, by: ==))
    }

    func testCartesianProduct02() {
        let list1: [Int] = i0
        let list2: [Character] = c2
        let expected: [(Int, Character)] = []

        let cartesian = list1.cartesianProduct(with: list2)

        XCTAssertEqual(cartesian.count, expected.count)
        XCTAssertTrue(cartesian.elementsEqual(expected, by: ==))
    }

    func testCartesianProduct03() {
        let list1: [Int] = i0
        let list2: [Character] = c3
        let expected: [(Int, Character)] = []

        let cartesian = list1.cartesianProduct(with: list2)

        XCTAssertEqual(cartesian.count, expected.count)
        XCTAssertTrue(cartesian.elementsEqual(expected, by: ==))
    }

    func testCartesianProduct10() {
        let list1: [Int] = i1
        let list2: [Character] = c0
        let expected: [(Int, Character)] = []

        let cartesian = list1.cartesianProduct(with: list2)

        XCTAssertEqual(cartesian.count, expected.count)
        XCTAssertTrue(cartesian.elementsEqual(expected, by: ==))
    }

    func testCartesianProduct11() {
        let list1: [Int] = i1
        let list2: [Character] = c1
        let expected: [(Int, Character)] = [(1,"1")]

        let cartesian = list1.cartesianProduct(with: list2)

        XCTAssertEqual(cartesian.count, expected.count)
        XCTAssertTrue(cartesian.elementsEqual(expected, by: ==))
    }

    func testCartesianProduct12() {
        let list1: [Int] = i1
        let list2: [Character] = c2
        let expected: [(Int, Character)] = [(1,"1"), (1,"2")]

        let cartesian = list1.cartesianProduct(with: list2)

        XCTAssertEqual(cartesian.count, expected.count)
        XCTAssertTrue(cartesian.elementsEqual(expected, by: ==))
    }

    func testCartesianProduct13() {
        let list1: [Int] = i1
        let list2: [Character] = c3
        let expected: [(Int, Character)] = [(1,"1"), (1,"2"), (1,"3")]

        let cartesian = list1.cartesianProduct(with: list2)

        XCTAssertEqual(cartesian.count, expected.count)
        XCTAssertTrue(cartesian.elementsEqual(expected, by: ==))
    }

    func testCartesianProduct20() {
        let list1: [Int] = i2
        let list2: [Character] = c0
        let expected: [(Int, Character)] = []

        let cartesian = list1.cartesianProduct(with: list2)

        XCTAssertEqual(cartesian.count, expected.count)
        XCTAssertTrue(cartesian.elementsEqual(expected, by: ==))
    }

    func testCartesianProduct21() {
        let list1: [Int] = i2
        let list2: [Character] = c1
        let expected: [(Int, Character)] = [(1,"1"), (2,"1")]

        let cartesian = list1.cartesianProduct(with: list2)

        XCTAssertEqual(cartesian.count, expected.count)
        XCTAssertTrue(cartesian.elementsEqual(expected, by: ==))
    }

    func testCartesianProduct22() {
        let list1: [Int] = i2
        let list2: [Character] = c2
        let expected: [(Int, Character)] = [(1,"1"), (1,"2"), (2,"1"), (2,"2")]

        let cartesian = list1.cartesianProduct(with: list2)

        XCTAssertEqual(cartesian.count, expected.count)
        XCTAssertTrue(cartesian.elementsEqual(expected, by: ==))
    }

    func testCartesianProduct23() {
        let list1: [Int] = i2
        let list2: [Character] = c3
        let expected: [(Int, Character)] = [(1,"1"), (1,"2"), (1,"3"), (2,"1"), (2,"2"), (2,"3")]

        let cartesian = list1.cartesianProduct(with: list2)

        XCTAssertEqual(cartesian.count, expected.count)
        XCTAssertTrue(cartesian.elementsEqual(expected, by: ==))
    }

    func testCartesianProduct30() {
        let list1: [Int] = i3
        let list2: [Character] = c0
        let expected: [(Int, Character)] = []

        let cartesian = list1.cartesianProduct(with: list2)

        XCTAssertEqual(cartesian.count, expected.count)
        XCTAssertTrue(cartesian.elementsEqual(expected, by: ==))
    }

    func testCartesianProduct31() {
        let list1: [Int] = i3
        let list2: [Character] = c1
        let expected: [(Int, Character)] = [(1,"1"), (2,"1"), (3,"1")]

        let cartesian = list1.cartesianProduct(with: list2)

        XCTAssertEqual(cartesian.count, expected.count)
        XCTAssertTrue(cartesian.elementsEqual(expected, by: ==))
    }

    func testCartesianProduct32() {
        let list1: [Int] = i3
        let list2: [Character] = c2
        let expected: [(Int, Character)] = [(1,"1"), (1,"2"), (2,"1"), (2,"2"), (3,"1"), (3,"2")]

        let cartesian = list1.cartesianProduct(with: list2)

        XCTAssertEqual(cartesian.count, expected.count)
        XCTAssertTrue(cartesian.elementsEqual(expected, by: ==))
    }

    func testCartesianProduct33() {
        let list1: [Int] = i3
        let list2: [Character] = c3
        let expected: [(Int, Character)] = [(1,"1"), (1,"2"), (1,"3"), (2,"1"), (2,"2"), (2,"3"), (3,"1"), (3,"2"), (3,"3")]

        let cartesian = list1.cartesianProduct(with: list2)

        XCTAssertEqual(cartesian.count, expected.count)
        XCTAssertTrue(cartesian.elementsEqual(expected, by: ==))
    }
}
