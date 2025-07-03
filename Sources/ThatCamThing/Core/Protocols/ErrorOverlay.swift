//
//  File.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/3/25.
//


import SwiftUI

/// A protocol that defines an overlay view used to present camera-related errors on top of the camera preview.
///
/// Conforming types must implement SwiftUI's `View` protocol and be initializable with a `CameraError`.
/// This allows developers to customize how camera errors (e.g., permission denied, setup failure) are displayed
/// to users in the UI layer.
///
/// Typical usage includes overlays that display alerts, messages etc.
public protocol ErrorOverlay: View {
    /// Creates a new error overlay view using the provided `CameraError`.
       ///
       /// - Parameter cameraError: The error encountered by the camera session.
    init(cameraError: CameraError)
}


//public struct EmptyErrorOverlay: View {
//    public let camera: CameraError
//    
//    public init(camera: CameraError) {
//        self.camera = camera
//    }
//    
//    public var body: some View {
//        EmptyView()
//    }
//}
