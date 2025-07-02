//
//  File.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/1/25.
//

import AVKit
import SwiftUI

public class CameraDeviceManager {
    
    private let session: AVCaptureSession
    private weak var cameraManager: CameraManager?
    
    var videoDeviceInput: AVCaptureDeviceInput?
    
    public init(session: AVCaptureSession, cameraManager: CameraManager) {
        self.session = session
        self.cameraManager = cameraManager
    }
    
    func setupInitialDevice(position: CameraPosition, frameRate: Int32, zoomFactor: CGFloat) -> Bool {
        let avPosition: AVCaptureDevice.Position = position == .back ? .back : .front
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: avPosition) else {
            cameraManager?.showAlert(message: "Could not find camera")
            return false
        }
        
        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput!) {
                session.addInput(videoDeviceInput!)
            }
            
            try configureFrameRate(device: videoDevice, frameRate: frameRate)
            applyZoom(to: videoDevice, zoomFactor: zoomFactor)
            
            return true
        } catch {
            cameraManager?.showAlert(message: "Could not create video device input: \(error.localizedDescription)")
            return false
        }
    }
    
    func switchCamera(to position: CameraPosition) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.beginConfiguration()
            
            if let currentInput = self.videoDeviceInput {
                self.session.removeInput(currentInput)
            }
            
            let avPosition: AVCaptureDevice.Position = position == .back ? .back : .front
            
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: avPosition) else {
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.cameraManager?.showAlert(message: "Could not find \(position == .back ? "back" : "front") camera")
                }
                return
            }
            
            do {
                let newInput = try AVCaptureDeviceInput(device: videoDevice)
                
                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                    self.videoDeviceInput = newInput
                    
                    if let frameRate = self.cameraManager?.attributes.frameRate {
                        try self.configureFrameRate(device: videoDevice, frameRate: frameRate)
                    }
                    
                    if let zoomFactor = self.cameraManager?.attributes.zoomFactor {
                        self.applyZoom(to: videoDevice, zoomFactor: zoomFactor)
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.cameraManager?.showAlert(message: "Could not switch camera: \(error.localizedDescription)")
                }
            }
            
            self.session.commitConfiguration()
        }
    }
    
    func updateZoom(_ zoomFactor: CGFloat) {
        guard let device = videoDeviceInput?.device else { return }
        applyZoom(to: device, zoomFactor: zoomFactor)
    }
    
    func updateFrameRate(_ frameRate: Int32) {
        guard let device = videoDeviceInput?.device else { return }
        
        do {
            try configureFrameRate(device: device, frameRate: frameRate)
        } catch {
            DispatchQueue.main.async {
                self.cameraManager?.showAlert(message: "Could not update frame rate: \(error.localizedDescription)")
            }
        }
    }
    
    private func applyZoom(to device: AVCaptureDevice, zoomFactor: CGFloat) {
        do {
            try device.lockForConfiguration()
            
            let maxZoom = device.activeFormat.videoMaxZoomFactor
            let clampedZoom = min(max(zoomFactor, 1.0), maxZoom)
            device.videoZoomFactor = clampedZoom
            
            if clampedZoom != zoomFactor {
                DispatchQueue.main.async {
                    self.cameraManager?.attributes.zoomFactor = clampedZoom
                }
            }
            
            device.unlockForConfiguration()
        } catch {
            DispatchQueue.main.async {
                self.cameraManager?.showAlert(message: "Could not adjust zoom: \(error.localizedDescription)")
            }
        }
    }
    
    private func configureFrameRate(device: AVCaptureDevice, frameRate: Int32) throws {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        
        let targetFrameRate = frameRate
        let formats = device.formats
        var bestFormat: AVCaptureDevice.Format?
        var bestFrameRateRange: AVFrameRateRange?
        
        // Find the best format that supports the target frame rate
        for format in formats {
            for range in format.videoSupportedFrameRateRanges {
                if range.maxFrameRate >= Double(targetFrameRate) && range.minFrameRate <= Double(targetFrameRate) {
                    if bestFormat == nil ||
                       CMVideoFormatDescriptionGetDimensions(format.formatDescription).width >
                       CMVideoFormatDescriptionGetDimensions(bestFormat!.formatDescription).width {
                        bestFormat = format
                        bestFrameRateRange = range
                    }
                }
            }
        }
        
        if let format = bestFormat,  let _ = bestFrameRateRange {
            device.activeFormat = format
            device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: targetFrameRate)
            device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: targetFrameRate)
        } else {
            // Fallback logic
            handleFrameRateFallback(device: device, targetFrameRate: targetFrameRate, formats: formats)
        }
    }
    
    private func handleFrameRateFallback(device: AVCaptureDevice, targetFrameRate: Int32, formats: [AVCaptureDevice.Format]) {
        for format in formats {
            for range in format.videoSupportedFrameRateRanges {
                if range.maxFrameRate >= 30.0 {
                    device.activeFormat = format
                    let clampedFrameRate = min(Double(targetFrameRate), range.maxFrameRate)
                    let clampedFrameRateInt32 = Int32(clampedFrameRate)
                    device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: clampedFrameRateInt32)
                    device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: clampedFrameRateInt32)
                    
                    if clampedFrameRateInt32 != targetFrameRate {
                        DispatchQueue.main.async {
                            self.cameraManager?.attributes.frameRate = clampedFrameRateInt32
                        }
                    }
                    return
                }
            }
        }
    }
}
