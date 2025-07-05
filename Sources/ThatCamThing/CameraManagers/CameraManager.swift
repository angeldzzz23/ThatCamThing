//
//  File.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/2/25.
//

import Foundation
import SwiftUI
import PhotosUI
import AVFoundation
import AVKit

// MARK: - Camera Manager Core

public class CameraManager: NSObject, ObservableObject, @unchecked Sendable {
    
    // MARK: - Public Properties
    public var session = AVCaptureSession()
    public var output = AVCapturePhotoOutput()
    public var preview: AVCaptureVideoPreviewLayer
    
    @Published public var cameraErrors: CameraError? = nil
    @Published public var containsErrors = false
    @Published public var attributes = CameraManagerAttributes()
    @Published public var capturedMedia: CameraMedia? = nil
    
    // MARK: - Private Properties
    private let sessionQueue = DispatchQueue(label: Constants.dispatchQueueName)
    private var currentInput: AVCaptureDeviceInput?
    
    // MARK: - Initialization
    public override init() {
        self.preview = AVCaptureVideoPreviewLayer()
        super.init()
    }
}

// MARK: - Setup & Permissions

extension CameraManager {
    
    public func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { status in
                DispatchQueue.main.async {
                    if status {
                        self.setUp()
                    } else {
                        self.containsErrors = true
                        self.cameraErrors = .cameraPermissionsNotGranted
                    }
                }
            }
        case .denied, .restricted:
            print("Denied")
            self.containsErrors = true
            self.cameraErrors = .cameraPermissionsNotGranted
            return
        default:
            self.containsErrors = true
            self.cameraErrors = .cameraPermissionsNotGranted
            return
        }
    }
    
    func setUp() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            defer { self.session.commitConfiguration() }
            
            do {
                self.session.sessionPreset = self.attributes.resolution
                
                let position: AVCaptureDevice.Position = self.attributes.cameraPosition == .back ? .back : .front
                
                var device: AVCaptureDevice?
                if position == .back {
                    if let dualWideCamera = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                        device = dualWideCamera
                        print("Using Dual Wide Camera for seamless zoom.")
                    } else if let dualCamera = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                        device = dualCamera
                        print("Using Dual Camera.")
                    }
                }
                
                // Fallback for front camera or if no virtual device is found.
                if device == nil {
                    device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
                }
                
                guard let finalDevice = device else {
                    DispatchQueue.main.async {
                        self.cameraErrors = .cannotSetupInput
                    }
                    return
                }
                
                try self.setupWithDevice(finalDevice)
                
            } catch {
                print("Error setting up camera: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.cameraErrors = .cannotSetupInput
                }
            }
        }
    }
    
    private func setupWithDevice(_ device: AVCaptureDevice) throws {
        do {
            try configureFrameRate(device: device, frameRate: attributes.frameRate)
        } catch {
            print("Error configuring frame rate: \(error.localizedDescription)")
        }
        
        let input = try AVCaptureDeviceInput(device: device)
        
        if self.session.canAddInput(input) && self.session.canAddOutput(self.output) {
            self.session.addInput(input)
            self.session.addOutput(self.output)
            self.currentInput = input
            
            let isUltraWideAvailable = device.minAvailableVideoZoomFactor < 1.0
            DispatchQueue.main.async {
                self.attributes.isUltraWideLensAvailable = isUltraWideAvailable
            }
            
            if self.output.isHighResolutionCaptureEnabled != true {
                self.output.isHighResolutionCaptureEnabled = true
            }
        } else {
            DispatchQueue.main.async {
                self.cameraErrors = .cannotSetupOutput
            }
        }
    }
}

// MARK: - Camera Controls

extension CameraManager {
    
    public func switchCamera() {
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            defer { self.session.commitConfiguration() }
            
            if let currentInput = self.currentInput {
                self.session.removeInput(currentInput)
            }
            
            let newPosition = self.attributes.cameraPosition == .back ? CameraPosition.front : .back
            DispatchQueue.main.async {
                self.attributes.cameraPosition = newPosition
            }
            let position: AVCaptureDevice.Position = newPosition == .back ? .back : .front
            let deviceType = self.attributes.lensType.deviceType
            
            var newDevice: AVCaptureDevice?
            if position == .back {
                if let dualWideCamera = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                    newDevice = dualWideCamera
                } else if let dualCamera = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                    newDevice = dualCamera
                }
            }
            
            if newDevice == nil {
                newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
            }
            
            guard let finalDevice = newDevice else {
                print("Error: Could not find a suitable device for the new position.")
                return
            }
            
            do {
                let newInput = try AVCaptureDeviceInput(device: finalDevice)
                
                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                    self.currentInput = newInput
                    
                    let isUltraWideAvailable = finalDevice.minAvailableVideoZoomFactor < 1.0
                    let zoomFactor = finalDevice.videoZoomFactor
                    DispatchQueue.main.async {
                        self.attributes.isUltraWideLensAvailable = isUltraWideAvailable
                        self.attributes.zoomFactor = zoomFactor
                    }
                }
            } catch {
                print("Error switching camera: \(error.localizedDescription)")
            }
        }
    }
    
    public func switchLensType() {
        sessionQueue.async { [weak self] in
            guard let self = self, let device = self.currentInput?.device else { return }

            let targetZoom: CGFloat
            
            // If we are zoomed in (or at 1x), switch to ultra-wide. Otherwise, switch to 1x.
            if self.attributes.zoomFactor >= 1.0 {
                targetZoom = device.minAvailableVideoZoomFactor
            } else {
                targetZoom = 1.0
            }
            
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = targetZoom
                device.unlockForConfiguration()
                
                DispatchQueue.main.async {
                    self.attributes.zoomFactor = targetZoom
                    self.attributes.lensType = targetZoom < 1.0 ? .ultraWide : .wide
                }
            } catch {
                print("Could not change zoom: \(error)")
            }
        }
    }
    
    public func pauseCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.attributes.isPaused = true
                    print("Camera session paused.")
                }
            }
        }
    }
    
    public func resumeCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.attributes.isPaused = false
                    print("Camera session resumed.")
                }
            }
        }
    }
    
    public nonisolated func stopCamera() {
        sessionQueue.async { [weak self] in
            if self?.session.isRunning == true {
                self?.session.stopRunning()
            }
        }
    }
    
    public func startCamera() {
        sessionQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    public func setZoom(_ factor: CGFloat) {
        sessionQueue.async { [weak self] in
            guard let self = self, let device = self.currentInput?.device else { return }
            
            do {
                try device.lockForConfiguration()
                let clampedFactor = min(max(factor, device.minAvailableVideoZoomFactor), device.maxAvailableVideoZoomFactor)
                device.videoZoomFactor = clampedFactor
                
                DispatchQueue.main.async {
                    self.attributes.zoomFactor = clampedFactor
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Error setting zoom: \(error.localizedDescription)")
            }
        }
    }
    
    public func setFrameRate(_ frameRate: Int32) {
        sessionQueue.async { [weak self] in
            guard let self = self, let device = self.currentInput?.device else { return }
            
            do {
                try self.configureFrameRate(device: device, frameRate: frameRate)
                DispatchQueue.main.async {
                    self.attributes.frameRate = device.activeVideoMinFrameDuration.timescale
                }
            } catch {
                print("Error setting frame rate: \(error.localizedDescription)")
            }
        }
    }
    
    private func configureFrameRate(device: AVCaptureDevice, frameRate: Int32) throws {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        
        print("Attempting to set frame rate to \(frameRate) fps...")
        
        var bestFormat: AVCaptureDevice.Format?
        
        let currentDimensions = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
        
        if let format = device.formats.first(where: { format in
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            return dimensions.width == currentDimensions.width &&
            dimensions.height == currentDimensions.height &&
            format.videoSupportedFrameRateRanges.contains(where: { $0.maxFrameRate >= Double(frameRate) })
        }) {
            bestFormat = format
        }
        else if let format = device.formats
            .sorted(by: { CMVideoFormatDescriptionGetDimensions($0.formatDescription).width > CMVideoFormatDescriptionGetDimensions($1.formatDescription).width })
            .first(where: { $0.videoSupportedFrameRateRanges.contains(where: { $0.maxFrameRate >= Double(frameRate) })
            }) {
            bestFormat = format
        }
        
        if let format = bestFormat {
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            print("Selected format: \(dimensions.width)x\(dimensions.height) for \(frameRate) fps")
            
            device.activeFormat = format
            device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
            device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
            
            print("Frame rate successfully set.")
        } else {
            print("No format found that supports \(frameRate) fps. The device may not support this frame rate. Current format will be kept.")
        }
    }
    
    private func handleFrameRateFallback(device: AVCaptureDevice, targetFrameRate: Int32, formats: [AVCaptureDevice.Format]) {
        print("Available frame rates:")
        
        var allRanges: [AVFrameRateRange] = []
        
        for format in formats {
            for range in format.videoSupportedFrameRateRanges {
                allRanges.append(range)
                let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                print("  \(dimensions.width)x\(dimensions.height): \(range.minFrameRate)-\(range.maxFrameRate) fps")
            }
        }
        
        var closestFrameRate: Double = 30.0
        var minDifference = Double.infinity
        
        for range in allRanges {
            let maxRate = range.maxFrameRate
            let difference = abs(maxRate - Double(targetFrameRate))
            if difference < minDifference {
                minDifference = difference
                closestFrameRate = maxRate
            }
        }
        
        print("Using closest supported frame rate: \(closestFrameRate) fps")
        DispatchQueue.main.async {
            self.attributes.frameRate = Int32(closestFrameRate)
        }
    }
}

// MARK: - Capture Operations

extension CameraManager {
    
    public func takePicture() {
        guard session.isRunning else {
            print("Attempted to take picture while session is not running.")
            return
        }
        
        let settings = AVCapturePhotoSettings()
        
        if currentInput?.device.hasFlash == true {
            switch attributes.flashMode {
            case .off:
                settings.flashMode = .off
            case .on:
                settings.flashMode = .on
            case .auto:
                settings.flashMode = .auto
            }
        }
        
        if output.isHighResolutionCaptureEnabled {
            settings.isHighResolutionPhotoEnabled = true
        }
        
        output.capturePhoto(with: settings, delegate: self)
    }
}

// MARK: - Configuration

extension CameraManager {
    
    public func switchFlash() {
        switch attributes.flashMode {
        case .off:
            attributes.flashMode = .on
        case .on:
            attributes.flashMode = .auto
        case .auto:
            attributes.flashMode = .off
        }
    }
    
}

// MARK: - Utilities

extension CameraManager {
    
    public func isUltraWideAvailable() -> Bool {
        return attributes.isUltraWideLensAvailable
    }
}

// MARK: - Photo Capture Delegate

extension CameraManager: @preconcurrency AVCapturePhotoCaptureDelegate {
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("Error getting image data")
            return
        }
        
        guard let image = UIImage(data: imageData) else {
            print("Error creating UIImage from data")
            return
        }
        
        let metadata = photo.metadata
        let cameraMedia = CameraMedia(
            image: image,
            metadata: metadata,
            timestamp: Date()
        )
        capturedMedia = cameraMedia
    }
}

// MARK: - Computed Properties

extension CameraManager {
    
    public var flashMode: CameraFlashMode {
        get { attributes.flashMode }
        set { attributes.flashMode = newValue }
    }
    
    private var isFrontCamera: Bool {
        attributes.cameraPosition == .front
    }
}
