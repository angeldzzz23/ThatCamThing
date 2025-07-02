//
//  File.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/1/25.
//

import SwiftUI
import AVKit

public struct DefaultCameraOverlay<Control: CameraControl>: CameraOverlayView {
    
    @ObservedObject var cameraControl: Control

    
    public init(cameraControl: Control) {
        self.cameraControl = cameraControl
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Button("Switch Camera") {
                    cameraControl.switchCamera()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
                
                Spacer()
                
                Button("Flash: \(flashModeText(cameraControl.flashMode))") {
                    cameraControl.toggleFlashMode()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
            HStack {
                Button("Resolution: \(resolutionText(cameraControl.resolution))") {
                    cameraControl.cycleResolution()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
                
                Spacer()
                
                Button("FPS: \(cameraControl.frameRate)") {
                    cameraControl.cycleFrameRate()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
            HStack {
                Button("Mirror: \(cameraControl.mirrorOutput ? "ON" : "OFF")") {
                    cameraControl.toggleMirrorOutput()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
                
                Spacer()
            }
            .padding(.horizontal)
            
            VStack {
                Text("Zoom: \(String(format: "%.1f", cameraControl.zoomFactor))x")
                    .foregroundColor(.white)
                
                Slider(
                    value: Binding(
                        get: { Float(cameraControl.zoomFactor) },
                        set: { cameraControl.zoomFactor = Float(CGFloat($0)) }
                    ),
                    in: 1...10.0,
                    step: 0.5
                )
                .accentColor(.white)
            }
            .padding()
            .background(Color.black.opacity(0.7))
            .cornerRadius(8)
            .padding(.horizontal)
            
            Button(action: {
                cameraControl.capturePhoto()
            }) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 2)
                            .frame(width: 60, height: 60)
                    )
            }
            .padding(.bottom, 50)
        }
    }
    
    private func flashModeText(_ mode: CameraFlashMode) -> String {
        switch mode {
        case .off: return "OFF"
        case .on: return "ON"
        case .auto: return "AUTO"
        }
    }
    
    private func resolutionText(_ resolution: AVCaptureSession.Preset) -> String {
        switch resolution {
        case .hd1920x1080: return "1080p"
        case .hd1280x720: return "720p"
        case .vga640x480: return "VGA"
        case .high: return "HIGH"
        default: return "CUSTOM"
        }
    }
}
