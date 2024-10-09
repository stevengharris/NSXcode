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

## Do You Need Restricted Entitlements?

Your project may require capabilities/entitlements that are only available with a provisioning profile. For example, iCloud access is only available with entitlements that are in turn tied to your provisioning profile. The entire concept of restricted entitlements applies to an app bundle, but here we are building a Node module. Unless you have the ability to embed node.js itself into an app bundle that has the proper entitlements, *you won't be able to invoke Swift code that requires entitlements from within the Node module*. To work around this limitation, you can access these kinds of functions from a CLI that you embed in an app bundle. We will discuss how to do that in a [separate section](#accessing-swift-code-requiring-restricted-entitlements) below.

## MyProject Build Targets Without Restricted Entitlements

`MyProject` contains two build targets that are free of the complications of restricted entitlements:

1. `MyProduct`: This target is used as the simplest baseline, an example of an existing Xcode project. It is the equivalent of the standard Xcode-produced target for a SwiftUI app (although everything here applies to any UI dependent app). The target was modified to remove the App Sandbox capability. Note the Hardened Runtime capability default was left in place. The "Hello, world!" string is returned from `MyModel` which is built as part of `MyProductLib` target.

2. `MyProductLib`: This builds the framework that both `MyProduct` and the Node module depend on. Note that `MyProductLib` has no dependency on NodeSwift. It is just a way to:

        * Factor-out non-UI code containing functions/methods we want to expose to Node.js.
        * Define a Package.swift that can be identified as a package dependency when we build the Node module separately.
        
In addition to these two normal Xcode build targets, we use a `MyProductNS` directory used to build the Node module. This is the equivalent of the example in the node-swift repository, but it exposes an entry point in MyProductLib to Node.js. (Note also that MyProductLib includes a [post-build step](#automating-node-module-builds) to automate the Node module build process.)

### Setting Up MyProductNS To Build The Node Module

The following steps were required to set up the `MyProductNS` directory in a way that can build the Node module and make it easy to iterate with changes in the Xcode project.

1. Add a `package.json` modeled on the one in the [node-swift example](https://github.com/kabiroberai/node-swift/tree/main/example). You can leave the dependencies section empty initially.

2. Install `node-swift` as a dependency using `npm install <relative path to the node-swift repo you cloned>`. This creates a symlink in your `node_modules` directory and updates the dependencies section of `package.json`.

3. Set up a `Package.swift` that can be used by the NodeSwift build process. The `Package.swift` here references the `MyProjectLib` package as a dependency, the same one the `MyProject` app depends on. Make sure `Package.swift` opens and resolves its dependencies correctly, since the node-swift build uses `Package.swift` (along with `package.json`) to build `Module.node`, the Node module. If you open Xcode on `Package.swift`, you should be able to build the `MyProductNS` library target, but this is not particularly useful.

4. In the Sources used by your `Package.swift`, define your NodeSwift module exports, the entry points on the Swift side that can be exposed to Node.js. Reminder: The Swift entry points *cannot* reside in source files that import or depend on UI modules - SwiftUI, UIKit, or AppKit. In our example, the Node module exports reference code in `MyProductLib`, so the `MyProductLib` Swift module has to be imported.

5. For testing purposes, create `index.js` which you can use to test your Swift entry points by executing `node index.js` after you successfully build `Module.node`. The `index.js` in `MyProductNS` also includes the corresponding exports from the original node-swift example to help you test what you've set up.

Tip: If you set up your own version of `MyProjectNS`, be careful that files like `package*.*`, `Package.*`, and `*.js` are not part of an Xcode target. It's also easy to find that files within directories like `.build` and `node_modules` suddenly end up in your Xcode target. To avoid that problem, make sure these directories are marked "Apply once to folder" within Xcode.

### Building the Node Module

You can build the Node module manually, or you can use a post-build script for `MyProductLib`, which is the Node module's only project dependency. 

The result of the build will be a Node module, `Module.node`, symlinked in the `.build` directory, along with a `libNodeAPI.dylib` that `Module.node` uses. The `Module.node` symlink points to either the `debug` or `release` directory (depending on the type of build) that contains `libNodeAPI.dylib`. These files/directories are in turn symlinked to the "build architecture" directory. All of this symlinking is just a convenience mechanism so that the `index.js` file loaded at Node.js execution time can use `require("./.build/Module.node")` to access the Swift entry points defined in `MyModuleExports.swift` in the `MyModuleLib` Swift module.

The first time you do the build, it takes a long time because of NodeSwift's dependency on [Swift Syntax](https://github.com/swiftlang/swift-syntax). Subsequent builds are reasonably fast.

#### Building the Node Module Manually

From within the `MyProductNS` directory, execute:

```
npm run build
```

#### Automating Node Module Builds

You can automate Node module builds by adding a Run Script in your library target (Build Phases -> "+ Button" -> Add New Run Script). In the example here, we use a script designed to be run from the `MyProductNS` directory:

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
Hello, world!
[ 3, 4 ]
NodeSwift! NodeSwift! NodeSwift! 
calculating...
5.0 + 10.0 = 15.0
```

## Accessing Swift Code Requiring Restricted Entitlements

There is an [excellent article](https://developer.apple.com/documentation/xcode/signing-a-daemon-with-a-restricted-entitlement) about how to deal with this problem when developing a daemon in Swift, which applies reasonably well here. 

As discussed [above](#do-you-need-restricted-entitlements), using restricted entitlements requires us to place the `Module.node` and `libNodeAPI.dylib` created during the node-swift build process into an app bundle along with the entitlements, and get everything properly signed. To avoid entangling the basic discussion of using node-swift with Xcode with the complications of restricted entitlements, we use three different targets. The restricted entitlement being used in the example is iCloud.

### MyProject Build Targets For Restricted Entitlements

#### *Less formal discussion, since the resulting Node module crashes at iCloud-entitled access...*

This is all on an Intel-based iMac running Sonoma 14.6.1 (to minimize the number of variables changing) and Xcode 16.0 (16A242d).

I use the same "normal" Xcode targets as before, but with "CK" in their name. The target specifies iCloud entitlements and exports an additional entry point:

```
    "iCloud": try NodeFunction { _ in
        MyModel.helloCloudKit()
    },
```

The `MyModel.helloCloudKit()` method creates an instance of `CKContainer`, which requires the iCloud entitlement:

```
    // A method that will crash if CloudKit entitlements are not properly enabled
    public static func helloCloudKit() -> String {
        let _ = CKContainer(identifier: "iCloud.com.stevengharris.MyProductCK")
        return "Hello, CloudKit!"
    }
```

If you build `MyProductCK`, it results in a window showing "Hello, world!" and "Hello, CloudKit!". If you do that without the iCloud entitlements, Xcode informs you:

> In order to use CloudKit, your process must have a com.apple.developer.icloud-services entitlement. The value of this entitlement must be an array that includes the string "CloudKit" or "CloudKit-Anonymous".

The node-swift build is done in the `MyProductCKNS` directory (via `npm run build`), producing `.build/Module.node` and `.build/debug/libNodeAPI.dylib`.

As would be expected, because there is no iCloud entitlement set up at thsi point, the result of `node index.js` crashes, showing that the "hello" execution works, but the "iCloud" execution fails when instantiating the `CKContainer`:

```
Hello, world!
Illegal instruction: 4
```

There is an additional `NSWrapper` app target that provides the minimal `NSWrapper.app` bundle that `Module.node` and `libNodeAPI.dylib` can be inserted into and re-signed. I did this because I don't really want to have to build my full UI app; I'd rather just have some placeholder that depends on the non-UI library that has the functionality I'm trying to access.

I use the `MyProductCKNS/post-build-app.sh` script to do the work, because it's a lot easier to generalize if you have access to the exports from the Xcode build target. 

**NOTE:** You must identify the cert you're using in the NSWrapper Xcode target. For example, line 52 of post-build-app.sh shows `CERT_ID="Apple Development: Steven Harris (77AW2CW22Z)"`, but should identify your signing certificate name.

If you build `NSWrapper` in Xcode, it does the following in a post-build action:

```
set -e
set -x

cd $PROJECT_DIR/MyProductCKNS
sh post-build-lib.sh
sh post-build-app.sh
```

The `post-build-lib` step creates `Module.node` and `libNodeAPI.dylib`. The `post-build-app` step copies `NSWrapper.app` into the .build directory, places `Module.node` into `NSWrapper.app/Contents/MacOS` and `libNodeAPI.dylib` into `NSWrapper.app/Contents/Frameworks`, doing the required code signing. As part of the process, I have to add to the rpath using install_name_tool on Module.node, which produces this warning, which is to be expected.

```
warning: changes being made to the file will invalidate the code signature in: ./NSWrapper.app/Contents/MacOS/Module.node
```

Later steps do the code signing, which verifies properly for both NSWrapper.app and Module.node (using `codesign -dvvvv`), and node loads the resulting Node module properly using `node index.js`. Unfortunately, I still end up with the same `Illegal instruction: 4` crash.

Crash logs look like:

```
-------------------------------------
Translated Report (Full Report Below)
-------------------------------------

Process:               node [75148]
Path:                  /Users/USER/*/node
Identifier:            node
Version:               ???
Code Type:             X86-64 (Native)
Parent Process:        bash [46697]
Responsible:           Terminal [5931]
User ID:               501

Date/Time:             2024-10-03 14:33:43.6742 -0700
OS Version:            macOS 14.6.1 (23G93)
Report Version:        12
Anonymous UUID:        D8F42156-6EB3-6538-461B-FD1C371AE765

Sleep/Wake UUID:       724C5B82-0602-43F7-B6C2-B1BBA6F2FAE0

Time Awake Since Boot: 1000000 seconds
Time Since Wake:       6859 seconds

System Integrity Protection: enabled

Crashed Thread:        0  Dispatch queue: com.apple.main-thread

Exception Type:        EXC_BAD_INSTRUCTION (SIGILL)
Exception Codes:       0x0000000000000001, 0x0000000000000000

Termination Reason:    Namespace SIGNAL, Code 4 Illegal instruction: 4
Terminating Process:   exc handler [75148]

Thread 0 Crashed::  Dispatch queue: com.apple.main-thread
0   CloudKit                              0x7ff815d135db 0x7ff815c32000 + 923099
1   CloudKit                              0x7ff815c69776 0x7ff815c32000 + 227190
2   CloudKit                              0x7ff815c696a1 0x7ff815c32000 + 226977
3   Module.node                              0x10c26f355 @nonobjc CKContainer.__allocating_init(identifier:) + 53
4   Module.node                              0x10c26f2a7 static MyModel.helloCloudKit() + 55 (MyModel.swift:19)
5   Module.node                              0x10c27029f closure #2 in closure #1 in $s13MyProductCKNS0025MyModelExportsswift_jqFBgfMX10_0_030_EDDBA243063FBD398423E0B1253E8F1BLl10NodeModulefMf_8registerfMu_(env:) + 207 (MyModelExports.swift:16)
6   libNodeAPI.dylib                         0x10c3f4755 thunk for @escaping @callee_guaranteed @Sendable (@guaranteed NodeArguments) -> (@out NodeValueConvertible, @error @owned Error) + 37
7   libNodeAPI.dylib                         0x10c3f47c4 partial apply for thunk for @escaping @callee_guaranteed @Sendable (@guaranteed NodeArguments) -> (@out NodeValueConvertible, @error @owned Error) + 20
8   libNodeAPI.dylib                         0x10c3f150a closure #1 in cCallback(rawEnv:info:) + 778 (NodeFunction.swift:11)
9   libNodeAPI.dylib                         0x10c3f1720 partial apply for closure #1 in cCallback(rawEnv:info:) + 16
10  libNodeAPI.dylib                         0x10c3e3463 static NodeContext._withContext<A>(_:environment:isTopLevel:do:) + 499 (NodeContext.swift:46)
11  libNodeAPI.dylib                         0x10c3e57bc closure #1 in static NodeContext.withContext<A>(environment:isTopLevel:do:) + 364 (NodeContext.swift:113)
12  libNodeAPI.dylib                         0x10c3e5865 partial apply for closure #1 in static NodeContext.withContext<A>(environment:isTopLevel:do:) + 53
13  libswift_Concurrency.dylib            0x7ffc25e03b3a TaskLocal.withValue<A>(_:operation:file:line:) + 186
14  libNodeAPI.dylib                         0x10c3e503f static NodeContext.withContext<A>(environment:isTopLevel:do:) + 895 (NodeContext.swift:112)
15  libNodeAPI.dylib                         0x10c3e5b3d closure #1 in static NodeContext.withUnsafeEntrypoint<A>(_:action:) + 285 (NodeContext.swift:127)
16  libNodeAPI.dylib                         0x10c3e5c04 partial apply for closure #1 in static NodeContext.withUnsafeEntrypoint<A>(_:action:) + 36
17  libNodeAPI.dylib                         0x10c3be96f thunk for @callee_guaranteed @Sendable () -> (@out A, @error @owned Error) + 15
18  libNodeAPI.dylib                         0x10c3be9ec partial apply for thunk for @callee_guaranteed @Sendable () -> (@out A, @error @owned Error) + 28
19  libNodeAPI.dylib                         0x10c3bead0 closure #1 in static NodeActor.unsafeAssumeIsolated<A>(_:) + 208 (NodeActor.swift:119)
20  libNodeAPI.dylib                         0x10c3bd439 static NodeActor.unsafeAssumeIsolated<A>(_:) + 137 (NodeActor.swift:118)
21  libNodeAPI.dylib                         0x10c3e59f7 static NodeContext.withUnsafeEntrypoint<A>(_:action:) + 231 (NodeContext.swift:126)
22  libNodeAPI.dylib                         0x10c3e58f2 static NodeContext.withUnsafeEntrypoint<A>(_:action:) + 130 (NodeContext.swift:122)
23  libNodeAPI.dylib                         0x10c3f11e1 cCallback(rawEnv:info:) + 321 (NodeFunction.swift:7)
24  libNodeAPI.dylib                         0x10c3f4cef closure #1 in closure #1 in closure #1 in NodeFunction.init(name:callback:) + 191 (NodeFunction.swift:90)
25  libNodeAPI.dylib                         0x10c3f4d19 @objc closure #1 in closure #1 in closure #1 in NodeFunction.init(name:callback:) + 9
26  node                                     0x1063dddb0 v8impl::(anonymous namespace)::FunctionCallbackWrapper::Invoke(v8::FunctionCallbackInfo<v8::Value> const&) + 128
27  node                                     0x10664eb58 v8::internal::MaybeHandle<v8::internal::Object> v8::internal::(anonymous namespace)::HandleApiCallHelper<false>(v8::internal::Isolate*, v8::internal::Handle<v8::internal::HeapObject>, v8::internal::Handle<v8::internal::FunctionTemplateInfo>, v8::internal::Handle<v8::internal::Object>, unsigned long*, int) + 856
28  node                                     0x10664e11a v8::internal::Builtin_HandleApiCall(int, unsigned long*, v8::internal::Isolate*) + 186
29  node                                     0x106ffa436 Builtins_CEntry_Return1_ArgvOnStack_BuiltinExit + 54
30  node                                     0x106f6bf1c Builtins_InterpreterEntryTrampoline + 220
31  node                                     0x106f6bf1c Builtins_InterpreterEntryTrampoline + 220
32  node                                     0x106f6bf1c Builtins_InterpreterEntryTrampoline + 220
33  node                                     0x106f6bf1c Builtins_InterpreterEntryTrampoline + 220
34  node                                     0x106f6bf1c Builtins_InterpreterEntryTrampoline + 220
35  node                                     0x106f6bf1c Builtins_InterpreterEntryTrampoline + 220
36  node                                     0x106f6bf1c Builtins_InterpreterEntryTrampoline + 220
37  node                                     0x106f6a2dc Builtins_JSEntryTrampoline + 92
38  node                                     0x106f6a003 Builtins_JSEntry + 131
39  node                                     0x1067325af v8::internal::(anonymous namespace)::Invoke(v8::internal::Isolate*, v8::internal::(anonymous namespace)::InvokeParams const&) + 3279
40  node                                     0x1067318c5 v8::internal::Execution::Call(v8::internal::Isolate*, v8::internal::Handle<v8::internal::Object>, v8::internal::Handle<v8::internal::Object>, int, v8::internal::Handle<v8::internal::Object>*) + 213
41  node                                     0x1066007e6 v8::Function::Call(v8::Local<v8::Context>, v8::Local<v8::Value>, int, v8::Local<v8::Value>*) + 502
42  node                                     0x10640a917 node::builtins::BuiltinLoader::CompileAndCall(v8::Local<v8::Context>, char const*, node::Realm*) + 311
43  node                                     0x1064ad150 node::Realm::ExecuteBootstrapper(char const*) + 64
44  node                                     0x1063eab07 node::StartExecution(node::Environment*, std::__1::function<v8::MaybeLocal<v8::Value> (node::StartExecutionCallbackInfo const&)>) + 2183
45  node                                     0x10633e637 node::LoadEnvironment(node::Environment*, std::__1::function<v8::MaybeLocal<v8::Value> (node::StartExecutionCallbackInfo const&)>, std::__1::function<void (node::Environment*, v8::Local<v8::Value>, v8::Local<v8::Value>)>) + 279
46  node                                     0x106474b80 node::NodeMainInstance::Run(node::ExitCode*, node::Environment*) + 272
47  node                                     0x10647489c node::NodeMainInstance::Run() + 124
48  node                                     0x1063ee642 node::Start(int, char**) + 850
49  dyld                                  0x7ff80c962345 start + 1909

```


Steps to Wrap The Bare Product CLI

1. Create MacOS App Target
2. Remove Sandbox
3. Remove AppIcon
4. Remove all UI-based folders and .swift files (Preview Content, Assets, ContentView.swift, \*App.swift)
5. In Build Settings...
    * Remove Deployment -> Development Assets
    * User Defined -> Enable_Previews -> NO
    * Build Options -> Enable Debug Dylib Support -> NO
6. Place main.swift in the folder with proper content, or otherwise marked @main. Generally don't need a bridging header.
7. Add iCloud -> CloudKit -> iCloud.<com.stevengharris.MyProductCK>

