//
//  MyModelExports.swift
//  MyProduct
//
//  Created by Steven Harris on 9/21/24.
//

import NodeAPI
import MyProductLib

#NodeModule(exports: [
    "hello": try NodeFunction { _ in
        MyModel.helloWorld()
    },
    // For consistency with the existing node-swift example...
    "nums": [Double.pi.rounded(.down), Double.pi.rounded(.up)],
    "str": String(repeating: "NodeSwift! ", count: 3),
    "add": try NodeFunction { (a: Double, b: Double) in
        print("calculating...")
        try await Task.sleep(nanoseconds: 500_000_000)
        return "\(a) + \(b) = \(a + b)"
    },
])
