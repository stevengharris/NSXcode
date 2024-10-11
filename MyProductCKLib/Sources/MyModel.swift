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
        "Hello, from Swift world!"
    }
    
    // A method that will crash if CloudKit entitlements are not properly enabled
    public static func helloCloudKit(_ container: String? = nil) -> String {
        let identifier = container ?? "iCloud.com.stevengharris.MyProductCK"
        let _ = CKContainer(identifier: identifier)
        return "Hello, CloudKit!"
    }
    
    // For consistency with the existing node-swift example...
    
    public static let nums: Array<Double> = [Double.pi.rounded(.down), Double.pi.rounded(.up)]
    
    public static let str = String(repeating: "NodeSwift! ", count: 3)
    
    public static func add(a: Double, b: Double) async -> String {
        print("calculating...")
        try? await Task.sleep(nanoseconds: 500_000_000)
        return "\(a) + \(b) = \(a + b)"
    }
    
}
