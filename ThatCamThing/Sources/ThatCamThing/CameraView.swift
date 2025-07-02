//
//  File.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/2/25.
//

import Foundation
import SwiftUI
import PhotosUI


// MARK: - Camera Manager

public class CameraManager: NSObject, ObservableObject, @unchecked Sendable {
  public var session = AVCaptureSession()
  public var alert = false
  public var output = AVCapturePhotoOutput()
  public var preview: AVCaptureVideoPreviewLayer!
  public var showAlert = false
  public var flashMode: AVCaptureDevice.FlashMode = .off
  
  private var currentInput: AVCaptureDeviceInput?
  private var isFrontCamera = false
  
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
              }
          }
      case .denied:
          DispatchQueue.main.async {
              self.showAlert = true
          }
          return
      default:
          return
      }
  }
  
    func setUp() {
      do {
          self.session.beginConfiguration()
          
          // Set session preset for high quality photos
          self.session.sessionPreset = .photo
          
          // Get camera device
          guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
              return
          }
          
          // Create input
          let input = try AVCaptureDeviceInput(device: device)
          
          // Check if we can add input and output
          if self.session.canAddInput(input) && self.session.canAddOutput(self.output) {
              self.session.addInput(input)
              self.session.addOutput(self.output)
              self.currentInput = input
              
              // ADD: Enable high resolution capture on the output
              if self.output.isHighResolutionCaptureEnabled != true {
                  self.output.isHighResolutionCaptureEnabled = true
              }
          }
          
          self.session.commitConfiguration()
          
      } catch {
          print("Error setting up camera: \(error.localizedDescription)")
      }
    }

  
  public func takePicture() {
      let settings = AVCapturePhotoSettings()
      
      // Set flash mode
      if currentInput?.device.hasFlash == true {
          settings.flashMode = flashMode
      }
      
      // Set high quality format
      settings.isHighResolutionPhotoEnabled = true
      
      output.capturePhoto(with: settings, delegate: self)
  }
  
  public func switchCamera() {
      session.beginConfiguration()
      
      // Remove current input
      if let currentInput = currentInput {
          session.removeInput(currentInput)
      }
      
      // Switch camera position
      isFrontCamera.toggle()
      let position: AVCaptureDevice.Position = isFrontCamera ? .front : .back
      
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
      switch flashMode {
      case .off:
          flashMode = .on
      case .on:
          flashMode = .auto
      case .auto:
          flashMode = .off
      @unknown default:
          flashMode = .off
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
      
      saveImageToPhotoLibrary(image)
  }
}


//extension CameraManager:
