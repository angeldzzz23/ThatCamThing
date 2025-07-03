//
//  File.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/2/25.
//

import SwiftUI
import AVKit
import ThatCamThing

// The container view. It manages the camera session and preview.
// Overlays are now configured via the .setOverlayScreen and .setErrorScreen modifiers.
public struct CameraView<Overlay: View, ErrorOverlay: View>: View {
    
    @StateObject private var camera = CameraManager()
 
    private let overlay: (CameraManager) -> Overlay
    private let errorOverlay: (CameraManager) -> ErrorOverlay
    private var onImageCapturedAction: ((UIImage) -> Void)?

    // This initializer is fileprivate to ensure it's only used by our extension methods.
    fileprivate init(
        overlay: @escaping (CameraManager) -> Overlay,
        errorOverlay: @escaping (CameraManager) -> ErrorOverlay,
        onImageCaptured: ((UIImage) -> Void)? = nil
    ) {
        self.overlay = overlay
        self.errorOverlay = errorOverlay
        self.onImageCapturedAction = onImageCaptured
    }

    public var body: some View {
        ZStack {
            // Only render the CameraPreview if our gate is open and permissions are granted.
            if !camera.showAlert {
                CameraPreview(camera: camera)
                    .ignoresSafeArea(.all)
            } else {
                // Provide a black background when the camera is not active.
                Color.black.ignoresSafeArea(.all)
            }
            
            // The custom overlay is always visible.
            overlay(camera)
            
            // Show error overlay if needed.
            if camera.showAlert {
                errorOverlay(camera)
            }
        }
        .onAppear(perform: checkPermissionsAndUpdateState)

        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // When returning, re-check permissions before opening the gate.
            checkPermissionsAndUpdateState()
        }
        .onChange(of: camera.attributes.capturedMedia?.image) { oldValue, newValue in
            if let newValue {
                onImageCapturedAction?(newValue)
            }
        }
    }
    
    private func checkPermissionsAndUpdateState() {
       
        DispatchQueue.main.async {
            camera.checkPermissions()
            
            
        }
    }
}

// Public initializer for creating a CameraView without any overlays.
extension CameraView where Overlay == EmptyView, ErrorOverlay == EmptyView {
    /// Initializes a CameraView without any custom overlays.
    public init() {
        self.init(overlay: { _ in EmptyView() }, errorOverlay: { _ in EmptyView() }, onImageCaptured: nil)
    }
}

// This extension provides the public modifiers for setting overlays.
extension CameraView {
    /**
     Sets a closure to be called when an image is captured.
     - parameter action: A closure that receives the captured `UIImage`.
     - returns: A new `CameraView` configured with the image capture action.
     */
    public func onImageCaptured(_ action: @escaping (UIImage) -> Void) -> CameraView<Overlay, ErrorOverlay> {
        var newView = self
        newView.onImageCapturedAction = action
        return newView
    }

    /**
     Sets a custom overlay for the camera view.
     - parameter content: A closure that returns the overlay view. It receives a `CameraManager` instance to control the camera.
     - returns: A new `CameraView` with the specified overlay.
     */
    public func setOverlayScreen<NewOverlay: View>(_ content: @escaping (CameraManager) -> NewOverlay) -> CameraView<NewOverlay, ErrorOverlay> {
        CameraView<NewOverlay, ErrorOverlay>(
            overlay: content,
            errorOverlay: self.errorOverlay,
            onImageCaptured: self.onImageCapturedAction
        )
    }
    
    /**
     Sets a custom error screen for the camera view.
     - parameter content: A closure that returns the error view. It receives a `CameraManager` instance.
     - returns: A new `CameraView` with the specified error screen.
     */
    public func setErrorScreen<NewErrorOverlay: View>(_ content: @escaping (CameraManager) -> NewErrorOverlay) -> CameraView<Overlay, NewErrorOverlay> {
        CameraView<Overlay, NewErrorOverlay>(
            overlay: self.overlay,
            errorOverlay: content,
            onImageCaptured: self.onImageCapturedAction
        )
    }
}


