# NSXcode

Using NodeSwift with an existing Xcode project

###

## Background

[NodeSwift](https://github.com/kabiroberai/node-swift) is a project that bridges Node.js and Swift code. The NodeSwift project contains an example within it, but many users will come at it with existing Xcode projects in-place. Building on the [NodeSwift example](https://github.com/kabiroberai/node-swift/tree/main/example), this repository and README provide documentation about how to take an existing Xcode project and make some of its functionality available to Node.js, including:

* Setting up the NodeSwift build directory for your Xcode project
* Using an Xcode Run Script to build the Node module for your Xcode project
* Dealing with Swift code that requires restricted entitlements (e.g., iCloud)
* Making creation of the Node module a transparent part of your Xcode project build process
* Using Swift from a VSCode extension (whose host process runs Node.js)

As stated in the [NodeSwift README](https://github.com/kabiroberai/node-swift):

> A NodeSwift module consists of a [SwiftPM](https://swift.org/package-manager/) package and [NPM](https://www.npmjs.com) package in the same folder, both of which express NodeSwift as a dependency.

> The Swift package is exposed to JavaScript as a native Node.js module, which can be `require`'d by the JS code. The two sides communicate via [Node-API](https://nodejs.org/api/n-api.html), which is wrapped by the `NodeAPI` module on the Swift side.

## Motivation

A major use case for me is to build a VSCode extension that uses functionality from my existing Swift app built in Xcode. Like many apps, mine is built in SwiftUI, but the documentation and approach outlined here is equally applicable to UIKit or AppKit-based projects. My app also uses restricted entitlements - specifically iCloud. I want to re-use my investment in Swift accessing iCloud, but invoke it from a VSCode extension.

## Requirements

You should have [Node.js](https://nodejs.org/en) and npm installed. The project was tested using v20.17.0.

Clone the [node-swift](https://github.com/kabiroberai/node-swift) repo locally. You should use a local copy because at this time, node-swift from npm is out of date, per [this issue](https://github.com/kabiroberai/node-swift/issues/13).

The Swift entry points you expose to Node.js *cannot* reside in source files that import or depend on UI modules - SwiftUI, UIKit, or AppKit. If you want to expose entry points in an existing project that includes UI, you should start by factoring-out a separate library without UI dependencies which you can then have your existing project depend on and import. In the SwiftUI example here, `MyProduct`, the `ContentView` displays "Hello, from Swift world!" using a `MyModel` struct that is built in the `MyProductLib` framework that `MyProduct` depends on.

## Do You Need Restricted Entitlements?

Your project may require capabilities/entitlements that are only available with a provisioning profile. For example, iCloud access is only available with entitlements that are in turn tied to your provisioning profile. The entire concept of restricted entitlements applies to an app bundle, but here we are building a Node module. *You won't be able to execute Swift code that requires entitlements using NodeSwift*. To work around this limitation, you can access these kinds of functions from a CLI that you embed in an app bundle. We will discuss how to do that in a [separate section](#builds-with-restricted-entitlements) below.

## Builds Without Restricted Entitlements

`MyProject` contains two build targets that are free of the complications of restricted entitlements:

1. `MyProduct`: This target is used as the simplest baseline, an example of an existing Xcode project. It is the equivalent of the standard Xcode-produced target for a SwiftUI app (although everything here applies to any UI-dependent app). The target was modified to remove the App Sandbox capability. Note the Hardened Runtime capability default was left in place. The "Hello, from Swift world!" string is returned from `MyModel` which is built as part of `MyProductLib` target.

2. `MyProductLib`: This builds the framework that both `MyProduct` and the Node module depend on. Note that `MyProductLib` has no dependency on NodeSwift. It is just a way to:
    * Factor-out non-UI code containing functions/methods we want to expose to Node.js.
    * Define a `Package.swift` that can be identified as a package dependency when we build the Node module separately.
        
In addition to these two normal Xcode build targets, we use a `MyProductNS` directory to build the Node module. This is the equivalent of the [example](https://github.com/kabiroberai/node-swift/tree/main/example) in the node-swift repository, but it exposes an entry point in MyProductLib to Node.js. (Note also that MyProductLib Build Phases include a [Run Script to automate](#automating-node-module-builds) the Node module build process.)

### Setting Up MyProductNS To Build The Node Module

The NodeSwift build process and the definition of the entry points that are exposed to Node.js are defined in the `MyProductNS` directory. The following steps were required to set up the `MyProductNS` directory in a way that can build the Node module and make it easy to iterate with changes in the Xcode project.

1. Add a `package.json` modeled on the one in the NodeSwift  [example](https://github.com/kabiroberai/node-swift/tree/main/example). You can leave the dependencies section empty initially. Note: If you want to access the exported entry points from JavaScript (perhaps via TypeScript) code, you need to include an `"exports": "./.build/Module.node"` section in `package.json. This is not included in the NodeSwift example.

2. Install `node-swift` as a dependency using `npm install <relative path to the node-swift repo you cloned>`. This creates a symlink in your `node_modules` directory and updates the dependencies section of `package.json`.

3. Set up a `Package.swift` that can be used by the NodeSwift build process. The `Package.swift` here references the `MyProjectLib` package as a dependency, the same one the `MyProject` app depends on. Make sure `Package.swift` opens and resolves its dependencies correctly, since the NodeSwift build uses `Package.swift` (along with `package.json`) to build the Node module (`Module.node`) and the dynamic library it uses (`libNodeAPI.dylib`). If you open Xcode on `Package.swift`, you should be able to build the `MyProductNS` library target, but this is not particularly useful.

4. In the Sources used by your `Package.swift`, define your NodeSwift module exports, the entry points on the Swift side that can be exposed to Node.js. Reminder: The Swift entry points *cannot* reside in source files that import or depend on UI modules - SwiftUI, UIKit, or AppKit. In our example, the Node module exports reference code in `MyProductLib`, so the `MyProductLib` Swift module has to be imported.

5. For testing purposes, create `index.js` which you can use to test your Swift entry points by executing `node index.js` after you successfully build `Module.node`. The `index.js` in `MyProductNS` also includes the corresponding exports from the original node-swift example to help you test what you've set up.

Tip: If you set up your own version of `MyProjectNS`, be careful that files like `package*.*`, `Package.*`, and `*.js` are not part of an Xcode target. It's also easy to find that files within directories like `.build` and `node_modules` suddenly end up in your Xcode target. To avoid that problem, make sure these directories are marked "Apply once to folder" within Xcode.

### Building the Node Module

You can build the Node module manually, or you can use a Run Script for `MyProductLib`, which is the Node module's only project dependency. 

The result of the build will be a Node module, `Module.node`, symlinked in the `.build` directory, along with a `libNodeAPI.dylib` that `Module.node` uses. The `Module.node` symlink points to either the `debug` or `release` directory (depending on the type of build) that contains `libNodeAPI.dylib`. These files/directories are in turn symlinked to the "build architecture" directory. All of this symlinking is just a convenience mechanism so that the `index.js` file loaded at Node.js execution time can use `require("./.build/Module.node")` to access the Swift entry points defined in `MyModuleExports.swift` in the `MyModuleLib` Swift module.

Warning: The first time you do the build, it takes a long time because of NodeSwift's dependency on [Swift Syntax](https://github.com/swiftlang/swift-syntax). Subsequent builds are reasonably fast.

#### Building the Node Module Manually

From within the `MyProductNS` directory, execute:

```
npm run build
```

#### Automating Node Module Builds

You can automate Node module builds by adding a Run Script in your library target (Build Phases -> "+ Button" -> Add New Run Script). In the example here, we use a script in the `MyProductLib` build target. It is designed to be run from the `MyProductNS` directory:

```
cd $PROJECT_DIR/MyProductNS
sh build-ns.sh
```

IMPORTANT: 

* You need to set "User Script Sandboxing" to "NO" in MyProductLib's build settings (else you will see an error like "Sandbox: bash(2538) deny(1) file-read-data...").
* Uncheck the "Based on dependency analysis" option so that your Node module updates every time you build MyProductLib. This will also include builds of MyProduct in the example here. You will want to adapt the flow to your specific project.

### Testing Your Node Module

From within the `MyProductNS` directory, invoke Node.js on `index.js`:

```
node index.js
```

You will see the `Model.helloWorld()` entry point that is exposed in `MyModelExports` along with the original Swift code execution from the node-swift example:

```
Hello, from Swift world!
[ 3, 4 ]
NodeSwift! NodeSwift! NodeSwift! 
calculating...
5.0 + 10.0 = 15.0
```

### Xcode Development Process With NodeSwift

The sample project here uses `build-ns.sh` as a Run Script for `MyProductLib`. Thus, if you make a change to the Swift code that is invoked and rebuild either MyProduct or MyProductLib, the changes will be show up when you run `node index.js` again. Similarly, if you want to expose other Swift entry points to Node.js, you would edit `MyModelExports.swift` in `Sources/MyProductNS` to do that and make a corresponding change to `index.js`. Then, by rebuilding MyProduct or MyProductLib, your changed Swift entry points are available and can be tested using `node index.js`.

## Builds With Restricted Entitlements

You should be sure to read the [section](#builds-without-restricted-entitlements) above before this section.

Swift code that requires restricted entitlements cannot be used with NodeSwift. If you try to do so, Node.js will load `Module.node` and `libNodeAPI.dylib` without errors, but when you execute the Swift code requiring restricted entitlements, the Node.js server will crash. You will be greeted with a helpful error like: `Illegal instruction: 4`, and you can examine the MacOS crash logs to find details.

> Note: If you find a way around this limitation, please raise an issue in this repository. As far as I can tell, no amount of code signing and app-bundle-wrapping of `Module.node` and `libNodeAPI.dylib` helps. You might be able to embed Node.js in an app bundle that contains the entitlements, but this was not practical for me.

There is a non-NodeSwift workaround for accessing Swift code that requires restricted entitlements. I'm including a discussion of the workaround here because I need to use it alongside my use of NodeSwift. A Node.js person might not even call this a workaround, since it seems to be the standard mechanism for accessing Go libraries from Node.js, but it will be less efficient and flexible than using NodeSwift.

The workaround consists of:

* Create a CLI for the entry points that require restricted entitlements.
* Wrap your CLI in an app bundle that includes the entitlements. There is an [excellent article](https://developer.apple.com/documentation/xcode/signing-a-daemon-with-a-restricted-entitlement) about how to deal with this issue when developing a daemon in Swift, which applies reasonably well here. 
* Use the Node.js child\_process mechanism to invoke the CLI.

To keep the complications out of the discussion of NodeSwift and Xcode, there are three separate build targets in the project associated with restricted entitlements:

1. MyProductCK - The same as MyProduct, but with iCloud entitlements and a dependency on MyProductCKLib.

2. MyProductCKLib - The same as MyProductLib, but includes a single function that depends on CloudKit. Note that this library (like any library) does not have entitlements, but the apps that consume it do.

3. MyProductCLI - An app - not actually a CLI executable - that has iCloud entitlements and a dependency on MyProductCKLib.

Perhaps unsurprisingly, the setup for building NodeSwift is pretty much the same as was [outlined above](#setting-up-myproductns-to-build-the-node-module). The steps to automate the Xcode build is similar but has to be augmented with additional steps to produce the CLI.

### Creating A Wrapped CLI

Creating a CLI in Xcode is as simple as creating a new "Command Line" target. That will produce a target that creates an executable, but you won't be able to add entitlements to it, because entitlements are only associated with app bundles. Your CLI executable can, however, be placed in an app bundle using the following steps, which are based on the [article](https://developer.apple.com/documentation/xcode/signing-a-daemon-with-a-restricted-entitlement) about signing a daemon with a restricted entitlement.

1. Create a MacOS "App" target. I chose SwiftUI as the "interface", but the choice only changes what kind of code you need to delete and which build settings you need to modify.

2. Remove the "App Sandbox" from the Signing \& Capabilities tab.

3. Remove the "App Icon" from the General tab.

4. Remove all UI-based folders and .swift files. For SwiftUI, this includes: Preview Content, Assets, ContentView.swift, \*App.swift).

5. In Build Settings...
    * Remove Deployment -> Development Assets
    * User Defined -> Enable_Previews -> NO
    * Build Options -> Enable Debug Dylib Support -> NO

6. Place a `main.swift` in the folder with proper content, or otherwise marked @main. If asked, don't create a bridging header.

7. Add the entitlements you need. 

8. In the Scheme editor for the CLI (`MyProductCLI`)...
    * Add a Run argument to test when the CLI builds. Here for example: `-i iCloud.com.stevengarris.MyProductCK`. This will let you know the CLI is working correctly by showing the print of "Hello CloudKit!" in the console.
    * Uncheck the Run Options -> Document Versions item to avoid having Xcode pass a "-NSDocumentRevisionsDebugMode" argument that will mess up your argument parsing.

### MyProductCLI Example

The `MyProductCLI` example uses `MyProjectTool.swift` for @main. The `MyProjectTool` struct depends on `MyProjectCKLib` and `ArgumentParser`. If you have not created a Swift CLI before, the [tutorial](https://www.swift.org/getting-started/cli-swiftpm/) on the swift.org web site is a good starting point. The example uses a `AsyncParsableCommand` because I want to wait on responses from iCloud, but your usage my not call for it.

The test that the entitlements work is a simple as possible: creating an instance of CKContainer. This code will fail without the entitlements. In Xcode, you will see a useful message in the console telling you you're missing the entitlements.

In the Signing and Capabilities tab, I used iCloud -> CloudKit -> `iCloud.com.stevengharris.MyProductCK`. If you are just trying out the example, you can point at any existing CloudKit container you have, because the example only instantiates a CKContainer and does no actual interaction with iCloud across the network - don't worry! However, if you've never used iCloud before, Xcode will create a container for you as soon as you identify it, and [that container will live forever](https://forums.developer.apple.com/forums/thread/45251).

### Running the Wrapped CLI

If you build the `MyProductCLI` target, you can run the CLI from the command line by locating the app and invoking the executable that resides inside of it. For a debug build, the app will reside at `~/Library/Developer/Xcode/DerivedData/Build/Products/Debug/MyProductCLI.app`, and the actual CLI is at ~/Library/Developer/Xcode/DerivedData/Build/Products/Debug/MyProductCLI.app/Contents/MacOS/MyProductCLI`. So, execute the wrapped CLI from the command line with the help option using:

```
~/Library/Developer/Xcode/DerivedData/Build/Products/Debug/MyProductCLI.app/Contents/MacOS/MyProductCLI -h
```

This will produce:

```
USAGE: myproduct [--icloud <container>]

OPTIONS:
  -i, --icloud <container>
                          Check iCloud access.
  -h, --help              Show help information.
```

Passing the container name using the -i option:

```
~/Library/Developer/Xcode/DerivedData/Build/Products/Debug/MyProductCLI.app/Contents/MacOS/MyProductCLI -i iCloud.com.stevengharris.MyProductCK
```

instantiates a CKContainer and then prints the following to stdout:

```
Hello, CloudKit!
```

The fact we see `Hello, CloudKit!` is showing that the entitlements are applied properly to the containing app bundle.

### Automating Node Module and CLI Builds

#### TL;DR

1. Use a Run Script invoking `build-ns.sh` on the library (MyProductCKLib) to build the Node module.
2. Use a post-build action `build-cli.sh` to build `MyProductCLI` after the library (MyProductCKLib) build. This script invokes `post-build-cli.sh` when the build is done. 
3. Use a post-build action `post-build-cli.sh` to put the CLI app and a symlink to the executable into `MyProductCKNS/.build` alongside the `Module.node` produced by NodeSwift.

#### Details

There are quite a few steps to build both the Node module for NodeSwift *and* the CLI and then place the wrapped CLI into a place where it is easily accessible from Node.js. It also involves multiple Xcode builds, and it's easy to forget a step. Ultimately, we want the Xcode development process to "just work" when we build the MyProjectCK app or the MyProjectCKLib library. Fortunately, everything can happen automatically in Xcode using a combination of Run Script build steps and post-build actions in the Xcode schemes.

We want to invoke the CLI from Node.js, so we need to make it more easily available to Node.js, just like the NodeSwift makes `Module.node` easily accessible from `index.js` by placing a symlink in the `.build` directory. In this example, we want *both* the `Module.node` and the CLI available. We already have automation set up to build `Module.node` using a Run Script build step on MyProductCKLib. We need something similar for the CLI. Unfortunately, there are two complications:

1. We can't add another Run Script build step to MyProductCKLib or extend the existing one, because we need to build another Xcode scheme, and because the Run Script is part of a build that is not complete, Xcode objects to two builds going on at the same time.

2. We need the CLI that we make available to Node.js to be fully built *and signed*. We can't add a Run Script to the MyProductCLI target, because Run Scripts execute before signing.

The solution here is to add a "post-build action" to the MyProductCKLib build. We do that using the Scheme editor: Edit Scheme... -> Expand the "Build" item on the left -> "Post-actions" -> "+" button. We use the build settings from `MyProductCKLib` and execute a script to build `MyProductCLI`:

```
sh $PROJECT_DIR/MyProductCKNS/build-cli.sh
```

When the `MyProductCLI` build is done, we use the `post-build-cli.sh` script to copy the resulting `MyProductCLI.app` into the same `.build` directory that `Module.node` is in, and we create a symlink to the executable `MyProductCLI` inside of the app. This makes both `Module.node` and `MyProductCLI` easily accessible from `index.js` by requiring them from the `.build` directory. We re-use the same `post-build-cli.sh` script as a post-build action on the MyProductCLI target so that it executes when `MyProductCLI` is built directly from the Xcode target.

### Testing The Node Module and CLI

Compared to `index.js` in `MyProductNS` (i.e., the directory used for the NodeSwift build without restricted entitlements issues), the `index.js` in `MyProductCKNS` adds additional code to invoke the CLI from Node.js using Node's child\_process.

```
// Needed to access MyProductCLI for entry points needing restricted entitlements
const child_process = require('child_process');
const fs = require('node:fs');
const path = require('path');

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

```

From within the `MyProductCKNS` directory, invoke Node.js on `index.js`:

```
node index.js
```

In addition to the `Model.helloWorld()` entry point that is exposed in `MyModelExports` and the original code from the NodeSwift example, you will see the "Hello, CloudKit" print show up that executes after instantiating a CKContainer (something that requires the entitlements):

```
Hello, from Swift world!
Hello, CloudKit!
[ 3, 4 ]
NodeSwift! NodeSwift! NodeSwift! 
calculating...
5.0 + 10.0 = 15.0
```

### Xcode Development Process With NodeSwift and CLI

Like the case without restricted entitlement complications, the Run Script for MyProductCKLib ensures that the Node module is built whenever you update and rebuild MyProductCK or MyProductCKLib. The addition of post-build actions to build and copy/symlink the CLI ensures that the CLI is also updated as you do Xcode development on the app or library.

If you want to add new functionality to the CLI because you need to exercise Swift entry points that require restricted entitlements, then you would do so in `MyProductTool.swift` within the example project, and then make corresponding changes/additions to `index.js` to test them.

## Using Swift from a VSCode Extension

It's been a long journey to automate the use of NodeSwift and a wrapped CLI within Xcode. But, the automation investment also means that we can develop in Xcode and immediately use our Swift investment from within a [VSCode extension](https://code.visualstudio.com/api/get-started/your-first-extension). Let's use the [helloworld-sample](https://github.com/microsoft/vscode-extension-samples/tree/main/helloworld-sample) found within the Microsoft's [VSCode extension samples](https://github.com/microsoft/vscode-extension-samples). 

From within the `helloworld-sample` directory, install the NodeSwift build directory for your project. Using the example with both NodeSwift entry points and the wrapped CLI to get access to restricted entitlements here:

```
npm install <relative path to MyProductCKNS>
```

This adds a dependency on `nsxcode` into the `helloworld-sample` `package.json` and adds a symlink to the relative path you identified in `node_modules`. It kicks off a build that takes a long time because of the dependency on Swift Syntax. Now as you update your Swift code from Xcode and build `MyProductCK` (or separately `MyProductCKLib` or `MyProductCLI`), your changes (via the links to `Module.node` and `MyProductCLI` in `MyProductCKNS/.build`) are available immediately to the `helloworld-sample` VSCode plugin.

Microsoft prefers TypeScript to JavaScript for VSCode plugins, so the code in the `helloworld-sample` resides in `src/extension.ts`, and we need to use `import` rather than `requires` like we were using in `index.js`. We also need to create `src/nsxcode.d.ts` file that declares the nsxcode module:

```
declare module "nsxcode"
```

Once that setup is complete, we can import the NodeSwift entry points:

```
import { hello, nums, str, add } from 'nsxcode';
```

We can invoke the CLI to gain access to iCloud the same way we did in `index.js`. Reaching `MyProductCLI` is a bit more convoluted, since it is being invoked from a VSCode extension. The modified `extension.ts` looks like this:

```
import * as vscode from 'vscode';

import { hello, nums, str, add } from 'nsxcode';

// Needed to access MyProductCLI for entry points needing restricted entitlements
import * as child_process from 'child_process';
import { readlinkSync } from 'node:fs';
import * as path from 'path';

// this method is called when your extension is activated
// your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {
    // Use the console to output diagnostic information (console.log) and errors (console.error)
    // This line of code will only be executed once when your extension is activated
    console.log('Congratulations, your extension "helloworld-sample" is now active!');
    
    // Invoke the node-swift-exposed entry point
    console.log(hello()); // Hello, from Swift world! coming from MyModel

    // Invoke the CLI command to access iCloud. The CLI executable has to reside within
    // an app that has the proper entitlements.
    try {
        // The post-build-cli script executed after MyProductCLI builds places a symbolic
        // link in the .build/MyProductCKNS directory which links to the executable
        // inside MyProductCLI.app. However, the link is relative to where it resides,
        // so we have to join it with the .build directory to spawn it.
        const pathToCLILink = path.join(context.extensionPath, 'node_modules', 'nsxcode/.build');
        const cliLink = path.join(pathToCLILink, 'MyProductCLI');
        const cli = path.join(pathToCLILink, readlinkSync(cliLink));
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

    // The command has been defined in the package.json file
    // Now provide the implementation of the command with registerCommand
    // The commandId parameter must match the command field in package.json
    const disposable = vscode.commands.registerCommand('extension.helloWorld', () => {
        // The code you place here will be executed every time your command is executed

        // Display a message box to the user
        vscode.window.showInformationMessage(hello());
    });

    context.subscriptions.push(disposable);
}
```

When you run the extension, the `console.log` statements show up in the VSCode console:

```
Congratulations, your extension "helloworld-sample" is now active!
Hello, from Swift world!
Hello, CloudKit!
(2) [3, 4]
NodeSwift! NodeSwift! NodeSwift!
5.0 + 10.0 = 15.0
```

and you will see an information box displaying the result from executing the Swift code in `MyModel.helloWorld()`.

![Hello, from Swift world!](HelloFromSwiftWorld.jpg)
