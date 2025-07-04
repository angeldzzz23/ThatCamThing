//
//  conforms.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/3/25.
//
import SwiftUI

/// A no-op implementation of `CameraOverlay` that renders nothing.
///
/// Useful as a default overlay when no additional UI is needed above the camera preview.
/// This struct conforms to `CameraOverlay` and can be used to disable overlays explicitly.
public struct EmptyCameraOverlay: CameraOverlay {
    
    public init(camera: CameraManager) {
        // Empty initializer - we don't need to store the camera manager
    }
    
    public var body: some View {
        EmptyView()
    }
}
