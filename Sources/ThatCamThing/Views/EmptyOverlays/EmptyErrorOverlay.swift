//
//  EmptyErrorOverlay.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/3/25.
//
import SwiftUI

public struct EmptyErrorOverlay: View {
    public let camera: CameraError
    
    public init(camera: CameraError) {
        self.camera = camera
    }
    
    public var body: some View {
        EmptyView()
    }
}
