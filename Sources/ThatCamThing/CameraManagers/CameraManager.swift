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
                // TODO: add check here fir resolution
                print("setting resolution by checking if it is supported")
                if self.session.canSetSessionPreset(self.attributes.resolution) {
                    print("desired resolution is supported ")
                    self.session.sessionPreset = self.attributes.resolution
                } else {
                    session.sessionPreset = .high
                    print("Desired resolution not supported — using .high instead.")
                }
                
                let position: AVCaptureDevice.Position = self.attributes.cameraPosition == .back ? .back : .front
                let deviceType = self.attributes.lensType.deviceType
                
                guard let device = AVCaptureDevice.default(deviceType, for: .video, position: position) else {
                    if self.attributes.lensType == .ultraWide {
                        print("Ultra wide camera not available, falling back to wide angle")
                        DispatchQueue.main.async {
                            self.attributes.lensType = .wide
                        }
                        guard let fallbackDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
                            DispatchQueue.main.async {
                                self.cameraErrors = .cannotSetupInput
                            }
                            return
                        }
                        try self.setupWithDevice(fallbackDevice)
                        return
                    } else {
                        DispatchQueue.main.async {
                            self.cameraErrors = .cannotSetupInput
                        }
                        return
                    }
                }
                
                try self.setupWithDevice(device)
                
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
            
            try self.configureFrameRate(device: device, frameRate: self.attributes.frameRate)

            let isUltraWideAvailable = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: device.position) != nil
            
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
            
            guard let newDevice = AVCaptureDevice.default(deviceType, for: .video, position: position) else {
                if self.attributes.lensType == .ultraWide {
                    print("Ultra wide camera not available for \(position == .back ? "back" : "front") camera, using wide angle")
                    guard let fallbackDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
                        return
                    }
                    
                    do {
                        let newInput = try AVCaptureDeviceInput(device: fallbackDevice)
                        if self.session.canAddInput(newInput) {
                            self.session.addInput(newInput)
                            self.currentInput = newInput
                            if position == .front {
                                DispatchQueue.main.async {
                                    self.attributes.lensType = .wide
                                }
                            }
                        }
                    } catch {
                        print("Error switching camera: \(error.localizedDescription)")
                    }
                    return
                }
                return
            }
            
            do {
                let newInput = try AVCaptureDeviceInput(device: newDevice)
                
                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                    self.currentInput = newInput
                }
            } catch {
                print("Error switching camera: \(error.localizedDescription)")
            }
        }
    }
    
    public func switchLensType() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            defer { self.session.commitConfiguration() }
            
            if let currentInput = self.currentInput {
                self.session.removeInput(currentInput)
            }
            
            let newLensType = self.attributes.lensType == .wide ? CameraLensType.ultraWide : .wide
            DispatchQueue.main.async {
                self.attributes.lensType = newLensType
            }
            
            let position: AVCaptureDevice.Position = self.attributes.cameraPosition == .back ? .back : .front
            let deviceType = newLensType.deviceType
            
            guard let newDevice = AVCaptureDevice.default(deviceType, for: .video, position: position) else {
                print("\(newLensType.displayName) camera not available, reverting to previous lens")
                let revertedLensType = newLensType == .wide ? CameraLensType.ultraWide : .wide
                DispatchQueue.main.async {
                    self.attributes.lensType = revertedLensType
                }
                
                let fallbackDeviceType = revertedLensType.deviceType
                guard let fallbackDevice = AVCaptureDevice.default(fallbackDeviceType, for: .video, position: position) else {
                    return
                }
                
                do {
                    let newInput = try AVCaptureDeviceInput(device: fallbackDevice)
                    if self.session.canAddInput(newInput) {
                        self.session.addInput(newInput)
                        self.currentInput = newInput
                    }
                } catch {
                    print("Error reverting camera: \(error.localizedDescription)")
                }
                return
            }
            
            do {
                let newInput = try AVCaptureDeviceInput(device: newDevice)
                
                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                    self.currentInput = newInput
                    print("Switched to \(newLensType.displayName) camera")
                }
            } catch {
                print("Error switching lens: \(error.localizedDescription)")
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
}

// MARK: - Capture Operations

extension CameraManager {
    
    public func takePicture() {
        guard session.isRunning else {
            print("Attempted to take picture while session is not running.")
            return
        }
        
        guard let connection = output.connection(with: .video), connection.isActive else {
            print("No active video connection — skipping photo capture to avoid crash.")
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
    
    // this allows to rotate the different flash settings
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
    
    //
    public func switchFlash(to mode: CameraFlashMode) {
        attributes.flashMode = mode
    }
    
    // this toggles flash between on and off
    public func toggleFlash() {
        if attributes.flashMode == .on {
            attributes.flashMode = .off
        } else {
            attributes.flashMode = .on
        }
    }
    
    public func setZoom(_ factor: CGFloat) {
        sessionQueue.async { [weak self] in
            guard let self = self, let device = self.currentInput?.device else { return }
            
            do {
                try device.lockForConfiguration()
                let clampedFactor = min(max(factor, 1.0), device.activeFormat.videoMaxZoomFactor)
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

// MARK: - Utilities

extension CameraManager {
    
    public func isUltraWideAvailable() -> Bool {
        let position: AVCaptureDevice.Position = attributes.cameraPosition == .back ? .back : .front
        return AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: position) != nil
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
