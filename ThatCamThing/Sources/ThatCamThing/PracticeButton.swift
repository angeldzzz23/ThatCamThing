//
//  SwiftUIView.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/1/25.
//

import SwiftUI

public struct PracticeButton: View {
    
    public var angel = "Hello"
    public init() {}
    
    public var body: some View {
        

        Button("Button") {
            Text("Hello, World!")
        }
    }
}

#Preview {
    PracticeButton()
}
