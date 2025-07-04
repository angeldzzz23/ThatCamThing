//
//  DefaultCameraErrorView.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/3/25.
//
import SwiftUI
import ThatCamThing

/// A default implementation of `ErrorOverlay` that displays a full-screen message
/// when camera access is denied or fails due to permissions.
///
/// This view provides the user with:
/// - A clear title indicating the error
/// - A subtitle explaining the cause and action
/// - A button that takes the user to the app's Settings page
///
/// Use this as the default error overlay to handle permission-related errors in a user-friendly way.
public struct DefaultCameraErrorView: ErrorOverlay {
    
    let cameraError: CameraError

    public init(cameraError: CameraError) {
        self.cameraError = cameraError
    }

    public var body: some View {
        VStack {
            title
            subtitle
            settingsButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private var title: some View {
        Text("Camera Access Denied")
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding()
    }
    
    private var subtitle: some View {
        Text("To use the camera, please grant permission in your device's settings.")
            .font(.body)
            .foregroundColor(.white.opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
    
    private var settingsButton: some View {
        Button(action: {
            openSettings()
        }) {
            Text("Go to Settings")
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(Color.white)
                .cornerRadius(10)
        }
        .padding(.top)
    }
    
    
}
