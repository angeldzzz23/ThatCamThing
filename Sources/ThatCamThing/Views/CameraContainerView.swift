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
public struct CameraView<Overlay: CameraOverlay, ErrorOverlay: View>: View {
    
    @StateObject private var camera = CameraManager()
 
    private let overlay: (CameraManager) -> Overlay
    private let errorOverlay: (CameraError) -> ErrorOverlay
    private var onImageCapturedAction: ((UIImage) -> Void)?
    private let defaultAttributes: CameraManagerAttributes?

    // This initializer is fileprivate to ensure it's only used by our extension methods.
    fileprivate init(
        overlay: @escaping (CameraManager) -> Overlay,
        errorOverlay: @escaping (CameraError) -> ErrorOverlay,
        onImageCaptured: ((UIImage) -> Void)? = nil,
        defaultAttributes: CameraManagerAttributes? = nil
    ) {
        self.overlay = overlay
        self.errorOverlay = errorOverlay
        self.onImageCapturedAction = onImageCaptured
        self.defaultAttributes = defaultAttributes
    }

    public var body: some View {
        ZStack {
            if !camera.containsErrors {
                CameraPreview(camera: camera)
                    .ignoresSafeArea(.all)
                
            } else {
                Color.black.ignoresSafeArea(.all)
            }
            overlay(camera)
            
            if camera.containsErrors {
                // Pass the camera error to the error overlay
                if let cameraError = camera.cameraErrors {
                    errorOverlay(cameraError)
                }
            }
            
        }
        .onAppear(perform: setupCameraWithAttributes)
        .onChange(of: camera.capturedMedia?.image) { oldValue, newValue in
            if let newValue {
                onImageCapturedAction?(newValue)
            }
        }
       
    }
    
    private func setupCameraWithAttributes() {
        // Apply default attributes if provided
        if let attributes = defaultAttributes {
            camera.attributes = attributes
        }
        camera.checkPermissions()
    }
}

public struct EmptyErrorOverlay: View {
    public let camera: CameraError
    
    public init(camera: CameraError) {
        self.camera = camera
    }
    
    public var body: some View {
        EmptyView()
    }
}

// Public initializer for creating a CameraView without any overlays.
extension CameraView where Overlay == EmptyCameraOverlay, ErrorOverlay == EmptyErrorOverlay {
    /// Initializes a CameraView without any custom overlays.
    public init() {
        self.init(
            overlay: { EmptyCameraOverlay(camera: $0) },
            errorOverlay: { EmptyErrorOverlay(camera: $0) },
            onImageCaptured: nil,
            defaultAttributes: nil
        )
    }
    
    /// Initializes a CameraView with default attributes.
    public init(attributes: CameraManagerAttributes) {
        self.init(
            overlay: { EmptyCameraOverlay(camera: $0) },
            errorOverlay: { EmptyErrorOverlay(camera: $0) },
            onImageCaptured: nil,
            defaultAttributes: attributes
        )
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
        CameraView<Overlay, ErrorOverlay>(
            overlay: self.overlay,
            errorOverlay: self.errorOverlay,
            onImageCaptured: action,
            defaultAttributes: self.defaultAttributes
        )
    }

    /**
     Sets a custom overlay for the camera view.
     - parameter content: A closure that returns the overlay view. It receives a `CameraManager` instance to control the camera.
     - returns: A new `CameraView` with the specified overlay.
     */
    public func setOverlayScreen<NewOverlay: CameraOverlay>(_ content: @escaping (CameraManager) -> NewOverlay) -> CameraView<NewOverlay, ErrorOverlay> {
        CameraView<NewOverlay, ErrorOverlay>(
            overlay: content,
            errorOverlay: self.errorOverlay,
            onImageCaptured: self.onImageCapturedAction,
            defaultAttributes: self.defaultAttributes
        )
    }
    
    /**
     Sets a custom error screen for the camera view.
     - parameter content: A closure that returns the error view. It receives a `CameraError` instance.
     - returns: A new `CameraView` with the specified error screen.
     */
    public func setErrorScreen<NewErrorOverlay: View>(_ content: @escaping (CameraError) -> NewErrorOverlay) -> CameraView<Overlay, NewErrorOverlay> {
        CameraView<Overlay, NewErrorOverlay>(
            overlay: self.overlay,
            errorOverlay: content,
            onImageCaptured: self.onImageCapturedAction,
            defaultAttributes: self.defaultAttributes
        )
    }
    
    /**
     Sets default camera attributes for the camera view.
     - parameter attributes: The default `CameraManagerAttributes` to use.
     - returns: A new `CameraView` with the specified default attributes.
     */
    public func setAttributes(_ attributes: CameraManagerAttributes) -> CameraView<Overlay, ErrorOverlay> {
        CameraView<Overlay, ErrorOverlay>(
            overlay: self.overlay,
            errorOverlay: self.errorOverlay,
            onImageCaptured: self.onImageCapturedAction,
            defaultAttributes: attributes
        )
    }
}
