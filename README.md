# NSXcode

Using node-swift with an existing Xcode project

###

## Background

NSXcode contains an example Xcode project that makes some of its Swift functionality callable from Node.js using the [NodeSwift](https://github.com/kabiroberai/node-swift) project. The NodeSwift project contains an example within it, but like me, many users will come at it with existing Xcode projects in-place. This repository and README provide documentation about how to take an existing Xcode project and make some of its functionality available to Node.js. 

As stated in the [NodeSwift README](https://github.com/kabiroberai/node-swift):

> A NodeSwift module consists of a [SwiftPM](https://swift.org/package-manager/) package and [NPM](https://www.npmjs.com) package in the same folder, both of which express NodeSwift as a dependency.

> The Swift package is exposed to JavaScript as a native Node.js module, which can be `require`'d by the JS code. The two sides communicate via [Node-API](https://nodejs.org/api/n-api.html), which is wrapped by the `NodeAPI` module on the Swift side.

## Motivation

A major use case for me is to build a VSCode extension that uses functionality from my existing Swift app built in Xcode. Like many apps, mine is built in SwiftUI, but the documentation and approach outlined here is equally applicable to UIKit or AppKit-based projects. My app also uses restricted entitlements - specifically iCloud. I want to re-use my investment in Swift accessing iCloud, but invoke it from a VSCode extension.

## Requirements

You should have [Node.js](https://nodejs.org/en) and npm installed. The project was tested using v20.17.0.

Clone the [node-swift](https://github.com/kabiroberai/node-swift) repo locally. You should use a local copy because at this time, node-swift from npm is out of date, per [this issue](https://github.com/kabiroberai/node-swift/issues/13).

The Swift entry points you expose to Node.js *cannot* reside in source files that import or depend on UI modules - SwiftUI, UIKit, or AppKit. If you want to expose entry points in an existing project that includes UI, you should start by factoring-out a separate library without UI dependencies which you can then have your existing project depend on and import. In the SwiftUI example here, `MyProduct`, the `ContentView` displays "Hello, world!" using a `MyModel` struct that is build in the `MyProductLib` framework that `MyProduct` depends on.

## MyProject Build Targets Without Managed Capabilities

`MyProject` contains several build targets that do not require [provisioning with capabilities](https://developer.apple.com/help/account/reference/provisioning-with-managed-capabilities/):

1. `MyProduct`: This target is used as the simplest baseline, an example of an existing Xcode project that doesn't require [provisioning with capabilities](https://developer.apple.com/help/account/reference/provisioning-with-managed-capabilities/). It is the equivalent of the standard Xcode-produced target for a SwiftUI app (although everything here applies to any UI dependent app). The target was modified to remove the App Sandbox capability. Note the Hardened Runtime capability default was left in place. The "Hello, world!" string is returned from `MyModel` which is built as part of `MyProductLib` target.

2. `MyProductLib`: This builds the framework that both `MyProduct` and the Node module depend on. Note that `MyProductLib` has no dependency on NodeSwift. It is just a way to:

        * Factor-out non-UI code containing functions/methods we want to expose to Node.js.
        * Define a Package.swift that can be identified as a package dependency when we build the Node module separately.

## Setting Up MyProductNS To Build The Node Module

After creating the `MyProductNS` target and its directory within `MyProject`, the following steps were required to set it up in a way that can build the Node module and make it easy to iterate with changes in the Xcode project.

1. Add a `package.json` modeled on the one in the [node-swift example](https://github.com/kabiroberai/node-swift/tree/main/example). You can leave the dependencies section empty initially.

2. Install `node-swift` as a dependency using `npm install <relative path to the node-swift repo you cloned>`. This creates a symlink in your `node_modules` directory and updates the dependencies section of `package.json`.

3. Define your NodeSwift module exports, the entry points on the Swift side that can be exposed to Node.js. Reminder: The Swift entry points *cannot* reside in source files that import or depend on UI modules - SwiftUI, UIKit, or AppKit.

4. Set up a `Package.swift` that can be used by the NodeSwift build process. The `Package.swift` here references the `MyProjectLib` package as a dependency, the same one the `MyProject` app depends on. Make sure `Package.swift` opens and resolves its dependencies correctly, since the node-swift build uses `Package.swift` (along with `package.json`) to build `Module.node`, the Node module. If you open Xcode on `Package.swift`, you should be able to build the `MyProductNS` target, but this is not particularly useful.

5. For testing purposes, create `index.js` which you can use to test your Swift entry points by executing `node index.js` after you successfully build `Module.node`. The `index.js` in `MyProductNS` also include the corresponding exports from the original node-swift example to help you test what you've set up.

Tip: If you set up your own version of `MyProjectNS`, be careful that files like `package*.*`, `Package.*`, and `*.js` are not part of an Xcode target. It's also easy to find that files within directories like `.build`, `.swiftpm`, `node_modules` suddenly end up in your Xcode target. To avoid that problem, make sure these directories are marked "Apply once to folder" within Xcode.

## Building the Node Module

You can build the Node module manually, or you can use a post-build script for MyProductLib, which is the Node module's' only project dependency. The result of the build is a Node module, `Module.node`, symlinked in the `.build` directory. The symlink points to either the `debug` or `release` directory depending on the type of build, which in turn is symlinked to the "build architecture" directory. All of this symlinking is just a convenience mechanism so that the `index.js` file loaded at Node.js execution time can use `require("./.build/Module.node")` to access the Swift entry points.

The first time you do the build, it takes a long time because of NodeSwift's dependency on [Swift Syntax](https://github.com/swiftlang/swift-syntax). Subsequent builds are reasonably fast.

### Building the Node Module Manually

From within the `MyProductNS` directory, execute:

```
npm run build
```

### Automating Node Module Builds

You can create a post-build script by editing the `MyProductLib` scheme. Expand `Build' in the scheme editor for the library, so that you can see `Post-actions`. Add a script to execute   `post-build-lib.sh` from within the `MyProductNS` directory:

```
cd $PROJECT_DIR/MyProductNS
sh post-build-lib.sh
```

The build script should be set to inherit the settings from the `MyProductLib` target.

