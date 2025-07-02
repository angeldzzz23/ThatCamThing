//
//  File.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/1/25.
//

import SwiftUI

struct ErrorScreenModifier<ErrorScreen: ErrorScreenView>: ViewModifier {
    let errorScreenType: ErrorScreen.Type
    @State private var currentError: Error?
    @State private var showError: Bool = false
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .onReceive(NotificationCenter.default.publisher(for: .cameraError)) { notification in
                    if let error = notification.object as? Error {
                        currentError = error
                        showError = true
                    }
                }
            
            if showError, let error = currentError {
                errorScreenType.init(error: error) {
                    retryCamera()
                }
            }
        }
    }
    
    private func retryCamera() {
        currentError = nil
        showError = false
        NotificationCenter.default.post(name: .cameraRetry, object: nil)
    }
}



extension View {
    /// Sets a custom error screen view type
    func setErrorScreen<T: ErrorScreenView>(_ errorScreenType: T.Type) -> some View {
        modifier(ErrorScreenModifier(errorScreenType: errorScreenType))
    }
    
    /// Sets the default error screen
    func setErrorScreen() -> some View {
        modifier(ErrorScreenModifier(errorScreenType: DefaultErrorScreen.self))
    }
}

extension Notification.Name {
    static let cameraError = Notification.Name("cameraError")
    static let cameraRetry = Notification.Name("cameraRetry")
}

// MARK: - LocalizedError extension for better error messages
extension CameraError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .cameraPermissionsNotGranted:
            return "Camera permissions not granted"
        case .cannotSetupInput:
            return "Cannot setup camera input"
        case .cannotSetupOutput:
            return "Cannot setup camera output"
        }
    }
}

extension CameraManager {
    func handleError(_ error: Error) {
        NotificationCenter.default.post(name: .cameraError, object: error)
    }
    
    func setupRetryListener() {
        NotificationCenter.default.addObserver(
            forName: .cameraRetry,
            object: nil,
            queue: .main
        ) { _ in
            self.retrySetup()
        }
    }
    
    private func retrySetup() {
        // Your retry logic here
        print("Retrying camera setup...")
    }
}
