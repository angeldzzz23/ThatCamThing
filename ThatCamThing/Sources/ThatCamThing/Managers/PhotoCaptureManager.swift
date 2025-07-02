//
//  PhotoCaptureManager.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/1/25.
//

import Foundation


import Foundation
import AVKit
import SwiftUI
import Photos

// MARK: - Photo Capture Management

public class PhotoCaptureManager: NSObject {
    private weak var cameraManager: CameraManager?
    var photoOutput: AVCapturePhotoOutput?
    private let imageProcessingQueue = DispatchQueue(label: "com.camera.imageProcessing", qos: .userInitiated)

    
    init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
        super.init()
    }
    
    public  func setupPhotoOutput(session: AVCaptureSession) -> Bool {
        photoOutput = AVCapturePhotoOutput()
        
        guard let photoOutput = photoOutput else { return false }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            return true
        }
        
        return false
    }
    
    public   func capturePhoto(flashMode: CameraFlashMode) {
        guard let photoOutput = photoOutput,
              let cameraManager = cameraManager,
              !cameraManager.isPaused else { return }
        
        let settings = AVCapturePhotoSettings()
        
        switch flashMode {
        case .off:
            settings.flashMode = .off
        case .on:
            settings.flashMode = .on
        case .auto:
            settings.flashMode = .auto
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension PhotoCaptureManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        // Move heavy processing to background thread
        imageProcessingQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Handle error case
            guard error == nil else {
                DispatchQueue.main.async {
                    self.cameraManager?.showAlert(message: "Failed to capture photo: \(error?.localizedDescription ?? "Unknown error")")
                    self.cameraManager?.isCapturing = false
                }
                return
            }
            
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                DispatchQueue.main.async {
                    self.cameraManager?.showAlert(message: "Failed to capture photo")
                    self.cameraManager?.isCapturing = false
                }
                return
            }
            
            // Apply mirroring if needed (this is expensive)
            let finalImage = self.cameraManager?.attributes.mirrorOutput == true ? image.mirrored() : image
            
            let metadata = photo.metadata
            let cameraMedia = CameraMedia(image: finalImage, metadata: metadata, timestamp: Date())
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.cameraManager?.capturedImage = finalImage
                self.cameraManager?.attributes.capturedMedia = cameraMedia
                self.cameraManager?.isCapturing = false // Re-enable capture
                self.cameraManager?.onImageCaptured?(finalImage)
            }
        }
    }
}
