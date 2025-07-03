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

// MARK: - Core Models and Enums

public enum CameraError: Error {
    case cameraPermissionsNotGranted
    case cannotSetupInput, cannotSetupOutput
}

public enum CameraOutputType: CaseIterable {
    case photo
}

public enum CameraPosition: CaseIterable {
    case back
    case front
}

public enum CameraFlashMode: CaseIterable {
    case off
    case on
    case auto
}

public enum CameraHDRMode: CaseIterable {
    case off
    case on
    case auto
}

public enum CameraLensType: CaseIterable {
    case wide
    case ultraWide
    
    public var deviceType: AVCaptureDevice.DeviceType {
        switch self {
        case .wide:
            return .builtInWideAngleCamera
        case .ultraWide:
            return .builtInUltraWideCamera
        }
    }
    
    public var displayName: String {
        switch self {
        case .wide:
            return "Wide"
        case .ultraWide:
            return "Ultra Wide"
        }
    }
}

public struct CameraMedia {
    public let image: UIImage
    public let metadata: [String: Any]?
    public let timestamp: Date
}

public struct CameraManagerAttributes {
    public var capturedMedia: CameraMedia?
    public var error: CameraError?
    public var outputType = CameraOutputType.photo
    public var cameraPosition = CameraPosition.back
    public var zoomFactor: CGFloat = 1.0
    public var frameRate: Int32 = 30
    public var flashMode = CameraFlashMode.off
    public var resolution = AVCaptureSession.Preset.hd1920x1080
    public var mirrorOutput = false
    public var lensType = CameraLensType.wide
}

// MARK: - Camera Manager

public class CameraManager: NSObject, ObservableObject, @unchecked Sendable {
    public var session = AVCaptureSession()
    public var alert = false
    public var output = AVCapturePhotoOutput()
    public var preview: AVCaptureVideoPreviewLayer!
    public var showAlert = false
    
    @Published public var attributes = CameraManagerAttributes()
    
    private let sessionQueue = DispatchQueue(label: "com.thatcamthing.sessionQueue")
    private var currentInput: AVCaptureDeviceInput?
    
    public var flashMode: CameraFlashMode {
        get { attributes.flashMode }
        set { attributes.flashMode = newValue }
    }
    
    private var isFrontCamera: Bool {
        attributes.cameraPosition == .front
    }
    
    public override init() {
        super.init()
    }
    
    @MainActor
    public func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { status in
                if status {
                    self.setUp()
                } else {
                    DispatchQueue.main.async {
                        self.attributes.error = .cameraPermissionsNotGranted
                    }
                }
            }
        case .denied:
            DispatchQueue.main.async {
                self.showAlert = true
                self.attributes.error = .cameraPermissionsNotGranted
            }
            return
        default:
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
                let deviceType = self.attributes.lensType.deviceType
                
                guard let device = AVCaptureDevice.default(deviceType, for: .video, position: position) else {
                    if self.attributes.lensType == .ultraWide {
                        print("⚠️ Ultra wide camera not available, falling back to wide angle")
                        self.attributes.lensType = .wide
                        guard let fallbackDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
                            self.attributes.error = .cannotSetupInput
                            return
                        }
                        try self.setupWithDevice(fallbackDevice)
                        return
                    } else {
                        self.attributes.error = .cannotSetupInput
                        return
                    }
                }
                
                try self.setupWithDevice(device)
                
            } catch {
                print("Error setting up camera: \(error.localizedDescription)")
                self.attributes.error = .cannotSetupInput
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
            
            if self.output.isHighResolutionCaptureEnabled != true {
                self.output.isHighResolutionCaptureEnabled = true
            }
        } else {
            attributes.error = .cannotSetupOutput
        }
    }
    
    public func takePicture() {
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
    
    public func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            defer { self.session.commitConfiguration() }
            
            if let currentInput = self.currentInput {
                self.session.removeInput(currentInput)
            }
            
            self.attributes.cameraPosition = self.attributes.cameraPosition == .back ? .front : .back
            let position: AVCaptureDevice.Position = self.attributes.cameraPosition == .back ? .back : .front
            let deviceType = self.attributes.lensType.deviceType
            
            guard let newDevice = AVCaptureDevice.default(deviceType, for: .video, position: position) else {
                if self.attributes.lensType == .ultraWide {
                    print("⚠️ Ultra wide camera not available for \(position == .back ? "back" : "front") camera, using wide angle")
                    guard let fallbackDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
                        return
                    }
                    
                    do {
                        let newInput = try AVCaptureDeviceInput(device: fallbackDevice)
                        if self.session.canAddInput(newInput) {
                            self.session.addInput(newInput)
                            self.currentInput = newInput
                            if position == .front {
                                self.attributes.lensType = .wide
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
            
            self.attributes.lensType = self.attributes.lensType == .wide ? .ultraWide : .wide
            
            let position: AVCaptureDevice.Position = self.attributes.cameraPosition == .back ? .back : .front
            let deviceType = self.attributes.lensType.deviceType
            
            guard let newDevice = AVCaptureDevice.default(deviceType, for: .video, position: position) else {
                print("⚠️ \(self.attributes.lensType.displayName) camera not available, reverting to previous lens")
                self.attributes.lensType = self.attributes.lensType == .wide ? .ultraWide : .wide
                
                let fallbackDeviceType = self.attributes.lensType.deviceType
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
                    print("✅ Switched to \(self.attributes.lensType.displayName) camera")
                }
            } catch {
                print("Error switching lens: \(error.localizedDescription)")
            }
        }
    }
    
    public func isUltraWideAvailable() -> Bool {
        let position: AVCaptureDevice.Position = attributes.cameraPosition == .back ? .back : .front
        return AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: position) != nil
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
    
    
    public func setZoom(_ factor: CGFloat) {
        sessionQueue.async { [weak self] in
            guard let self = self, let device = self.currentInput?.device else { return }
            
            do {
                try device.lockForConfiguration()
                let clampedFactor = min(max(factor, 1.0), device.activeFormat.videoMaxZoomFactor)
                device.videoZoomFactor = clampedFactor
                self.attributes.zoomFactor = clampedFactor
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
                self.attributes.frameRate = frameRate
            } catch {
                print("Error setting frame rate: \(error.localizedDescription)")
            }
        }
    }
    
    private func configureFrameRate(device: AVCaptureDevice, frameRate: Int32) throws {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        
        if let range = device.activeFormat.videoSupportedFrameRateRanges.first(where: { $0.maxFrameRate >= Double(frameRate) }) {
            device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
            device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
            print("✅ Frame rate set to \(frameRate) fps.")
        } else {
            print("❌ Desired frame rate \(frameRate) is not supported by the active format.")
        }
    }
    
    private func handleFrameRateFallback(device: AVCaptureDevice, targetFrameRate: Int32, formats: [AVCaptureDevice.Format]) {
        print("📋 Available frame rates:")
        var allRanges: [AVFrameRateRange] = []
        
        for format in formats {
            for range in format.videoSupportedFrameRateRanges {
                allRanges.append(range)
                let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                print("   \(dimensions.width)x\(dimensions.height): \(range.minFrameRate)-\(range.maxFrameRate) fps")
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
        
        print("🔄 Using closest supported frame rate: \(closestFrameRate) fps")
        attributes.frameRate = Int32(closestFrameRate)
    }
    
    private func saveImageToPhotoLibrary(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            print("Photo saved successfully")
                        } else if let error = error {
                            print("Error saving photo: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
}

extension CameraManager: @preconcurrency AVCapturePhotoCaptureDelegate {
    
    @MainActor
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
        attributes.capturedMedia = cameraMedia
        
        saveImageToPhotoLibrary(image)
    }
}
