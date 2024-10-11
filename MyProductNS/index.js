//
//  index.js
//  MyProductNS
//
//  Created by Steven Harris on 9/30/24.
//

// Entry points defined in struct MyModel and exposed in MyModelExports
const { hello, nums, str, add } = require('./.build/Module.node');

// Invoke the node-swift-exposed entry point
console.log(hello()); // Hello, from Swift world! coming from MyModel

// Original node-swift example
console.log(nums); // [ 3, 4 ]
console.log(str); // NodeSwift! NodeSwift! NodeSwift!
add(5, 10).then(console.log); // 5.0 + 10.0 = 15.0
