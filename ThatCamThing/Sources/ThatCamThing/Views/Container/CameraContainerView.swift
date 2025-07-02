//
//  File.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/1/25.
//

import SwiftUI

// TODO: user an alternative to .onchange to add support for lower versions of iOS 17
// TODO: user an alternative to .onchange to add support for lower versions of iOS 17
public struct CameraContainerView<Overlay: CameraOverlayView>: View {
    
    @StateObject private var cameraManager: CameraManager
    
    let onImageCapturedCallback: ((UIImage) -> Void)?
    let onCameraStateChanged: ((CameraManager) -> Void)?
    let customErrorHandler: ((CameraError) -> Void)?
    let defaultAttributes: CameraManagerAttributes
    
    // Store the overlay creation closure
    private let createOverlay: (CameraManager) -> Overlay
    
    public init(
        attributes: CameraManagerAttributes = .init(),
        onImageCaptured: ((UIImage) -> Void)? = nil,
        onStateChanged: ((CameraManager) -> Void)? = nil,
        errorHandler: ((CameraError) -> Void)? = nil
    ) where Overlay == DefaultCameraOverlay<CameraManager> {
        self.defaultAttributes = attributes
        self._cameraManager = StateObject(wrappedValue: CameraManager(initialAttributes: attributes))
        self.onImageCapturedCallback = onImageCaptured
        self.onCameraStateChanged = onStateChanged
        self.customErrorHandler = errorHandler
        self.createOverlay = { manager in
            DefaultCameraOverlay(cameraControl: manager) as! Overlay
        }
    }
    
    // Private init for custom overlay
    private init(
        attributes: CameraManagerAttributes,
        onImageCaptured: ((UIImage) -> Void)?,
        onStateChanged: ((CameraManager) -> Void)?,
        errorHandler: ((CameraError) -> Void)?,
        createOverlay: @escaping (CameraManager) -> Overlay
    ) {
        self.defaultAttributes = attributes
        self._cameraManager = StateObject(wrappedValue: CameraManager(initialAttributes: attributes))
        self.onImageCapturedCallback = onImageCaptured
        self.onCameraStateChanged = onStateChanged
        self.customErrorHandler = errorHandler
        self.createOverlay = createOverlay
    }
    
    public var body: some View {
        ZStack {
            CameraPreview(session: cameraManager.session)
                .ignoresSafeArea()
            
            // Create the overlay using the closure
            createOverlay(cameraManager)
        }
        .setErrorScreen(DefaultErrorScreen.self)
        .onAppear {
            setupCameraManager()
        }
        .onChange(of: cameraManager.isSessionRunning) { _, newValue in
            if newValue {
                onCameraStateChanged?(cameraManager)
            }
        }
        .onChange(of: cameraManager.attributes.error) { _, error in
            if let error = error {
                handleError(error)
            }
        }
    }
    
    private func setupCameraManager() {
        cameraManager.onImageCaptured = onImageCapturedCallback
        cameraManager.requestPermissions()
    }
    
    private func handleError(_ error: CameraError) {
        if let customErrorHandler = customErrorHandler {
            customErrorHandler(error)
        } else {
            // Default error handling
            switch error {
            case .cameraPermissionsNotGranted:
                cameraManager.showAlert(message: "Camera permissions are required to use this feature. Please enable camera access in Settings.")
            case .cannotSetupInput:
                cameraManager.showAlert(message: "Unable to setup camera input. Please try again.")
            case .cannotSetupOutput:
                cameraManager.showAlert(message: "Unable to setup camera output. Please try again.")
            }
        }
    }
}

public extension CameraContainerView {
    public func setOverlayScreen<T: CameraOverlayView>(_ overlayType: T.Type) -> CameraContainerView<T>
     where T.Control == CameraManager {
         return CameraContainerView<T>(
             attributes: defaultAttributes,
             onImageCaptured: onImageCapturedCallback,
             onStateChanged: onCameraStateChanged,
             errorHandler: customErrorHandler,
             createOverlay: { manager in
                 T(cameraControl: manager)
             }
         )
     }
    
    /// Set a callback for when an image is captured
    public func onImageCaptured(_ callback: @escaping (UIImage) -> Void) -> CameraContainerView<Overlay> {
        CameraContainerView<Overlay>(
            attributes: defaultAttributes,
            onImageCaptured: callback,
            onStateChanged: onCameraStateChanged,
            errorHandler: customErrorHandler,
            createOverlay: createOverlay
        )
    }
    
    /// Set a callback for when camera state changes (e.g., session starts)
    public func onCameraStateChanged(_ callback: @escaping (CameraManager) -> Void) -> CameraContainerView<Overlay> {
        CameraContainerView<Overlay>(
            attributes: defaultAttributes,
            onImageCaptured: onImageCapturedCallback,
            onStateChanged: callback,
            errorHandler: customErrorHandler,
            createOverlay: createOverlay
        )
    }
    
    /// Set a custom error handler
    public  func onError(_ handler: @escaping (CameraError) -> Void) -> CameraContainerView<Overlay> {
        CameraContainerView<Overlay>(
            attributes: defaultAttributes,
            onImageCaptured: onImageCapturedCallback,
            onStateChanged: onCameraStateChanged,
            errorHandler: handler,
            createOverlay: createOverlay
        )
    }
    
    /// Configure initial camera settings
    public func cameraConfiguration(_ configuration: @escaping (CameraManager) -> Void) -> CameraContainerView<Overlay> {
        let newView = CameraContainerView<Overlay>(
            attributes: defaultAttributes,
            onImageCaptured: onImageCapturedCallback,
            onStateChanged: { manager in
                configuration(manager)
                onCameraStateChanged?(manager)
            },
            errorHandler: customErrorHandler,
            createOverlay: createOverlay
        )
        return newView
    }
}

// MARK: - Convenience typealias for default usage
public typealias DefaultCameraContainerView = CameraContainerView<DefaultCameraOverlay<CameraManager>>

