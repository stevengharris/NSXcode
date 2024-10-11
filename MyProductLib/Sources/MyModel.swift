//
//  MyModel.swift
//  MyProductLib
//
//  Created by Steven Harris on 10/1/24.
//

/// A simple model struct that doesn't depend on UI
public struct MyModel {
    
    public static func helloWorld() -> String {
        "Hello, from Swift world!"
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
