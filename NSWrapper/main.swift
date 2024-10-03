//
//  main.swift
//  MyProject
//
//  Created by Steven Harris on 10/3/24.
//

import CloudKit

print("Hello, World!")

// The following will crash if CloudKit entitlements are not set up properly
_ = CKContainer(identifier: "iCloud.com.stevengharris.MyProductCK")

// So if we get here, CloudKit can be accessed
print("Hello, CloudKit!")
