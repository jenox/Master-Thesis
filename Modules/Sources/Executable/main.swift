//
//  File.swift
//  
//
//  Created by Christian Schnorr on 11.04.20.
//

import Foundation




do {
    let v = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
    let data = [3, 1, 4, 1, 5, 9, 2, 6]

    print(Array(v.lazy.scan(0, +)))
    print(Array(v.scan(0, +)))

    print("The first 10 even numbers area:", v.scan(0, +).map(String.init).joined(separator: " "))
    print("The first 10 powers of 2 are:", v.scan(1, *).map(String.init).joined(separator: " "))

    print(data.scan(0, max))
    print(Array(data.reversed().scan(0, max).reversed()))
}
