//
//  CameraManaging.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/1/25.
//


public protocol CameraManaging: ObservableObject {
    public var isSessionRunning: Bool { get }
    public  var isPaused: Bool { get }
    public  var isShowingAlert: Bool { get }
    public  var alertMessage: String { get }

    public   func requestPermissions()
    public   func togglePause()
    public   func capturePhoto()
}
