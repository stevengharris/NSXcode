//
//  ContentView.swift
//  MyProduct
//
//  Created by Steven Harris on 10/1/24.
//

import SwiftUI
import MyProductLib

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(MyModel.helloWorld())
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
