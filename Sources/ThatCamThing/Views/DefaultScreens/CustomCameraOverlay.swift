//
//  File.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/3/25.
//

import Foundation
import SwiftUI
import ThatCamThing
import AVKit

/// A comprehensive camera overlay that provides a full-featured interface for camera controls.
/// This overlay includes flash controls, frame rate selection, zoom controls, settings panel,
/// and camera switching capabilities. It's designed to work with the ThatCamThing camera library.
/// User it for inspo on how to use the library or to test how the library actually works 
public struct CustomCameraOverlay:  CameraOverlay {
    
    // MARK: properties
    
    /// The camera manager that this overlay controls
    @ObservedObject var camera: CameraManager
    
    /// Controls the visibility of the frame rate picker overlay
    @State private var showFrameRatePicker = false
    @State private var showSettingsPanel = false
    
    // Frame rate options
    /// Available frame rate options for the camera
    private let frameRateOptions: [Int32] = [15, 24, 30, 60, 120]
    
    // Resolution options
    /// Available resolution presets for the camera
    private let resolutionOptions: [AVCaptureSession.Preset] = [
        .hd1280x720,
        .hd1920x1080,
        .hd4K3840x2160,
        .photo
    ]
    
    // MARK: initializers
    
    /// Initializes the camera overlay with a camera manager
       /// - Parameter camera: The CameraManager instance to control
    public init(camera: CameraManager) {
        self.camera = camera
    }
    
    public var body: some View {
        
        ZStack {
            
            VStack {
                topContainer

                Spacer()

                middleContainer

                Spacer()

                captureButton
                
                bottom
            }
            .padding(.horizontal)
            
            if showFrameRatePicker {
                overlayFrameRatePicker
            }
            
            if showSettingsPanel {
                settingsPannel
            }
        }
    }
    
    // MARK: Views

    //MARK: TOP Container
    /// Top container with flash, frame rate, and camera rotation controls

    private var topContainer: some View {
        HStack {
            flashButton
            Spacer()
            frameRateBtn
            Spacer()
            rotateCamera
        }
    }
    
    /// Flash control button that cycles through off, on, and auto modes
    private var flashButton: some View {
        return  Button(action: {
            camera.switchFlash()
        }) {
            Image(systemName: camera.flashMode == .off ? "bolt.slash" : (camera.flashMode == .on ? "bolt" : "bolt.badge.a"))
                .font(.title2)
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
    }
    
    /// Frame rate selection button that displays current FPS and opens the frame rate picker
    private var frameRateBtn: some View {
        Button(action: {
            withAnimation {
                showFrameRatePicker.toggle()
                showSettingsPanel = false
            }
        }) {
            VStack(spacing: 2) {
                Text("\(camera.attributes.frameRate)")
                    .font(.system(.title2, design: .monospaced, weight: .bold))
                    .foregroundColor(.white)
                Text("FPS")
                    .font(.system(.caption, design: .monospaced, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.6))
            .cornerRadius(8)
        }
    }
    
    /// Camera rotation button that switches between front and back cameras
    private var rotateCamera: some View {
        Button(action: {
            camera.switchCamera()
        }) {
            Image(systemName: "camera.rotate")
                .font(.title2)
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
    }
    
    // MARK: Middle container
    
    /// Middle container that houses the settings button and zoom controls
        /// Positioned on opposite sides of the screen for easy access
    private var middleContainer: some View  {
        HStack {
            settingsBtn
            Spacer()
            cameraZoomPanel
        }
    }
    
    /// Settings button that opens the camera settings panel
    private var settingsBtn: some View {
        
        Button(action: {
            withAnimation(.spring()) {
                showSettingsPanel.toggle()
                showFrameRatePicker = false
            }
        }) {
            Image(systemName: "gearshape.fill")
                .font(.title2)
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
    }
    
    /// This view includes:
    /// Vertical panel containing zoom controls:
    /// - Zoom in button (+)
    /// - Current zoom level display
    /// - Zoom out button (-)
    private var cameraZoomPanel: some View {
        
        VStack(spacing: 20) {
            
            VStack {
                addZoomBtn
                
                currentZoomFactor
                
                decrementZoomBtn
            }
            
        }
    }
    
    /// Button to increase zoom by 0.5x increments
    private var addZoomBtn: some View {
        Button(action: {
            camera.setZoom(camera.attributes.zoomFactor + 0.5)
        }) {
            Image(systemName: "plus")
                .font(.title3)
                .foregroundColor(.white)
                .padding(12)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
    }
    
    /// Display showing the current zoom factor (e.g., "2.0x")
    private var currentZoomFactor: some View {
        Text("\(String(format: "%.1f", camera.attributes.zoomFactor))x")
            .font(.system(.caption, design: .monospaced, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.6))
            .cornerRadius(4)
    }
    
    /// Button to decrease zoom by 0.5x increments (minimum 1.0x)
    private var decrementZoomBtn: some View {
        Button(action: {
            camera.setZoom(max(1.0, camera.attributes.zoomFactor - 0.5))
        }) {
            Image(systemName: "minus")
                .font(.title3)
                .foregroundColor(.white)
                .padding(12)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
    }
    
    // MARK: Capture Button
    
    /// Main capture button for taking photos
    /// Disabled when camera is paused, with visual indication
    private var captureButton: some View {
        VStack {
            Button(action: {
                camera.takePicture()
            }) {
                Circle()
                    .stroke(Color.white, lineWidth: 5)
                    .frame(width: 80, height: 80)
                    .background(
                        Circle()
                            .fill(camera.attributes.isPaused ? Color.white.opacity(0.5) : Color.white)
                            .frame(width: 70, height: 70)
                    )
            }
            .disabled(camera.attributes.isPaused)
        }
        .padding(.bottom, 50)
    }
    
    // MARK: Bottom Container
    
    /// Bottom container with pause/play, status, and lens switching controls
    private var bottom: some View {
        HStack {
            playPauseBtn
            Spacer()
            cameraStatusHUD
            changeCameraLensBtn
        }
    }
    
    private var playPauseBtn: some View {
        Button(action: {
            if camera.attributes.isPaused {
                camera.resumeCamera()
            } else {
                camera.pauseCamera()
            }
        }) {
            Image(systemName: camera.attributes.isPaused ? "play.fill" : "pause.fill")
                .font(.title3)
                .foregroundColor(.white)
                .padding(12)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
    }
    
    /// Button to switch between wide and ultra-wide camera lenses
       /// Automatically disabled if ultra-wide is not available on the device
    private var changeCameraLensBtn: some View {
        Button(action: {
            camera.switchLensType()
        }) {
            VStack(spacing: 2) {
                Image(systemName: camera.attributes.lensType == .wide ? "camera" : "camera.aperture")
                    .font(.title3)
                    .foregroundColor(.white)
                Text(camera.attributes.lensType.displayName)
                    .font(.system(.caption2, design: .monospaced, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.6))
            .cornerRadius(8)
        }
        .opacity(camera.isUltraWideAvailable() ? 1.0 : 0.5)
        .disabled(!camera.isUltraWideAvailable())
    }
    
    /// Status indicator showing camera health and current position (front/back)
    private var cameraStatusHUD: some View {
        VStack(spacing: 4) {
            if let _ = camera.cameraErrors {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            
            Text(camera.attributes.cameraPosition == .back ? "BACK" : "FRONT")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(8)
        .background(Color.black.opacity(0.6))
        .cornerRadius(8)
    }
    
    
    // MARK: Overlays
    
    /// Horizontal scrollable frame rate picker overlay
    /// Appears when the frame rate button is tapped
    private var overlayFrameRatePicker: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(frameRateOptions, id: \.self) { frameRate in
                        Button(action: {
                            camera.setFrameRate(frameRate)
                            
                            withAnimation {
                                showFrameRatePicker = false
                            }
                        }) {
                            VStack(spacing: 4) {
                                Text("\(frameRate)")
                                    .font(.system(.title3, design: .monospaced, weight: .bold))
                                Text("fps")
                                    .font(.system(.caption2, design: .monospaced))
                            }
                            .foregroundColor(camera.attributes.frameRate == frameRate ? .black : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(camera.attributes.frameRate == frameRate ?
                                          Color.white : Color.black.opacity(0.6))
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 120)
            Spacer()
        }
        .background(
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showFrameRatePicker = false
                    }
                }
        )
    }
    

    // MARK: Settings Panel

    /// Main settings panel overlay containing camera configuration options
    /// Slides up from the bottom when settings button is tapped
    private var settingsPannel: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                settingsHeader
                
                VStack(spacing: 20) {
                    resolution
                    
                    cameraStatus
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            
        }
        .background(
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        showSettingsPanel = false
                    }
                }
        )
    }
    
    /// Header for the settings panel containing title and close butto
    private var settingsHeader: some View {
        HStack {
            Text("Camera Settings")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring()) {
                    showSettingsPanel = false
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .font(.title2)
            }
        }
    }
    /// Resolution selector section in the settings panel
    /// Currently shows available resolutions but needs implementation (marked with TODO)
    private var resolution: some View {
        // Resolution selector
        VStack(alignment: .leading, spacing: 8) {
            Text("Resolution")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 8) {
                ForEach(resolutionOptions, id: \.self) { resolution in
                    Button(action: {
                        // TODO:
                    }) {
                        Text(resolutionName(resolution))
                            .font(.system(.caption, design: .monospaced, weight: .medium))
                            .foregroundColor(camera.attributes.resolution == resolution ? .black : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(camera.attributes.resolution == resolution ?
                                          Color.white : Color.white.opacity(0.2))
                            )
                    }
                }
            }
        }
    }
    
    /// Camera status section showing current operational state
    private var cameraStatus: some View {
        HStack {
            Text("Status")
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            if let _ = camera.cameraErrors {
                errorStatus
            } else {
                healthyStatus
            }
        }
    }
    
    /// Error status indicator (red triangle with "Error" text)
    private var errorStatus: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text("Error")
                .foregroundColor(.red)
        }
    }
    
    /// Healthy status indicator (green checkmark with "Ready" text)
    private var healthyStatus: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("Ready")
                .foregroundColor(.green)
        }
    }
    
    // MARK: helper methods
    
    /// Converts AVCaptureSession.Preset to human-readable resolution names
    /// - Parameter preset: The resolution preset to convert
    /// - Returns: A string representation of the resolution (e.g., "1080p", "4K")
    private func resolutionName(_ preset: AVCaptureSession.Preset) -> String {
        switch preset {
        case .hd1280x720: return "720p"
        case .hd1920x1080: return "1080p"
        case .hd4K3840x2160: return "4K"
        case .photo: return "Photo"
        default: return "Unknown"
        }
    }
    
}
