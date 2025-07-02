//
//  CameraSessionManager.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/1/25.
//

import Foundation

public class CameraSessionManager {
    
    private let session: AVCaptureSession
    private weak var cameraManager: CameraManager?
    
    public init(session: AVCaptureSession, cameraManager: CameraManager) {
        self.session = session
        self.cameraManager = cameraManager
    }
    
    public func setupSessionObservers() {
        let startNotification: NSNotification.Name
        let stopNotification: NSNotification.Name
        
        if #available(iOS 18.0, *) {
            startNotification = AVCaptureSession.didStartRunningNotification
            stopNotification = AVCaptureSession.didStopRunningNotification
        } else {
            startNotification = .AVCaptureSessionDidStartRunning
            stopNotification = .AVCaptureSessionDidStopRunning
        }
        
        NotificationCenter.default.addObserver(
            forName: startNotification,
            object: session,
            queue: .main
        ) { [weak self] _ in
            self?.cameraManager?.isSessionRunning = true
        }
        
        NotificationCenter.default.addObserver(
            forName: stopNotification,
            object: session,
            queue: .main
        ) { [weak self] _ in
            self?.cameraManager?.isSessionRunning = false
        }
    }
    
    public  func updateResolution(_ resolution: AVCaptureSession.Preset) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.beginConfiguration()
            self.session.sessionPreset = resolution
            self.session.commitConfiguration()
        }
    }
    
    public  func startSession() {
        guard !session.isRunning else { return }
        session.startRunning()
        
        DispatchQueue.main.async {
            self.cameraManager?.isPaused = false
        }
    }
    
    public  func pauseSession() {
        guard let cameraManager = cameraManager,
              cameraManager.isSessionRunning && !cameraManager.isPaused else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.beginConfiguration()
            
            if let videoInput = cameraManager.deviceManager.videoDeviceInput {
                self.session.removeInput(videoInput)
            }
            
            self.session.commitConfiguration()
            
            DispatchQueue.main.async {
                cameraManager.isPaused = true
            }
        }
    }
    
    public  func resumeSession() {
        guard let cameraManager = cameraManager,
              cameraManager.isPaused else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.beginConfiguration()
            
            if let videoInput = cameraManager.deviceManager.videoDeviceInput {
                if self.session.canAddInput(videoInput) {
                    self.session.addInput(videoInput)
                }
            }
            
            self.session.commitConfiguration()
            
            DispatchQueue.main.async {
                cameraManager.isPaused = false
            }
        }
    }
}
