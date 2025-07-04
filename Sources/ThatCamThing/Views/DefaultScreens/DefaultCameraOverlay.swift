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

public struct CustomCameraOverlay:  CameraOverlay {
    
    @ObservedObject var camera: CameraManager
    @State private var showFrameRatePicker = false
    @State private var showSettingsPanel = false
    
    public init(camera: CameraManager) {
        self.camera = camera
    }
    
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
    
    private var bottom: some View {
        HStack {
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
            Spacer()
            cameraStatusHUD
            cameraLens
        }
    }
    
    // Frame rate options
    private let frameRateOptions: [Int32] = [15, 24, 30, 60, 120]
    
    // Resolution options
    private let resolutionOptions: [AVCaptureSession.Preset] = [
        .hd1280x720,
        .hd1920x1080,
        .hd4K3840x2160,
        .photo
    ]
    
    private func resolutionName(_ preset: AVCaptureSession.Preset) -> String {
        switch preset {
        case .hd1280x720: return "720p"
        case .hd1920x1080: return "1080p"
        case .hd4K3840x2160: return "4K"
        case .photo: return "Photo"
        default: return "Unknown"
        }
    }
       
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
    
    private var rightSide: some View {
        
        VStack(spacing: 20) {
            
            VStack {
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
                
                Text("\(String(format: "%.1f", camera.attributes.zoomFactor))x")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(4)
                
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
            
        }
        
    }
    
    
    private var middleContainer: some View  {
        HStack {
            settingsBtn
            Spacer()
            rightSide
        }
    }
    
    private func changeCameraSetting(action: @escaping () -> Void) {
        // Check if the camera was running before this operation.
        let wasRunning = !camera.attributes.isPaused
        
        // If it was running, pause it first.
        if wasRunning {
            camera.pauseCamera()
        }
        
        // Perform the action and then resume on the next run cycle.
        // This gives the session time to properly process the state changes.
        DispatchQueue.main.async {
            action()
            if wasRunning {
                camera.resumeCamera()
            }
        }
    }
    
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
            
            // OVERLAY: Frame rate picker
            if showFrameRatePicker {
                VStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(frameRateOptions, id: \.self) { frameRate in
                                Button(action: {
                                    changeCameraSetting {
                                        camera.setFrameRate(frameRate)
                                    }
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
            
            if showSettingsPanel {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 20) {
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
                        
                        VStack(spacing: 20) {
                            // Resolution selector
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Resolution")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 8) {
                                    ForEach(resolutionOptions, id: \.self) { resolution in
                                        Button(action: {
                                            changeCameraSetting {
                                                camera.attributes.resolution = resolution
                                            }
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
                            
                            // Mirror output toggle
                            HStack {
                                Text("Mirror Output")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button(action: {
                                    changeCameraSetting {
                                        camera.attributes.mirrorOutput.toggle()
                                    }
                                }) {
                                    Image(systemName: camera.attributes.mirrorOutput ? "checkmark.square.fill" : "square")
                                        .foregroundColor(.white)
                                        .font(.title2)
                                }
                            }
                            
                            // Status
                            HStack {
                                Text("Status")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if let error = camera.cameraErrors {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                        Text("Error")
                                            .foregroundColor(.red)
                                    }
                                } else {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Ready")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
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
        }
       
    }
    
    private var topContainer: some View {
        HStack {
            flashButton
            Spacer()
            frameRateBtn
            Spacer()
            rotateCamera
        }
    }
    
    private var cameraLens: some View {
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
    
    private var settingsContainer: some View {
        HStack {
            settingsBtn
        }
    }
    
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
}
