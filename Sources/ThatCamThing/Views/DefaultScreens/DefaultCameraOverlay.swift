//
//  File.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/4/25.
//

import Foundation
import SwiftUI
import AVKit

/// A comprehensive camera overlay that provides a full-featured interface for camera controls.
public struct DefaultCameraOverlay:  CameraOverlay {

    // MARK: properties
    
    /// The camera manager that this overlay controls
    @ObservedObject var camera: CameraManager
    
    // Zoom presets like iOS Camera app
    private let zoomPresets: [CGFloat] = [0.5, 1.0, 2.0]

    // MARK: initializers

    /// Initializes the camera overlay with a camera manager
    /// - Parameter camera: The CameraManager instance to control
    public init(camera: CameraManager) {
        self.camera = camera
    }

    public var body: some View {

        ZStack {

            Color.clear
                .contentShape(Rectangle())

            VStack(spacing: 0) {

                Spacer()


                // Main controls
                mainControlsContainer


                Spacer().frame(height: 30)

                // Dynamic zoom display
                dynamicZoomDisplay

                Spacer().frame(height: 50)

            }
            .padding(.horizontal, 20)

        }
    }

    /// Dynamic zoom display that shows current zoom level
    private var dynamicZoomDisplay: some View {
        VStack(spacing: 12) {
            // Always show zoom buttons (like Apple's camera app)
            iosZoomButtons


        }
    }

    /// iOS-style zoom buttons (0.5x, 1x, 2x)
    private var iosZoomButtons: some View {
        HStack(spacing: 8) {
            ForEach(zoomPresets, id: \.self) { preset in
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        handleZoomPreset(preset)
                    }

                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }) {
                    Text(dynamicZoomDisplayText(for: preset))
                        .font(.system(.body, design: .rounded, weight: isCurrentZoomPreset(preset) ? .bold : .medium))
                        .foregroundColor(isCurrentZoomPreset(preset) ? .black : .white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(isCurrentZoomPreset(preset) ? Color.white : Color.white.opacity(0.2))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                        .scaleEffect(isCurrentZoomPreset(preset) ? 1.05 : 1.0)
                }
                .disabled(!isZoomPresetAvailable(preset))
                .opacity(isZoomPresetAvailable(preset) ? 1.0 : 0.4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.black.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }

    /// Main controls container
    private var mainControlsContainer: some View {
        HStack(spacing: 40) {
            flashButton
            captureButton
            rotateCamera
        }
    }

    /// Flash control button that cycles through off, on, and auto modes
    private var flashButton: some View {
        Button(action: {
            camera.switchFlash()

            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            Image(systemName: camera.flashMode == .off ? "bolt.slash" : (camera.flashMode == .on ? "bolt" : "bolt.badge.a"))
                .font(.system(.title2, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .scaleEffect(0.9)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: camera.flashMode)
    }

    /// Camera rotation button that switches between front and back cameras
    private var rotateCamera: some View {
        Button(action: {
            camera.switchCamera()

            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }) {
            Image(systemName: "camera.rotate")
                .font(.system(.title2, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .scaleEffect(0.9)
    }

    // MARK: Capture Button

    /// Main capture button for taking photos
    private var captureButton: some View {
        Button(action: {
            camera.takePicture()

            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        }) {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 6)
                    .frame(width: 90, height: 90)

                Circle()
                    .fill(camera.attributes.isPaused ? Color.white.opacity(0.5) : Color.white)
                    .frame(width: 75, height: 75)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.1), lineWidth: 2)
                    )
            }
        }
        .disabled(camera.attributes.isPaused)
        .scaleEffect(camera.attributes.isPaused ? 0.9 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: camera.attributes.isPaused)
    }


    // MARK: Helper Methods

    /// Handles continuous zoom changes from gestures
    private func handleZoomChange(_ targetZoom: CGFloat) {
        let newZoom = max(0.5, min(10.0, targetZoom))

        if newZoom < 1.0 {
            if camera.isUltraWideAvailable() {
                if camera.attributes.lensType != .ultraWide {
                    camera.switchLensType()
                }
                // Map the effective zoom (0.5x-1x) to the ultra-wide lens's own zoom factor (1x-2x)
                let ultraWideZoomFactor = newZoom * 2.0
                camera.setZoom(ultraWideZoomFactor)

            } else {
                // No ultra-wide lens available, so clamp at 1.0x zoom
                camera.setZoom(1.0)
            }
        } else { // newZoom is 1.0 or greater
            if camera.attributes.lensType == .ultraWide {
                camera.switchLensType()
            }
            camera.setZoom(newZoom)
        }
    }

    /// Gets the current zoom display text with proper formatting
    private func getCurrentZoomDisplayText() -> String {
        let currentZoom = camera.attributes.zoomFactor
        let isUltraWide = camera.attributes.lensType == .ultraWide

        if isUltraWide {
            // For ultra-wide, the effective zoom is half of the lens's zoom factor
            let effectiveZoom = camera.attributes.zoomFactor / 2.0
            return String(format: "%.1f×", effectiveZoom)
        } else {
            // Show one decimal place for values between whole numbers
            if currentZoom.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(currentZoom))×"
            } else {
                return String(format: "%.1f×", currentZoom)
            }
        }
    }

    /// Returns dynamic display text for zoom preset buttons based on current zoom
    private func dynamicZoomDisplayText(for preset: CGFloat) -> String {
        let currentZoom = camera.attributes.zoomFactor
        let isUltraWide = camera.attributes.lensType == .ultraWide
        let effectiveZoom = isUltraWide ? currentZoom / 2.0 : currentZoom

        if preset == 0.5 {
            // Ultra-wide is always 0.5×, but show current zoom if active
            if isUltraWide {
                return String(format: "%.1f×", effectiveZoom)
            }
            return "0.5×"
        } else if preset == 1.0 {
            // Show current zoom if it's between 1.0 and 1.9
            if !isUltraWide && effectiveZoom >= 1.0 && effectiveZoom < 2.0 {
                if effectiveZoom.truncatingRemainder(dividingBy: 1) == 0 {
                    return "\(Int(effectiveZoom))×"
                } else {
                    return String(format: "%.1f×", effectiveZoom)
                }
            }
            return "1×"
        } else if preset == 2.0 {
            // Show current zoom if it's 2.0 or higher
            if !isUltraWide && effectiveZoom >= 2.0 {
                if effectiveZoom.truncatingRemainder(dividingBy: 1) == 0 {
                    return "\(Int(effectiveZoom))×"
                } else {
                    return String(format: "%.1f×", effectiveZoom)
                }
            }
            return "2×"
        }
        return "\(preset)×"
    }

    /// Checks if current zoom is at a preset value
    private func isCurrentZoomPreset(_ preset: CGFloat) -> Bool {
        let currentZoom = camera.attributes.zoomFactor
        let isUltraWide = camera.attributes.lensType == .ultraWide
        let effectiveZoom = isUltraWide ? currentZoom / 2.0 : currentZoom

        if preset == 0.5 {
            // Ultra-wide lens is active
            return isUltraWide
        } else if preset == 1.0 {
            // Regular lens with zoom between 1.0 and 1.9
            return !isUltraWide && effectiveZoom >= 1.0 && effectiveZoom < 2.0
        } else if preset == 2.0 {
            // Regular lens with zoom 2.0 and above
            return !isUltraWide && effectiveZoom >= 2.0
        }
        return false
    }

    /// Checks if a zoom preset is available on the current device
    private func isZoomPresetAvailable(_ preset: CGFloat) -> Bool {
        if preset == 0.5 {
            return camera.isUltraWideAvailable()
        }
        return true // 1x and 2x are always available
    }

    private func handleZoomPreset(_ preset: CGFloat) {
        if preset == 0.5 {
            // Switch to ultra-wide lens if available
            if camera.isUltraWideAvailable() && camera.attributes.lensType != .ultraWide {
                camera.switchLensType()
            }
            camera.setZoom(1.0) // Ultra-wide at 1x is effectively 0.5x
        } else {
            // Switch to regular lens if on ultra-wide
            if camera.attributes.lensType == .ultraWide {
                camera.switchLensType()
            }
            camera.setZoom(preset)
        }
    }

    private func zoomDisplayText(for preset: CGFloat) -> String {
        if preset == 0.5 {
            return "0.5×"
        } else if preset == 1.0 {
            return "1×"
        } else if preset == 2.0 {
            return "2×"
        }
        return "\(preset)×"
    }
}
