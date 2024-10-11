//
//  MyModelExports.swift
//  MyProductCKNS
//
//  Created by Steven Harris on 9/21/24.
//

import NodeAPI
import MyProductCKLib

#NodeModule(exports: [
    
    "hello": try NodeFunction { _ in MyModel.helloWorld() },
    
    // For consistency with the existing node-swift example...
    "nums": Array<NodeValueConvertible>(MyModel.nums),
    "str": MyModel.str,
    "add": try NodeFunction { a, b in await MyModel.add(a: a, b: b) }
    
])
