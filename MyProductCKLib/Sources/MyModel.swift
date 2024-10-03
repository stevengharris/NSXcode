//
//  MyModel.swift
//  MyProductCKLib
//
//  Created by Steven Harris on 10/1/24.
//

import CloudKit

/// A simple model struct that doesn't depend on UI but does depend on CloudKit
public struct MyModel {
    
    public static func helloWorld() -> String {
        "Hello, world!"
    }
    
    // A method that will crash if CloudKit entitlements are not properly enabled
    public static func helloCloudKit() -> String {
        let _ = CKContainer(identifier: "iCloud.com.stevengharris.MyProductCK")
        return "Hello, CloudKit!"
    }

}
