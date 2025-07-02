//
//  File.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/1/25.
//

import Foundation
import AVKit
import SwiftUI
import Photos


struct CameraControlsView: View {
    let manager: CameraManager
    
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 40) {
                // Flash toggle
                Button(action: { toggleFlash() }) {
                    Image(systemName: flashIconName)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                // Capture button
                Button(action: { manager.capturePhoto() }) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 2)
                                .frame(width: 60, height: 60)
                        )
                }
                
                // Camera switch
                Button(action: { toggleCamera() }) {
                    Image(systemName: "camera.rotate")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(.bottom, 50)
        }
    }
    
    private var flashIconName: String {
        switch manager.attributes.flashMode {
        case .off: return "bolt.slash"
        case .on: return "bolt"
        case .auto: return "bolt.badge.a"
        }
    }
    
    private func toggleFlash() {
        let newMode: CameraFlashMode = switch manager.attributes.flashMode {
        case .off: .on
        case .on: .auto
        case .auto: .off
        }
        manager.updateFlashMode(newMode)
    }
    
    private func toggleCamera() {
        let newPosition: CameraPosition = manager.attributes.cameraPosition == .back ? .front : .back
        manager.updateCameraPosition(newPosition)
    }
}

