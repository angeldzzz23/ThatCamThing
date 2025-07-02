//
//  that.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/1/25.
//


import AVKit

/// A protocol that defines methods for configuring various camera settings.

protocol CameraConfigurationManaging {
    
    /// Updates the camera to use the specified position (e.g., front or back).
    /// - Parameter position: The desired camera position.
    func updateCameraPosition(_ position: CameraPosition)
    
    /// Sets the capture session's resolution preset.
    /// - Parameter resolution: The resolution preset to apply (e.g., .hd1920x1080).
    func updateResolution(_ resolution: AVCaptureSession.Preset)
    
    /// Adjusts the camera's zoom factor.
    /// - Parameter zoom: The zoom level to apply. Typically ranges from 1.0 (no zoom) upward.
    func updateZoomFactor(_ zoom: CGFloat)
    
    /// Sets the flash mode for photo or video capture.
    /// - Parameter flashMode: The desired flash mode (e.g., on, off, auto).
    func updateFlashMode(_ flashMode: CameraFlashMode)
    
    /// Toggles whether the output should be mirrored (commonly used for front camera previews).
    /// - Parameter mirror: A Boolean indicating whether to mirror the output.
    func updateMirrorOutput(_ mirror: Bool)
    
    /// Configures the camera's frame rate for video capture.
    /// - Parameter frameRate: The desired frame rate (e.g., 30 for 30 FPS).
    func updateFrameRate(_ frameRate: Int32)
}
