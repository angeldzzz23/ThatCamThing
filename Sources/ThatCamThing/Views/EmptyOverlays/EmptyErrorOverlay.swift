//
//  EmptyErrorOverlay.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/3/25.
//
import SwiftUI

/// A no-op implementation of an error overlay that renders nothing.
///
/// Useful as a default error overlay when no error UI should be shown over the camera preview.
/// This struct conforms to `View` and is initialized with a `CameraError`, but does not display it.
public struct EmptyErrorOverlay: View {
    public let camera: CameraError
    
    public init(camera: CameraError) {
        self.camera = camera
    }
    
    public var body: some View {
        EmptyView()
    }
}
