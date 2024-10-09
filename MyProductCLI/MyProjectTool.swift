//
//  MyProjectTool.swift
//  MyProject
//
//  Created by Steven Harris on 10/8/24.
//

import MyProductCKLib
import ArgumentParser

@main struct MyProjectTool: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(commandName: "myproject")
    
    @Option(name: [.short, .customLong("icloud")], help: ArgumentHelp("Check iCloud access.", valueName: "container"))
    var iCloudContainer: String?
    
    @Argument(parsing: .allUnrecognized, help: .hidden)
    var other: [String] = []
    
    mutating func run() async throws {
        
        // Let the user know if any arguments were unrecognized and therefore ignored
        showUnrecognized()
        
        // If iCloudContainer, set and report result, and then process more args
        if let iCloudContainer {
            print(MyModel.helloCloudKit(iCloudContainer))
            return
        }
        
    }
    
    func showUnrecognized() {
        if !other.isEmpty {
            print("\nWarning: Unrecognized arguments ignored...")
            print(" \(other.joined(separator: " "))\n")
        }
    }
    
}

