//
//  ContentView.swift
//  MyProductCK
//
//  Created by Steven Harris on 10/2/24.
//

import SwiftUI
import MyProductCKLib

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(MyModel.helloWorld())
            Text(MyModel.helloCloudKit())
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
