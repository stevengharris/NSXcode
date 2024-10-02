//
//  index.js
//  NSXcode
//
//  Created by Steven Harris on 9/30/24.
//

const { hello, nums, str, add } = require("./.build/Module.node");
console.log(hello()); // Hello, world! coming from MyModel
console.log(nums); // [ 3, 4 ]
console.log(str); // NodeSwift! NodeSwift! NodeSwift!
add(5, 10).then(console.log); // 5.0 + 10.0 = 15.0
