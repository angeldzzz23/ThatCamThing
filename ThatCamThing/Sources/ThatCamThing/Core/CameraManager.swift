//
//  CameraManager.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/1/25.
//

import Foundation

import SwiftUI
import AVKit

// MARK: - Main Camera Manager
public class CameraManager: NSObject, CameraManaging {
    
    // MARK: - Published Properties
    @Published var attributes: CameraManagerAttributes = .init() {
        didSet {
            configurationManager.handleAttributeChanges(oldValue: oldValue, newValue: attributes)
        }
    }
    
    @Published var isSessionRunning = false
    @Published var isPaused = false
    @Published var isShowingAlert = false
    @Published var alertMessage = ""
    @Published var capturedImage: UIImage?
    @Published var isCapturing: Bool = false

    // MARK: - Callbacks
    var onImageCaptured: ((UIImage) -> Void)?
    
    // MARK: - Core Components
    let session = AVCaptureSession()
    
    // MARK: - Managers
    public lazy var deviceManager = CameraDeviceManager(session: session, cameraManager: self)
    public lazy var sessionManager = CameraSessionManager(session: session, cameraManager: self)
    public  lazy var permissionManager = CameraPermissionManager(cameraManager: self)
    public   lazy var photoCaptureManager = PhotoCaptureManager(cameraManager: self)
    public lazy var configurationManager = CameraConfigurationManager(cameraManager: self)
    
    // MARK: - Initialization
    
    init(initialAttributes: CameraManagerAttributes = .init()) {
        self.attributes = initialAttributes
        super.init()
        
        setupCamera()
        sessionManager.setupSessionObservers()
    }
    
    convenience init(
        cameraPosition: CameraPosition = .back,
        resolution: AVCaptureSession.Preset = .hd1920x1080,
        flashMode: CameraFlashMode = .off,
        frameRate: Int32 = 30,
        zoomFactor: CGFloat = 1.0
    ) {
        var attributes = CameraManagerAttributes()
        attributes.cameraPosition = cameraPosition
        attributes.resolution = resolution
        attributes.flashMode = flashMode
        attributes.frameRate = frameRate
        attributes.zoomFactor = zoomFactor
        
        self.init(initialAttributes: attributes)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupCamera() {
        session.sessionPreset = attributes.resolution
        
        guard deviceManager.setupInitialDevice(
            position: attributes.cameraPosition,
            frameRate: attributes.frameRate,
            zoomFactor: attributes.zoomFactor
        ) else {
            attributes.error = .cannotSetupInput
            return
        }
        
        guard photoCaptureManager.setupPhotoOutput(session: session) else {
            attributes.error = .cannotSetupOutput
            return
        }
    }
    
    // MARK: - Public Interface
    func requestPermissions() {
        permissionManager.requestPermissions()
    }
    
    func togglePause() {
        if isPaused {
            sessionManager.resumeSession()
        } else {
            sessionManager.pauseSession()
        }
    }
    
    func capturePhoto() {
        photoCaptureManager.capturePhoto(flashMode: attributes.flashMode)
    }
    
    func clearCaptureImage() {
        capturedImage = nil
        attributes.capturedMedia = nil
    }
    
    func showAlert(message: String) {
        DispatchQueue.main.async {
            self.alertMessage = message
            self.isShowingAlert = true
        }
    }
}
