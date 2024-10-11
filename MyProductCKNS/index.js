//
//  index.js
//  MyProductCKNS
//
//  Created by Steven Harris on 9/30/24.
//

// Entry points defined in struct MyModel and exposed in MyModelExports
const { hello, nums, str, add } = require('./.build/Module.node');

// Needed to access MyProductCLI for entry points needing restricted entitlements
const child_process = require('child_process');
const fs = require('node:fs');
const path = require('path');

// Invoke the node-swift-exposed entry point
console.log(hello()); // Hello, from Swift world! coming from MyModel

// Invoke the CLI command to access iCloud. The CLI executable has to reside within
// an app that has the proper entitlements.
try {
    // The post-build-cli script executed after MyProductCLI builds places a symbolic
    // link in the .build/MyProductCKNS directory which links to the executable
    // inside MyProductCLI.app. However, the link is relative to where it resides,
    // so we have to join it with the .build directory to spawn it.
    const cli = path.join(".build", fs.readlinkSync('./.build/MyProductCLI'));
    const child = child_process.spawnSync(cli, ['-i', 'iCloud.com.stevengharris.MyProductCK']);
    
    // Note the contents of stdout is from print(MyModel.helloCloudKit(iCloudContainer)) inside
    // of MyProjectTool.run(). The async command being run doesn't return a result.
    console.log(child.stdout.toString().trim()); // Hello, iCloud! coming from MyModel
} catch (err) {
    console.log('Error. Build MyProductCLI before running "node index.js"... ' + err);
}

// Original node-swift example
console.log(nums); // [ 3, 4 ]
console.log(str); // NodeSwift! NodeSwift! NodeSwift!
add(5, 10).then(console.log); // 5.0 + 10.0 = 15.0
