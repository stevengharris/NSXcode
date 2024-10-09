//
//  MyModelExports.swift
//  MyProductNS
//
//  Created by Steven Harris on 9/21/24.
//

import NodeAPI
import MyProductLib

#NodeModule(exports: [
    
    "hello": try NodeFunction { _ in MyModel.helloWorld() },
    
    // For consistency with the existing node-swift example...
    "nums": Array<NodeValueConvertible>(MyModel.nums),
    "str": MyModel.str,
    "add": try NodeFunction { await MyModel.add(a: 2, b: 2) }
    
])
