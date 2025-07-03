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

struct CameraMedia {
    let image: UIImage
    let metadata: [String: Any]?
    let timestamp: Date
}

public struct CameraManagerAttributes {
    var capturedMedia: CameraMedia?
    var error: CameraError?
    var outputType = CameraOutputType.photo
    var cameraPosition = CameraPosition.back
    var zoomFactor: CGFloat = 1.0
    var frameRate: Int32 = 60
    var flashMode = CameraFlashMode.off
    var resolution = AVCaptureSession.Preset.hd1920x1080
    var mirrorOutput = false
}

// MARK: - Camera Manager

public class CameraManager: NSObject, ObservableObject, @unchecked Sendable {
    public var session = AVCaptureSession()
    public var alert = false
    public var output = AVCapturePhotoOutput()
    public var preview: AVCaptureVideoPreviewLayer!
    public var showAlert = false
    
    @Published public var attributes = CameraManagerAttributes()
    
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
        do {
            self.session.beginConfiguration()
            
            self.session.sessionPreset = attributes.resolution
            
            // Get camera device based on attributes
            let position: AVCaptureDevice.Position = attributes.cameraPosition == .back ? .back : .front
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
                attributes.error = .cannotSetupInput
                return
            }
            
            // Create input
            let input = try AVCaptureDeviceInput(device: device)
            
            // Check if we can add input and output
            if self.session.canAddInput(input) && self.session.canAddOutput(self.output) {
                self.session.addInput(input)
                self.session.addOutput(self.output)
                self.currentInput = input
                
                // Enable high resolution capture on the output
                if self.output.isHighResolutionCaptureEnabled != true {
                    self.output.isHighResolutionCaptureEnabled = true
                }
            } else {
                attributes.error = .cannotSetupOutput
            }
            
            self.session.commitConfiguration()
            
        } catch {
            print("Error setting up camera: \(error.localizedDescription)")
            attributes.error = .cannotSetupInput
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
        
        // Check if high resolution is supported before setting
        if output.isHighResolutionCaptureEnabled {
            settings.isHighResolutionPhotoEnabled = true
        }
        
        output.capturePhoto(with: settings, delegate: self)
    }
    
    public func switchCamera() {
        session.beginConfiguration()
        
        // Remove current input
        if let currentInput = currentInput {
            session.removeInput(currentInput)
        }
        
        attributes.cameraPosition = attributes.cameraPosition == .back ? .front : .back
        let position: AVCaptureDevice.Position = attributes.cameraPosition == .back ? .back : .front
        
        // Get new device
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            session.commitConfiguration()
            return
        }
        
        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                currentInput = newInput
            }
        } catch {
            print("Error switching camera: \(error.localizedDescription)")
        }
        
        session.commitConfiguration()
    }
    
    public nonisolated func stopCamera() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if self?.session.isRunning == true {
                self?.session.stopRunning()
            }
        }
    }
    
    public func startCamera() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
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
        guard let device = currentInput?.device else { return }
        
        do {
            try device.lockForConfiguration()
            let clampedFactor = min(max(factor, 1.0), device.activeFormat.videoMaxZoomFactor)
            device.videoZoomFactor = clampedFactor
            attributes.zoomFactor = clampedFactor
            device.unlockForConfiguration()
        } catch {
            print("Error setting zoom: \(error.localizedDescription)")
        }
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    
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
